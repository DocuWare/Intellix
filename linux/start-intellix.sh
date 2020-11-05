#!/bin/bash

scriptRoot=$(readlink -f "$0")
scriptRoot=$(dirname "$scriptRoot")

echo "Starting Intelligent Indexing..."
docker-compose -f "$scriptRoot/setup/run/docker-compose.yml" up -d --remove-orphans
echo "Intelligent Indexing is started."
hn=$(hostname -f)
echo "Intelligent Indexing can be reached at http://localhost/intellix-v2/ or http://$hn/intellix-v2/"
