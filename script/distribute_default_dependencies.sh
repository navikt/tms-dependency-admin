#!/bin/bash

## Add 'navikt/..' to included repositories unless different owner is specified
if [[ ! -z $INCLUDE ]]; then
  REPOSITORIES=$(echo "$INCLUDE" | sed 's/\(^[^\/]*$\)/navikt\/\1/g')
fi

## Sort and filter duplicates
REPOSITORIES=$(echo -e "$REPOSITORIES" | sort | uniq)

## Distribute files for each project
for repository in $REPOSITORIES; do
  if [[ $repository == $GITHUB_REPOSITORY ]]; then
    echo "Should not distribute files to same repository. Skipping $repository"
  else
    ./push_default_dependencies.sh $repository
  fi
done
