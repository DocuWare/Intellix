# Install NuGet Provider
$existingNugetProvider = (Get-PackageProvider -Name NuGet) | Where-Object { ([System.Version]$_.Version) -gt ([System.Version]"1.8.5.201") } | Measure-Object
if ($existingNugetProvider.Count -eq 0) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force    
} else {
    Write-Host "PackageProvider NuGet is already installed."
}

# Install Docker
Install-Module DockerMsftProvider -Force
Install-Package Docker -ProviderName DockerMsftProvider -Force

# Install Docker-Compose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Windows-x86_64.exe" -UseBasicParsing -OutFile $Env:ProgramFiles\Docker\docker-compose.exe
