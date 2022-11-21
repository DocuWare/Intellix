#!/bin/bash

intellixDbUser='intellix'

while [ $# -gt 0 ]; do
  case "$1" in
  --license-file=*)
    licenseFileSource="${1#*=}"
    echo "Reading license from '$licenseFileSource'"
    ;;
  --intellix-admin-user=*)
    intellixAdminUser="${1#*=}"
    echo "Intellix user '$intellixAdminUser'"
    ;;
  --intellix-admin-password=*)
    intellixAdminPassword="${1#*=}"
    ;;
  --intellix-db-user=*)
    intellixDbUser="${1#*=}"
    echo "Intellix SQL user '$intellixDbUser'"
    ;;
  --intellix-db-password=*)
    intellixDbPassword="${1#*=}"
    ;;
  --sql-server-instance=*)
    sqlServerInstance="${1#*=}"
    ;;
  --sql-server-instance-user=*)
    sqlServerInstanceUser="${1#*=}"
    ;;
  --sql-server-instance-password=*)
    sqlServerInstancePassword="${1#*=}"
    ;;
  *) ;;
  esac
  shift
done


if ! [ -z "${sqlServerInstance}" ]; then 
  echo "Intelligent indexing is set up on SQL Server instance ${sqlServerInstance}"
  if [ -z "${sqlServerInstanceUser}" ] || [ -z "${sqlServerInstancePassword}" ]; then
    echi "There are no credentials for the SQL Server instance ${sqlServerInstance} specified. Please use the parameters --sql-server-instance-user and --sql-server-instance-password to specify the credentials to access the SQL Server."
    exit 1
  fi
fi

echo "Generating docker-compose file..."

scriptRoot=$(readlink -f "$0")
scriptRoot=$(dirname "$scriptRoot")

runPath="$scriptRoot/run"
echo $runPath

if [ ! -d "$runPath" ]; then 
  mkdir "$runPath"
fi


if [ ! -z "${sqlServerInstance}" ]; then
  cp -af "$scriptRoot/docker-compose-own-sql.template.yml" "$runPath/docker-compose.yml"
else
  cp -af "$scriptRoot/docker-compose-sql-in-container.template.yml" "$runPath/docker-compose.yml"
fi

if [ ! -z "${intellixDbUser}" ] && [ ! -z "${intellixDbPassword}" ]; then
  echo "Writing connection string file..."
  if [ ! -z "${sqlServerInstance}" ]; then
    server=$sqlServerInstance
  else
    server="sql"
  fi
  connectionString="ConnectionStrings__IntellixDatabaseEntities=Server=$server;Database=intellixv2;user id=$intellixDbUser;password=$intellixDbPassword;Trusted_Connection=False;pooling=True;multipleactiveresultsets=True;App=Intellix"
  echo $connectionString > "$runPath/intellix-database.env"
fi

fqdn=$(hostname -f)

if [ ! -z "${intellixAdminUser}" ] && [ ! -z "${intellixAdminPassword}" ]; then
  confPath="$runPath/intelligent-indexing-connection.xml"  
  now=$(date +"%Y-%m-%dT%H:%M:%S")
  echo "Writing DocuWare configuration file '$confPath'..."  
  echo '<?xml version="1.0"?>' > "$confPath"
  echo "<IntellixConnectionSetup CreatedAt=\"$now\" xmlns=\"http://dev.docuware.com/public/services/intellix\">" >> "$confPath"
  echo "    <ServiceUri>http://$fqdn/intellix-v2/</ServiceUri>" >> "$confPath"
  echo "    <User>$intellixAdminUser</User>" >> "$confPath"
  echo "    <Password>$intellixAdminPassword</Password>" >> "$confPath"
  echo "    <ModelspaceName>Default_$intellixAdminUser</ModelspaceName>" >> "$confPath"
  echo "</IntellixConnectionSetup>" >> "$confPath"
fi

echo "Create or update data directories..."
declare -a intellixDirs=(
  "/var/intellix/"
  "/var/intellix/sql/"
  "/var/intellix/sql/data/"
  "/var/intellix/sql/secrets/"
  "/var/intellix/sql/log/"
  "/var/intellix/solr/"
  "/var/intellix/license/"
  "/var/intellix/files/"
)

for dir in "${intellixDirs[@]}"; do
  if [ ! -d $dir ]; then
    mkdir $dir
    chmod a+rwX -R $dir
    echo "Created '$dir'"
  fi
done


touch "$runPath/intellix-license.env"
if ! [ -z "${licenseFileSource}" ] && [ -f "$licenseFileSource" ]; then
  cp "$licenseFileSource" /var/intellix/license/license.lic
  echo "LicenseFileLocation=/license/license.lic" > "$runPath/intellix-license.env"
  echo "License file applied."
fi

if ! [ -d /var/intellix/solr/data/productionWordPairExtended/ ]; then
  mkdir /var/intellix/solr/data
  cp -r "$scriptRoot/productionWordPairExtended" /var/intellix/solr/data/
  chmod -R a+rwX /var/intellix/solr/data/
  echo "Solr files copied."
fi

dbSetupDir="$scriptRoot/database-setup"
if ! [ -z "${sqlServerInstance}" ]; then
  dbSetupPath="$dbSetupDir/docker-compose-own-sql.template.yml"
else
  dbSetupPath="$dbSetupDir/docker-compose-sql-in-container.template.yml"
fi

docker-compose -f "$dbSetupPath" pull
docker-compose -f "$dbSetupPath" run --rm \
  -e intellixUserName=$intellixAdminUser \
  -e intellixUserPassword=$intellixAdminPassword \
  -e intellixDbUser=$intellixDbUser \
  -e intellixDbPassword=$intellixDbPassword \
  -e sqlServerInstance=$sqlServerInstance \
  -e sqlServerInstanceUser=$sqlServerInstanceUser \
  -e sqlServerInstancePassword=$sqlServerInstancePassword \
  tools --exit-code-from tools
err=$?


if [ $err -eq 0 ]; then
  docker-compose -f "$dbSetupPath" down
  err=$?
fi

docker-compose -f "$scriptRoot/run/docker-compose.yml" pull

if [ $err -eq 0 ]; then
  echo "Start Intelligent Indexing with './start-intellix.sh"
  echo "Browse Intelligent Indexing at http://$fqdn/intellix-v2/"
else
  echo "Something went wrong. See messages above"
fi

exit $err
