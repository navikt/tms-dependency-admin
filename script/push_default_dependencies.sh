#!/bin/bash

IFS=

DEPENDENCIES_FILE_LOCATION="buildSrc/src/main/kotlin/default/dependencies.kt"
GROUPS_FILE_LOCATION="buildSrc/src/main/kotlin/groups.kt"

## Default dependencies file
function defaultDependenciesNode {
  echo $(jq -n -c \
              --arg path $DEPENDENCIES_FILE_LOCATION \
              --rawfile content "$DEPENDENCIES_FILE_LOCATION" \
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

LOCAL_SHORT_SHA=$(echo $GITHUB_SHA | cut -c1-7)
BRANCH_NAME="tms-dependency-admin_$LOCAL_SHORT_SHA"

## Remove existing branches and pull requests originating from this repo
ALL_BRANCHES=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/branches")

MANAGED_BRANCHES=$(echo $ALL_BRANCHES | jq -r '.[] | select(.name | startswith("tms-dependency-admin_")) | .name')

while read -r branch; do
  if [[ $branch == $BRANCH_NAME ]]; then
    BRANCH_EXISTS='true'
    continue
  fi

  curl -X DELETE -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$branch"
done <<< "$MANAGED_BRANCHES"

if [[ $BRANCH_EXISTS == 'true' ]]; then
  echo "Branch med ønskede endringer finnes allerede for repo $REPOSITORY.."
  exit 0
fi


## Find existing files in buildSrc folder
BUILD_SRC_CONTENTS=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$LATEST_COMMIT_SHA?recursive=1" | jq -r '.tree[] | select(.path | startswith("buildSrc"))')

## Find file versions
LOCAL_DEPENDENCY_FILE_VERSION=$(git hash-object "$DEPENDENCIES_FILE_LOCATION")
LOCAL_GROUPS_FILE_VERSION=$(git hash-object "$GROUPS_FILE_LOCATION")

REMOTE_DEPENDENCY_FILE_VERSION=$(echo $BUILD_SRC_CONTENTS | jq -r "select(.path == \"$DEPENDENCIES_FILE_LOCATION\").sha")
REMOTE_GROUPS_FILE_VERSION=$(echo $BUILD_SRC_CONTENTS | jq -r "select(.path == \"$GROUPS_FILE_LOCATION\").sha")

## Check if files are missing or out of date
if [[ -z $REMOTE_DEPENDENCY_FILE_VERSION || $REMOTE_DEPENDENCY_FILE_VERSION != $LOCAL_DEPENDENCY_FILE_VERSION ]]; then
  UPDATE_DEPENDENCY_FILE='true'
else
  UPDATE_DEPENDENCY_FILE='false'
fi

if [[ -z $REMOTE_GROUPS_FILE_VERSION || $REMOTE_GROUPS_FILE_VERSION != $LOCAL_GROUPS_FILE_VERSION ]]; then
  UPDATE_GROUPS_FILE='true'
else
  UPDATE_GROUPS_FILE='false'
fi

## Add files to tree
if [[ $UPDATE_DEPENDENCY_FILE == 'false' && $UPDATE_GROUPS_FILE == 'false' ]]; then
  echo "No changes necessary for [$REPOSITORY]"
  exit 0
else
  echo "Updating [$REPOSITORY]..."
fi

TREE_NODES="[$(defaultDependenciesNode),$(dependencyGroupsNode)]"

## Create new tree on remote and keep its ref
CREATE_TREE_PAYLOAD=$(jq -n -c \
                      --arg base_tree $LATEST_COMMIT_SHA \
                      '{ base_tree: $base_tree, tree: [] }'
)

CREATE_TREE_PAYLOAD=$(echo $CREATE_TREE_PAYLOAD | jq -c '.tree = '"$TREE_NODES")

UPDATED_TREE_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_TREE_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/trees" | jq -r '.sha')

if [[ -z $COMMIT_MESSGE_OVERRIDE ]]; then
  COMMIT_MESSAGE=$(git log -1 --pretty=%B)
else
  COMMIT_MESSAGE=$COMMIT_MESSGE_OVERRIDE
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

UPDATED_COMMIT_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/commits" | jq -r '.sha')

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

BRANCH_SHA=$(curl -s -X PATCH -u "$API_ACCESS_TOKEN:" --data "$PUSH_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$BRANCH_NAME" | jq -r '.object.sha')

echo "Branch $BRANCH_NAME is now on commit $BRANCH_SHA"
