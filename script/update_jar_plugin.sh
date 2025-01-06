#!/bin/bash

IFS=

PLUGIN_FILE_LOCATION="buildSrc/src/main/kotlin/jarBundling.kt"
GROUPS_FILE_LOCATION="buildSrc/src/main/kotlin/groups.kt"
BUILD_FILE_LOCATION="buildSrc/build.gradle.kts"

## Plugin file
function pluginNode {
  echo $(jq -n -c \
              --arg path $PLUGIN_FILE_LOCATION \
              --rawfile content "$PLUGIN_FILE_LOCATION" \
              '{ path: $path, mode: "100644", type: "blob", content: $content }'
  )
}

## Dependency groups file
function dependencyGroupsNode {
  echo $(jq -n -c \
                --arg path "$GROUPS_FILE_LOCATION" \
                --rawfile content "$GROUPS_FILE_LOCATION" \
                '{ path: $path, mode: "100644", type: "blob", content: $content }'
    )
}

## Gradle build file
function buildNode {
  echo $(jq -n -c \
                --arg path "$BUILD_FILE_LOCATION" \
                --rawfile content "$BUILD_FILE_LOCATION" \
                '{ path: $path, mode: "100644", type: "blob", content: $content }'
    )
}

## -- Script start --

## Set name for remote branches
BRANCH_NAME="update-jar-plugin"

## Remove existing branches and pull requests originating from this repo
ALL_BRANCHES=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/branches")

MANAGED_BRANCHES=$(echo $ALL_BRANCHES | jq -r '.[] | select(.name | startswith("update-jar-plugin")) | .name')

while read -r branch; do
  if [[ $branch == $BRANCH_NAME ]]; then
    BRANCH_EXISTS='true'
    continue
  fi

  if [[ ! -z $branch ]]; then
    curl -X DELETE -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$branch"
  fi
done <<< "$MANAGED_BRANCHES"


if [[ $BRANCH_EXISTS == 'true' ]]; then
  echo "Branch med ønskede endringer finnes allerede for repo $REPOSITORY.."
  exit 0
fi


## Find existing files in buildSrc folder
BUILD_SRC_CONTENTS=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$LATEST_COMMIT_SHA?recursive=1" | jq -r '.tree[] | select(.path | startswith("buildSrc"))')

## Find file versions
LOCAL_PLUGIN_FILE_VERSION=$(git hash-object "$PLUGIN_FILE_LOCATION")
LOCAL_GROUPS_FILE_VERSION=$(git hash-object "$GROUPS_FILE_LOCATION")
LOCAL_BUILD_FILE_VERSION=$(git hash-object "$BUILD_FILE_LOCATION")

REMOTE_PLUGIN_FILE_VERSION=$(echo $BUILD_SRC_CONTENTS | jq -r "select(.path == \"$PLUGIN_FILE_LOCATION\").sha")
REMOTE_GROUPS_FILE_VERSION=$(echo $BUILD_SRC_CONTENTS | jq -r "select(.path == \"$GROUPS_FILE_LOCATION\").sha")
REMOTE_BUILD_FILE_VERSION=$(echo $BUILD_SRC_CONTENTS | jq -r "select(.path == \"$BUILD_FILE_LOCATION\").sha")


## Check if files are missing or out of date
if [[ -z $REMOTE_PLUGIN_FILE_VERSION || $REMOTE_PLUGIN_FILE_VERSION != $LOCAL_PLUGIN_FILE_VERSION ]]; then
  UPDATE_PLUGIN_FILE='true'
else
  UPDATE_PLUGIN_FILE='false'
fi

if [[ -z $REMOTE_GROUPS_FILE_VERSION || $REMOTE_GROUPS_FILE_VERSION != $LOCAL_GROUPS_FILE_VERSION ]]; then
  UPDATE_GROUPS_FILE='true'
else
  UPDATE_GROUPS_FILE='false'
fi

