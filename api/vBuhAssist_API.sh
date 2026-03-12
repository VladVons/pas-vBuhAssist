#!/bin/bash

Api()
{
  aPostData=$1;

  wget --header="Content-Type: application/json" \
     --header="Accept: application/json" \
     --post-data="$aPostData" \
     --quiet \
     -O - \
     https://windows.cloud-server.com.ua/api |\
  jq
}

User="yuta"
Passw="xxx"

#Api '{"type":"get_ver"}'

#Api '{"type":"get_annonce", "app": "vBuhAssist", "ver": "11.2.48"}'

#Api '{"type":"get_licence","app":"vBuhAssist", "module": "FMedocCheckDocs", "firms":["24620181","40050963", "24620182"]}'

#Api '{"type":"get_licences_user", "app": "vBuhAssist", "user": "yuta", "passw": "26022026"}'
Api '{"type":"get_licences_user", "app": "vBuhAssist", "user": "'"$User"'", "passw": "'"$Passw"'", "date":"2026-03", "count": true}'

#Api '{"type":"order_licence","app":"vBuhAssist", "module": "FMedocCheckDocs", "user":"'"$User"'","passw":"'"$Passw"'","firms":["24620183"]}'

#Api '{"type":"get_orders", "app":"vBuhAssist", "user":"'"$User"'", "passw": "'"$Passw"'"}'
#Api '{"type":"get_orders", "app":"vBuhAssist", "user":"'"$User"'", "passw": "'"$Passw"'", "date":"2026-03-05"}'
