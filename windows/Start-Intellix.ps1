Write-Output "Getting container images. This can take up to a few minutes. Be patient..."
docker-compose -f $PSScriptRoot/setup/run/docker-compose.yml pull -q

Write-Output "Starting Intelligent Indexing..."
docker-compose -f $PSScriptRoot/setup/run/docker-compose.yml up -d -t 60 --force-recreate
Write-Output "Intelligent Indexing is started."

$hn = $(hostname)
Write-Output "Intelligent Indexing can be reached at http://localhost:8080/intellix-v2/ or http://$hn/intellix-v2/"
Write-Output "To open the UI, browse to http://localhost:8080/intellix-v2/Html or http://$hn/intellix-v2/Html"