if [[ -z $REMOTE_BUILD_FILE_VERSION || $REMOTE_BUILD_FILE_VERSION != $LOCAL_BUILD_FILE_VERSION ]]; then
  UPDATE_BUILD_FILE='true'
else
  UPDATE_BUILD_FILE='false'
fi


## Add files to tree
if [[ $UPDATE_DEPENDENCY_FILE == 'false' && $UPDATE_GROUPS_FILE == 'false' && $UPDATE_BUILD_FILE == 'false' ]]; then
  echo "No changes necessary for [$REPOSITORY]"
  exit 0
else
  echo "Updating [$REPOSITORY]..."
fi

TREE_NODES="[$(pluginNode),$(dependencyGroupsNode),$(buildNode)]"

## Create new tree on remote and keep its ref
CREATE_TREE_PAYLOAD=$(jq -n -c \
                      --arg base_tree $LATEST_COMMIT_SHA \
                      '{ base_tree: $base_tree, tree: [] }'
)

CREATE_TREE_PAYLOAD=$(echo $CREATE_TREE_PAYLOAD | jq -c '.tree = '"$TREE_NODES")

UPDATED_TREE_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_TREE_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/trees" | jq -r '.sha')

if [[ -z $COMMIT_MESSAGE_OVERRIDE ]]; then
  COMMIT_MESSAGE='Initialiserer buildSrc/build.gradle.kts med gradle plugin'
else
  COMMIT_MESSAGE="$COMMIT_MESSAGE_OVERRIDE"
fi


## Create commit based on new tree, keep new tree ref
CREATE_COMMIT_PAYLOAD=$(jq -n -c \
                        --arg message $COMMIT_MESSAGE \
                        --arg tree $UPDATED_TREE_SHA \
                        --arg name "Dependency Admin" \
                        --arg email "personbruker@nav.no" \
                        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                        '{ tree: $tree, message: $message, author: { name: $name, email: $email, date: $date }, parents: [] }'
)

CREATE_COMMIT_PAYLOAD=$(echo $CREATE_COMMIT_PAYLOAD | jq -c '.parents = ["'"$LATEST_COMMIT_SHA"'"]')

CREATED_COMMIT_RESPONSE=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/commits")
echo "New ref: $CREATED_COMMIT_RESPONSE"

UPDATED_COMMIT_SHA=$(echo $CREATED_COMMIT_RESPONSE | jq -r '.sha')
if [[ $UPDATED_COMMIT_SHA == null ]]; then
  echo 'Kunne ikke lage ny commit på remote repository'
  exit 1
fi


## Create branch
CREATE_BRANCH_PAYLOAD=$(jq -n -c \
                      --arg ref "refs/heads/$BRANCH_NAME" \
                      --arg sha $LATEST_COMMIT_SHA \
                      '{ ref: $ref, sha: $sha }'
)

curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_BRANCH_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs" > /dev/null

## Push new commit
PUSH_COMMIT_PAYLOAD=$(jq -n -c \
                      --arg sha $UPDATED_COMMIT_SHA \
                      '{ sha: $sha, force: false }'
)

BRANCH_OUTPUT=$(curl -s -X PATCH -u "$API_ACCESS_TOKEN:" --data "$PUSH_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$BRANCH_NAME")
BRANCH_SHA=$(echo $BRANCH_OUTPUT | jq -r '.object.sha')

if [[ $BRANCH_SHA == null ]]; then
  echo 'Kunne ikke oppdatere branch'
  exit 1
else
  echo "Branch $BRANCH_NAME is now on commit $BRANCH_SHA"
fi

## Create pull request

CREATE_PR_PAYLOAD=$(jq -n -c \
                  --arg title "Oppdater buildSrc og jar plugin" \
                  --arg body "Initialiser/Oppdaterer buildSrc/build.gradle.kts og jar plugin. " \
                  --arg head $BRANCH_NAME \
                  --arg base $MAIN_BRANCH \
                  '{ title: $title, body: $body, head: $head, base: $base }'
)

PR_OUTPUT=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_PR_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/pulls")

echo "$PR_OUTPUT"
