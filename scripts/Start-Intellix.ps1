Write-Output "Starting Intelligent Indexing..."
docker-compose -f $PSScriptRoot/setup/run/docker-compose.yml up -d -t 60 --force-recreate
Write-Output "Intelligent Indexing is started."
Write-Output "Intelligent Indexing can be reached at http://localhost:8080/intellix-v2/ or http://$env:COMPUTERNAME/intellix-v2/"
Write-Output "To open the UI, browse to http://localhost:8080/intellix-v2/Html or http://$env:COMPUTERNAME/intellix-v2/Html"
