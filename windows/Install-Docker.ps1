# Install Mirantis runtime
$script = Invoke-WebRequest https://get.mirantis.com/install.ps1
Invoke-Expression $($script.Content)


# Install Docker-Compose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://github.com/docker/compose/releases/download/v2.11.0/docker-compose-Windows-x86_64.exe" -UseBasicParsing -OutFile $Env:ProgramFiles\Docker\docker-compose.exe
