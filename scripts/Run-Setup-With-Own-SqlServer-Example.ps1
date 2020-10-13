Set-Location $PSScriptRoot

$intellixAdminPassword = ./Get-RandomPassword.ps1
$intellixDbPassword = ./Get-RandomPassword.ps1

./setup/Setup-Intellix.ps1 `
    -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic' `
    -IntellixAdminUser intellix `
    -IntellixAdminPassword $intellixAdminPassword `
    -IntellixDbUser intellix `
    -IntellixDbPassword $intellixDbPassword `
    -SqlServerInstance "Chw-Win2019-Sql2019" `
    -SqlServerInstanceUser "sa" `
    -SqlServerInstancePassword "Admin001"

Write-Output "Intelligent Indexing Web UI user: intellix"
Write-Output "Intelligent Indexing Web UI password: $intellixAdminPassword"
