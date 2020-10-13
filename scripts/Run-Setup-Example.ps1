Set-Location $PSScriptRoot

$intellixAdminPassword = ./Get-RandomPassword.ps1
$intellixDbPassword = ./Get-RandomPassword.ps1

./setup/Setup-Intellix.ps1 `
    -IntellixAdminUser intellix `
    -IntellixAdminPassword $intellixAdminPassword `
    -IntellixDbUser intellix `
    -IntellixDbPassword $intellixDbPassword `
    -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic'

Write-Output "Intelligent Indexing Web UI user: intellix"
Write-Output "Intelligent Indexing Web UI password: $intellixAdminPassword"

