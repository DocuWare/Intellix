$progressPreference = 'silentlyContinue'
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SqlServer -Force -Scope CurrentUser

Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2143496" -OutFile sqlpackage.zip
Expand-Archive sqlpackage.zip -DestinationPath /sqlpackage
