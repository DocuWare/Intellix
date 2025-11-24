#!/bin/bash

withRestart=
while [ $# -gt 0 ]; do
  case "$1" in
  --with-restart)
    withRestart=1
    ;;
  *) ;;
  esac
  shift
done

scriptRoot=$(readlink -f "$0")
scriptRoot=$(dirname "$scriptRoot")

docker compose -f "$scriptRoot/setup/run/docker-compose.yml" pull

if [ -n "$withRestart" ] ; then
    "$scriptRoot/stop-intellix.sh"
    "$scriptRoot/start-intellix.sh"
fi
