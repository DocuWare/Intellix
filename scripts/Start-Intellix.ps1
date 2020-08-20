.\Read-IntellixConfiguration.ps1

if (-not (Test-Path $env:E_FileStoragePath)) {
    mkdir -force $env:E_FileStoragePath | Out-Null
}

if (-not (Test-Path $env:E_SolRDataPath)) {
    mkdir -force $env:E_SolRDataPath | Out-Null
}

if (-not (Test-Path $env:E_DataProtectionKeysPath)) {
    mkdir -force $env:E_DataProtectionKeysPath | Out-Null
}

docker-compose -f docker-compose.yml up -d -t 60 --force-recreate 
