#!/bin/bash

if [ -f ./setup/run/docker-compose.yml ] ;
then
  ./stop-intellix.sh
fi

intellixAdminUser='intellix'
intellixAdminPassword=$(./random-password.sh)
intellixDbUser='intellix'
intellixDbPassword=$(./random-password.sh)

while [ $# -gt 0 ]; do
  case "$1" in
  --intellix-admin-user=*)
    intellixAdminUser="${1#*=}"
    echo "Intellix user '$intellixAdminUser'"
    ;;
  --intellix-admin-password=*)
    intellixAdminPassword="${1#*=}"
    ;;
  *) ;;
  esac
  shift
done


./setup/setup-intellix.sh \
    --license-file='../../licenses/Peters Engineering_Enterprise.lic' \
    --intellix-admin-user=$intellixAdminUser \
    --intellix-admin-password=$intellixAdminPassword \
    --intellix-db-user=intellix \
    --intellix-db-password=$intellixDbPassword

if [ $? -eq 0 ] ; then
    echo "Intelligent Indexing Web UI user: $intellixAdminUser"
    echo "Intelligent Indexing Web UI password: $intellixAdminPassword"

    ./start-intellix.sh
fi
