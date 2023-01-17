#!/bin/bash

SCOPE_HEADER=$(curl -X HEAD https://api.github.com -H "Authorization: token $API_ACCESS_TOKEN" -I -s | grep 'x-oauth-scopes')

IFS=', ' read -r -a TOKEN_SCOPES <<< $(echo $SCOPE_HEADER | sed 's/x-oauth-scopes: \(.*\)\r/\1/')

if [[ ! " ${TOKEN_SCOPES[@]} " =~ " repo " ]]; then
  echo "API_ACCESS_TOKEN mangler 'repo' scope"
  exit 1
fi

if [[ ! " ${TOKEN_SCOPES[@]} " =~ " workflow " ]]; then
  echo "API_ACCESS_TOKEN mangler 'workflow' scope"
  exit 1
fi
