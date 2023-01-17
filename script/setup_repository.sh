#!/bin/bash

## Prefix repository with 'navikt' if no owner is specified
REPOSITORY=$(echo "$MANAGED_APP" | sed 's/\(^[^\/]*$\)/navikt\/\1/g')

## Get name of main branch
MAIN_BRANCH=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY" | jq -r '.default_branch')

if [[ $MAIN_BRANCH == 'null' ]]; then
  echo "Repository '$REPOSITORY' ser ikke ut til å eksistere."
  exit 1
fi

## Check permissions for remote repository
API_ACCESS_TOKEN_OWNER=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/user" | jq -r '.login')

PRIVILEGE_LEVEL=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/collaborators/$API_ACCESS_TOKEN_OWNER/permission" | jq -r '.permission')

if [[ $PRIVILEGE_LEVEL != 'admin' && $PRIVILEGE_LEVEL != 'write' ]]; then
  echo "Access token owner $API_ACCESS_TOKEN_OWNER does not have write permission for repository $REPOSITORY"
  exit 1
fi

## Get latest commit sha on main
export BASE_TREE_SHA=$(curl -s -u "$API_ACCESS_TOKEN:" "https://api.github.com/repos/$REPOSITORY/git/refs/heads/$MAIN_BRANCH" | jq -r '.object.sha')

# Export variables
echo "REPOSITORY=$REPOSITORY" >> $GITHUB_ENV
echo "MAIN_BRANCH=$MAIN_BRANCH" >> $GITHUB_ENV
echo "LATEST_COMMIT_SHA=$BASE_TREE_SHA" >> $GITHUB_ENV
