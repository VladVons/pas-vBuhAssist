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

Api '{"type":"get_licenses","app":"BuhAssist","firms":["88888801","40050963"]}'
#Api '{"type":"order_licenses","app":"BuhAssist","user":"yuta","passw":"1234","firms":["88888801"]}'
