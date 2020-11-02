param (
    [string] $intellixAdminUser = 'intellix',
    [string] $intellixAdminPassword = $(./Get-RandomPassword.ps1)
)
Set-Location $PSScriptRoot

# The service is configured with random passwords
$intellixDbUser = 'intellix'
$intellixDbPassword = ./Get-RandomPassword.ps1

./setup/Setup-Intellix.ps1 `
    -IntellixAdminUser $intellixAdminUser `
    -IntellixAdminPassword $intellixAdminPassword `
    -IntellixDbUser $intellixDbUser `
    -IntellixDbPassword $intellixDbPassword `
    -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic'

if ($?) {
    Write-Output "Intelligent Indexing Web UI user: $intellixAdminUser"
    Write-Output "Intelligent Indexing Web UI password: $intellixAdminPassword"

    ./Start-Intellix.ps1
}
