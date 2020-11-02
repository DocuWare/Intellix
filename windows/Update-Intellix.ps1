<#
.SYNOPSIS
    Updates DocuWare Intelligent Indexing

.DESCRIPTION
    Updates DocuWare Intelligent Indexing and restarts the service

.EXAMPLE  
./Update-Intellix.ps1 -WithRestart
#>
param(
    # If set, Intelligent Index is restarted after the containers are pulled
    [switch] $WithRestart
)    

docker-compose -f $PSScriptRoot/setup/run/docker-compose.yml pull

if($WithRestart){    
    & "$PSScriptRoot/Stop-Intellix.ps1"
    & "$PSScriptRoot/Start-Intellix.ps1"
}