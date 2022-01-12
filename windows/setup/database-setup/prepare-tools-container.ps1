$progressPreference = 'silentlyContinue'

$existingNugetProvider = (Get-PackageProvider -Name NuGet -Force) | Where-Object { ([System.Version]$_.Version) -gt ([System.Version]"1.8.5.201") } | Measure-Object
if ($existingNugetProvider.Count -eq 0) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force    
} else {
    Write-Host "PackageProvider NuGet is already installed."
}

Install-Module -Name SqlServer -Force -Scope CurrentUser

Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2143496" -OutFile sqlpackage.zip
Expand-Archive sqlpackage.zip -DestinationPath /sqlpackage
