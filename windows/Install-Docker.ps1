$ProgressPreference = 'SilentlyContinue'

# Install Mirantis runtime
$script = Invoke-WebRequest https://get.mirantis.com/install.ps1 -UseBasicParsing
Invoke-Expression $($script.Content)


# Install Docker-Compose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://github.com/docker/compose/releases/download/v2.10.1/docker-compose-windows-x86_64.exe" -UseBasicParsing -OutFile $Env:ProgramFiles\Docker\docker-compose.exe
