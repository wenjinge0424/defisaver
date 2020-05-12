#!/bin/bash
UUID=$(grep MOONNET_UUID .env | cut -d '=' -f2)
URL=https://node.moonnet.space/reset/uuid/$UUID

curl $URL \
  -X 'POST' \
  -H 'Connection: keep-alive' \
  -H 'Content-Length: 0' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Origin: https://moonnet.now.sh' \
  -H 'Sec-Fetch-Site: cross-site' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://moonnet.now.sh/' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  --compressed
