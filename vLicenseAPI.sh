#!/bin/bash

Api()
{
  aPostData=$1;

  wget --header="Content-Type: application/json" \
     --header="Accept: application/json" \
     --post-data="$aPostData" \
     --quiet \
     -O - \
     https://windows.cloud-server.com.ua/api
}

Api '{"type":"get_licenses","app":"vBuhAssist","firms":["88888801"]}'
