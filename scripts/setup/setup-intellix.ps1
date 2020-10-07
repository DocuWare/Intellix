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
  Write-Host "Intelligent indexing is set up on SQL Server instance $SqlServerInstance"
}

if (-not (Test-Path run -PathType Container)) {
  mkdir ./run -Force
}

if ($IntellixDbUser -and $IntellixDbPassword) {
  if ($SqlServerInstance) {
    $server = $SqlServerInstance
    Copy-Item -Force ./docker-compose-own-sql.template.yml ./run/docker-compose.yml
  }
  else {
    $server = "sql\SQLEXPRESS"
    Copy-Item -Force ./docker-compose-sql-in-container.template.yml ./run/docker-compose.yml
  }
  $connectionString = "ConnectionStrings__IntellixDatabaseEntities=Server=$server;Database=intellixv2;user id=$intellixDbUser;password=$intellixDbPassword;Trusted_Connection=False;pooling=True;multipleactiveresultsets=True;App=Intellix"
  $connectionString | Out-File -FilePath ./run/intellix-database.env -Encoding ASCII
}

if ($IntellixAdminUser -and $IntellixAdminPassword) {
  [Xml] $xml = '<?xml version="1.0"?>
  <IntellixConnectionSetup CreatedAt="2013-12-05T17:11:32.0919779+01:00" xmlns="http://dev.docuware.com/public/services/intellix">
    <ServiceUri></ServiceUri>
    <User></User>
    <Password></Password>
    <ModelspaceName></ModelspaceName>
  </IntellixConnectionSetup>'

  $domain = $env:USERDNSDOMAIN
  $fqdn = $env:COMPUTERNAME
  if ($domain) {
    $fqdn += ".$domain"
  }

  [System.Xml.XmlElement] $rootElement = $xml.DocumentElement
  $rootElement.CreatedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
  $rootElement.ServiceUri = "http://$fqdn/intellix-v2/"
  $rootElement.Password = $IntellixAdminPassword 
  $rootElement.User = $IntellixAdminUser
  $rootElement.ModelspaceName = "$($user)_Default"
  $xml.Save("$PSScriptRoot/run/intelligent-indexing-connection.xml")
}

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

"" | Out-File -FilePath ./run/intellix-license.env -Encoding ASCII
if ($LicenseFile -and (Test-Path $LicenseFile)) {
  Copy-Item $LicenseFile c:\ProgramData\IntellixV2\License\license.lic
  "LicenseFileLocation=c:/license/license.lic" | Out-File -FilePath ./run/intellix-license.env -Encoding ASCII
}

if (-not (Test-Path 'c:\ProgramData\IntellixV2\Solr\data\productionWordPairExtended' -PathType Container) ) {
  mkdir 'c:\ProgramData\IntellixV2\Solr\data' -Force
  Copy-Item productionWordPairExtended 'c:\ProgramData\IntellixV2\Solr\data\' -Recurse 
}

if ($SqlServerInstance) {
  $dbSetupPath = "database-setup/docker-compose-own-sql.template.yml"
}
else {
  $dbSetupPath = "database-setup/docker-compose-sql-in-container.template.yml"
}


docker-compose -f $dbSetupPath build
docker-compose -f $dbSetupPath run --rm -e intellixUserName=$IntellixAdminUser -e intellixUserPassword=$IntellixAdminPassword -e intellixDbUser=$IntellixDbUser -e intellixDbPassword=$IntellixDbPassword -e sqlServerInstance=$SqlServerInstance -e sqlServerInstanceUser=$SqlServerInstanceUser -e sqlServerInstancePassword=$SqlServerInstancePassword tools --exit-code-from tools
#docker logs intellix-sql-setup
docker-compose -f $dbSetupPath down




#if [ $err -eq 0 ]; then
Write-Output "Start Intelligent Indexing with 'docker-compose -f run/docker-compose.yml up -d'"
Write-Output "Browse Intelligent Indexing at http://$(hostname)/intellix-v2/"
#else
#echo "Something went wrong. See messages above"
#fi

#exit $err

