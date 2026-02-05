wget --header="Content-Type: application/json" \
     --header="Accept: application/json" \
     --post-data='{"type":"get_licenses","app":"vBuhAssist","firms":["88888801"]}' \
     --quiet -O - \
     https://windows.cloud-server.com.ua/api
