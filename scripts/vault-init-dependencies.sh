#!/bin/sh
if ! command -v bash >/dev/null 2>&1; then
  apk update
  apk add bash
fi
if ! command -v jq >/dev/null 2>&1; then
  apk update
  apk add jq
fi

/opt/vault/init.sh