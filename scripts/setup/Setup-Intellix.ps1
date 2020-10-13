<#
    .SYNOPSIS
        Configures DocuWare Intelligent Indexing
    .DESCRIPTION
        Configures DocuWare Intelligent Indexing by creating directories and the service environment.
        Directories are created on c:\ProgramData\IntellixV2. Docker containers are set up.
        A self-contained database 'intellixv2' on the SQL Server.

    .EXAMPLE  
    ./setup-intellix.ps1 `
      -LicenseFile <path-to-the-licence-file> `
      -IntellixAdminUser <name of web ui user> `
      -IntellixAdminPassword <password for web ui user> `
      -IntellixDbUser <name of intellixv2 database user> `
      -IntellixDbPassword <password of intellixv2 database user> 

    .EXAMPLE
    ./setup-intellix.ps1 `
      -LicenseFile <path-to-the-licence-file> `
      -IntellixAdminUser <name of web ui user> `
      -IntellixAdminPassword <password for web ui user> `
      -IntellixDbUser <name of intellixv2 database user> `
      -IntellixDbPassword <password of intellixv2 database user>  `
      -SqlServerInstance "my-sqlserver-2019" `
      -SqlServerInstanceUser "sa" `
      -SqlServerInstanceUser <sa password >
#>
param(
  # The path to the license file
  [string] $LicenseFile,

  # The name of the user who can administrate the service in the web ui
  [string] $IntellixAdminUser,

  # The password of the user who can administrate the service in the web ui
  [string] $IntellixAdminPassword,

  # The name of the database user which the service uses to connect the database. If you use
  # your own database, you must create the user yourself
  [string] $IntellixDbUser,

  # The password of the database user which the service uses to connect the database.
  [string] $IntellixDbPassword,

  # In case you do not want to use the SQL Server deployed as Docker container, specify
  # the instance of you SQL Server. In this case, the server must contain a user SqlServerInstanceUser 
  # with SqlServerInstancePassword, which has permissions to create and modify the intellixv2 database.
  [string] $SqlServerInstance,

  [string] $SqlServerInstanceUser,

  [string] $SqlServerInstancePassword
)


if ($SqlServerInstance) {
  Write-Host "Intelligent indexing is set up on SQL Server instance $SqlServerInstance $SqlServerInstanceUser $SqlServerInstancePassword"
  if ((-not $SqlServerInstanceUser) -or (-not $SqlServerInstancePassword)) {
    Write-Error "There are no credentials for the SQL Server instance $SqlServerInstance specified. Please use the parameters SqlServerInstanceUser and SqlServerInstancePassword to specify the credentials to access the SQL Server."
    exit 1
  }
}

Write-Verbose "Generating docker-compose file..."

$runPath = "$PSScriptRoot/run"
if (-not (Test-Path $runPath -PathType Container)) {
  mkdir $runPath -Force
}

if ($SqlServerInstance) {
  Copy-Item -Force $PSScriptRoot/docker-compose-own-sql.template.yml $runPath/docker-compose.yml
}
else {
  Copy-Item -Force $PSScriptRoot/docker-compose-sql-in-container.template.yml $runPath/docker-compose.yml
}


if ($IntellixDbUser -and $IntellixDbPassword) {
  Write-Verbose "Writing connection string file..."
  if ($SqlServerInstance) {
    $server = $SqlServerInstance
  }
  else {
    $server = "sql\SQLEXPRESS"
  }
  $connectionString = "ConnectionStrings__IntellixDatabaseEntities=Server=$server;Database=intellixv2;user id=$intellixDbUser;password=$intellixDbPassword;Trusted_Connection=False;pooling=True;multipleactiveresultsets=True;App=Intellix"
  $connectionString | Out-File -FilePath $runPath/intellix-database.env -Encoding ASCII
  Write-Verbose "Connection string file written"
}
else {
  Write-Verbose "Skipping writing connection string file."
}

if ($IntellixAdminUser -and $IntellixAdminPassword) {
  Write-Verbose "Writing DocuWare configuration file..."

  [Xml] $xml = '<?xml version="1.0"?>
  <IntellixConnectionSetup CreatedAt="2013-12-05T17:11:32.0919779+01:00" xmlns="http://dev.docuware.com/public/services/intellix">
    <ServiceUri></ServiceUri>
    <User></User>
    <Password></Password>
    <ModelspaceName></ModelspaceName>
  </IntellixConnectionSetup>'

  $fqdn = $(hostname)

  [System.Xml.XmlElement] $rootElement = $xml.DocumentElement
  $rootElement.CreatedAt = "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")"
  $rootElement.ServiceUri = "http://$fqdn/intellix-v2/"
  $rootElement.Password = $IntellixAdminPassword 
  $rootElement.User = $IntellixAdminUser
  $rootElement.ModelspaceName = "Default_$($IntellixAdminUser)"
  $xml.Save("$runPath/intelligent-indexing-connection.xml")
  Write-Verbose "DocuWare configuration file written."
}
else {
  Write-Verbose "Skipping DocuWare configuration file."
}

Write-Verbose "Create or update data directories..."
$intellixDirs = @(
  'c:\ProgramData\IntellixV2'
  'c:\ProgramData\IntellixV2\SQL'
  'c:\ProgramData\IntellixV2\License'
  'c:\ProgramData\IntellixV2\Solr'
  'c:\ProgramData\IntellixV2\License'
  'c:\ProgramData\IntellixV2\Files'
)

foreach ($dir in $intellixDirs) {
  if (-not (Test-Path $dir -PathType Container)) {
    mkdir $dir -Force
  }
}
Write-Verbose "Data directories updated."

if (-not (Test-Path $runPath/intellix-license.env)) {
  "" | Out-File -FilePath $runPath/intellix-license.env -Encoding ASCII
}

if ($LicenseFile -and (Test-Path $LicenseFile)) {
  Copy-Item $LicenseFile c:\ProgramData\IntellixV2\License\license.lic
  "LicenseFileLocation=c:/license/license.lic" | Out-File -FilePath $runPath/intellix-license.env -Encoding ASCII
  Write-Verbose "License file applied."
}

if (-not (Test-Path 'c:\ProgramData\IntellixV2\Solr\data\productionWordPairExtended' -PathType Container) ) {
  mkdir 'c:\ProgramData\IntellixV2\Solr\data' -Force
  Copy-Item  $PSScriptRoot/productionWordPairExtended 'c:\ProgramData\IntellixV2\Solr\data\' -Recurse 
  Write-Verbose "Solr files copied."
}

$dbSetupDir = Join-Path -Path $PSScriptRoot -ChildPath database-setup
if ($SqlServerInstance) {
  $dbSetupPath = Join-Path -Path $dbSetupDir -ChildPath docker-compose-own-sql.template.yml
}
else {
  $dbSetupPath = Join-Path -Path $dbSetupDir -ChildPath docker-compose-sql-in-container.template.yml
}


docker-compose -f $dbSetupPath build
if (!$?) {
  Write-Error "Could not build the database setup container. Exiting..."
  exit -1
}

docker-compose -f $dbSetupPath run --rm -e intellixUserName=$IntellixAdminUser -e intellixUserPassword=$IntellixAdminPassword -e intellixDbUser=$IntellixDbUser -e intellixDbPassword=$IntellixDbPassword -e sqlServerInstance=$SqlServerInstance -e sqlServerInstanceUser=$SqlServerInstanceUser -e sqlServerInstancePassword=$SqlServerInstancePassword tools --exit-code-from tools
if (!$?) {
  Write-Error "Could not run the database setup container. You should check the console output for errors. Exiting..."
  exit -1
}

docker-compose -f $dbSetupPath down
if (!$?) {
  Write-Error "Could not stop the database setup container. You should try to remove the containers manually. Exiting..."
  exit -1
}

Write-Output "Start Intelligent Indexing with 'Start-Intellix.ps1"
Write-Output "You find the configuration file for DocuWare at '$(Join-Path $runPath 'intelligent-indexing-connection.xml')'"
Write-Output "Browse Intelligent Indexing at http://$(hostname)/intellix-v2/"
