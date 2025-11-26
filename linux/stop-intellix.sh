#!/bin/bash

scriptRoot=$(readlink -f "$0")
scriptRoot=$(dirname "$scriptRoot")

echo "Stopping Intelligent Indexing..."
docker compose -f "$scriptRoot/setup/run/docker-compose.yml" down --remove-orphans
echo "Intelligent Indexing is stopped."
