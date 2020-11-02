Write-Output "Stopping Intelligent Indexing..."
docker-compose -f $PSScriptRoot/setup/run/docker-compose.yml down --remove-orphans
Write-Output "Intelligent Indexing is stopped."
