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


#Api '{"type":"get_ver"}'
Api '{"type":"get_licences","app":"vBuhAssist","firms":["88888801","40050963"]}'
#Api '{"type":"order_licences","app":"vBuhAssist","user":"yuta","passw":"1234","firms":["88888801"]}'
#Api '{"type":"get_orders", "user":"yuta"}'
#Api '{"type":"get_orders", "user":"yuta", "date":"2026/02/13"}'
