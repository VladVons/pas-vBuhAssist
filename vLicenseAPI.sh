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
#Api '{"type":"get_annonce", "app": "vBuhAssist", "ver": "1.11.2.22"}'
#Api '{"type":"get_licence","app":"vBuhAssist","firms":["24620181","40050963"]}'
#Api '{"type":"order_licence","app":"vBuhAssist","user":"vladvons","passw":"19710819","firms":["24620181"]}'
Api '{"type":"get_orders", "app":"vBuhAssist", "user":"yuta"}'
#Api '{"type":"get_orders", "app":"vBuhAssist", "user":"yuta", "date":"2026/02/13"}'
