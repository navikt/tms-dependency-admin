#!/bin/bash

export REPOSITORY=$1
IFS=

DEPENDENCIES_FILE_LOCATION="buildSrc/src/main/kotlin/default/dependencies.kt"
GROUPS_FILE_LOCATION="buildSrc/src/main/kotlin/groups.kt"

## Default dependencies file
function defaultDependenciesNode {
  echo $(jq -n -c \
              --arg path $DEPENDENCIES_FILE_LOCATION \
              --rawfile content "../$DEPENDENCIES_FILE_LOCATION" \
              '{ path: $path, mode: "100644", type: "blob", content: $content }'
  )
}

## Dependency groups file
function dependencyGroupsNode {
  echo $(jq -n -c \
                --arg path "$GROUPS_FILE_LOCATION" \
                --rawfile content "../$GROUPS_FILE_LOCATION" \
                '{ path: $path, mode: "100644", type: "blob", content: $content }'
    )
}

## Get name of main branch
MAIN_BRANCH=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY" | jq -r '.default_branch')

## Get latest commit sha on main
export BASE_TREE_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$MAIN_BRANCH" | jq -r '.object.sha')

## Find existing files in buildSrc folder
BUILD_SRC_CONTENTS=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$BASE_TREE_SHA?recursive=1" | jq -r '.tree[] | select(.path | startswith("buildSrc"))')

## Find file versions
LOCAL_DEPENDENCY_FILE_VERSION=$(git hash-object "../$DEPENDENCIES_FILE_LOCATION")
LOCAL_GROUPS_FILE_VERSION=$(git hash-object "../$GROUPS_FILE_LOCATION")

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
  echo 'No changes necessary'
  exit 0
fi

TREE_NODES="[$(defaultDependenciesNode),$(dependencyGroupsNode)]"

## Create new tree on remote and keep its ref
CREATE_TREE_PAYLOAD=$(jq -n -c \
                      --arg base_tree $BASE_TREE_SHA \
                      '{ base_tree: $base_tree, tree: [] }'
)

CREATE_TREE_PAYLOAD=$(echo $CREATE_TREE_PAYLOAD | jq -c '.tree = '"$TREE_NODES")

UPDATED_TREE_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_TREE_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/trees" | jq -r '.sha')


SHORT_SHA=$(echo $GITHUB_SHA | cut -c1-7)

COMMIT_MESSAGE=$(git log -1 --pretty=%B)

## Create commit based on new tree, keep new tree ref
CREATE_COMMIT_PAYLOAD=$(jq -n -c \
                        --arg message $COMMIT_MESSAGE \
                        --arg tree $UPDATED_TREE_SHA \
                        --arg name "Team min-side dependency admin" \
                        --arg email "personbruker@nav.no" \
                        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                        '{ tree: $tree, message: $message, author: { name: $name, email: $email, date: $date }, parents: [] }'
)

CREATE_COMMIT_PAYLOAD=$(echo $CREATE_COMMIT_PAYLOAD | jq -c '.parents = ["'"$BASE_TREE_SHA"'"]')

UPDATED_COMMIT_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/commits" | jq -r '.sha')

BRANCH_NAME="tms-dependency-admin_$SHORT_SHA"

## Create branch
CREATE_BRANCH_PAYLOAD=$(jq -n -c \
                      --arg ref refs/head/$BRANCH_NAME \
                      --arg sha $BASE_TREE_SHA \
                      '{ ref: $ref, sha: $sha }'
)

curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_BRANCH_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs"

## Push new commit
PUSH_COMMIT_PAYLOAD=$(jq -n -c \
                      --arg sha $UPDATED_COMMIT_SHA \
                      '{ sha: $sha, force: false }'
)

HEAD_SHA=$(curl -s -X PATCH -u "$API_ACCESS_TOKEN:" --data "$PUSH_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$BRANCH_NAME" | jq -r '.object.sha')

## Create PR
PULL_REQUEST_PAYLOAD=$(jq -n -c \
                       --arg title "Request to update dependencies" \
                       --arg head $BRANCH_NAME \
                       --arg base $MAIN_BRANCH \
                       '{ title: $title, head: $head, base: $base }'
)

curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$PULL_REQUEST_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/pulls"
