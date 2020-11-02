#!/bin/bash

scriptRoot=$(readlink -f "$0")
scriptRoot=$(dirname "$scriptRoot")

docker-compose -f "$scriptRoot/setup/run/docker-compose.yml" logs -f
