.\Read-IntellixConfiguration.ps1

docker pull docuwarepublic.azurecr.io/intellix/app:$env:E_IntellixImageVersion
docker pull docuwarepublic.azurecr.io/intellix/solr:$env:E_SolRImageVersion

docker image prune --force
