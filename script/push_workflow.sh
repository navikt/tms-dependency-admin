#!/bin/bash

export REPOSITORY=$1
IFS=

LOCAL_WORKFLOW_LOCATION='../.github/workflows/distributed/verify_distributed_dependencies.yaml'
REMOTE_WORKFLOW_LOCATION='.github/workflows/verify_distributed_dependencies.yaml'

## Workflow file
function workflowFileNode {
  echo $(jq -n -c \
              --arg path $REMOTE_WORKFLOW_LOCATION \
              --rawfile content $LOCAL_WORKFLOW_LOCATION \
              '{ path: $path, mode: "100644", type: "blob", content: $content }'
  )
}

## Get name of main branch
MAIN_BRANCH=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY" | jq -r '.default_branch')

## Get latest commit sha on main
export BASE_TREE_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$MAIN_BRANCH" | jq -r '.object.sha')

## Find version for remote workflow file if exists
REMOTE_WORKFLOW_VERSION=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/trees/$BASE_TREE_SHA?recursive=1" | jq -r ".tree[] | select(.path == \"$REMOTE_WORKFLOW_LOCATION\").sha")

LOCAL_WORKFLOW_VERSION=$(git hash-object "$LOCAL_WORKFLOW_LOCATION")

## Check if file is missing or out of date
if [[ -z $REMOTE_WORKFLOW_VERSION || $REMOTE_WORKFLOW_VERSION != $LOCAL_WORKFLOW_VERSION ]]; then
  UPDATE_WORKFLOW_FILE='true'
else
  UPDATE_WORKFLOW_FILE='false'
fi

## Add files to tree
if [[ $UPDATE_WORKFLOW_FILE == 'false' ]]; then
  echo "No workflow changes necessary for [$REPOSITORY]"
  exit 0
else
  echo "Updating worfklow file for [$REPOSITORY]..."
fi

TREE_NODE="[$(workflowFileNode)]"

## Create new tree on remote and keep its ref
CREATE_TREE_PAYLOAD=$(jq -n -c \
                      --arg base_tree $BASE_TREE_SHA \
                      '{ base_tree: $base_tree, tree: [] }'
)

CREATE_TREE_PAYLOAD=$(echo $CREATE_TREE_PAYLOAD | jq -c '.tree = '"$TREE_NODE")

UPDATED_TREE_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_TREE_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/trees" | jq -r '.sha')

SHORT_SHA=$(echo $GITHUB_SHA | cut -c1-7)

COMMIT_MESSAGE="Automated update for dependency workflow file"

## Create commit based on new tree, keep new tree ref
CREATE_COMMIT_PAYLOAD=$(jq -n -c \
                        --arg message $COMMIT_MESSAGE \
                        --arg tree $UPDATED_TREE_SHA \
                        --arg name "Dependency Admin" \
                        --arg email "personbruker@nav.no" \
                        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                        '{ tree: $tree, message: $message, author: { name: $name, email: $email, date: $date }, parents: [] }'
)

CREATE_COMMIT_PAYLOAD=$(echo $CREATE_COMMIT_PAYLOAD | jq -c '.parents = ["'"$BASE_TREE_SHA"'"]')

UPDATED_COMMIT_SHA=$(curl -s -X POST -u "$API_ACCESS_TOKEN:" --data "$CREATE_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/commits" | jq -r '.sha')

## Push new commit
PUSH_COMMIT_PAYLOAD=$(jq -n -c \
                      --arg sha $UPDATED_COMMIT_SHA \
                      '{ sha: $sha, force: false }'
)

curl -s -X PATCH -u "$API_ACCESS_TOKEN:" --data "$PUSH_COMMIT_PAYLOAD" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$MAIN_BRANCH" > /dev/null


echo DEBUG
echo tree $TREE_NODE
echo create tree $CREATE_TREE_PAYLOAD
echo create commit $CREATE_COMMIT_PAYLOAD
echo push commit $PUSH_COMMIT_PAYLOAD
