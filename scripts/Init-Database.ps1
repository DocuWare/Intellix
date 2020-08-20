param(
    [Parameter(Mandatory = $true)]
    [string] $dbIntellixUser,
    [Parameter(Mandatory = $true)]
    [string] $dbIntellixUserPassword,
    [Parameter(Mandatory = $true)]
    [string] $serverInstance,
    [Parameter(Mandatory = $true)]
    [string] $intellixAdminUser,
    [Parameter(Mandatory = $true)]
    [string] $intellixAdminUserPassword
)

$dataSource = '.\' + $serverInstance


Write-Host "Creating database..."
sqlcmd -S $dataSource -i .\init_database.sql 1>.\init_database.log 2>.\init_database.err
if ($LASTEXITCODE -ne 0) {
    Write-Error "Creating database failed. Please check init_database.log and init_database.err for details."
    exit $LASTEXITCODE
}


Write-Host "Creating Intelligent Indexing admin user..."
$intellixAdminUserCmd = "
USE intellixv2
go

IF NOT EXISTS(select * from users where Name=N'$intellixAdminUser')
BEGIN
	Execute AddUser N'$intellixAdminUser', N'$intellixAdminUserPassword'; 

    declare @adminUserRoleId int

	set @adminUserRoleId = (select Id from Roles where name = N'Administrator');
	insert into UserRoles(UserId, RoleId)
	select u.Id, @adminUserRoleId from 
		(select * from Users where name = N'$intellixAdminUser') u left outer join 
		(select * from UserRoles where RoleId = @adminUserRoleId) ur on u.Id = ur.UserId 
		where ur.UserId is null
END

"

sqlcmd -b -S $dataSource -Q $intellixAdminUserCmd 1>>.\init_database.log 2>>.\init_database.err
if ($LASTEXITCODE -ne 0) {
    Write-Error "Creating the Intelligent Indexing Service administation user failed."
    exit $LASTEXITCODE
}
Write-Host "Creating user $dbIntellixUser for Intelligent Indexing database..."
$createUserCmd = `
    "USE intellixv2`n" + `
    "GO`n" + `
    "CREATE LOGIN [$dbIntellixUser] WITH PASSWORD=N'$dbIntellixUserPassword', DEFAULT_DATABASE=intellixv2`n" + `
    "GO`n" + `
    "ALTER LOGIN [$dbIntellixUser] ENABLE`n" + 
"GO`n" + `
    "CREATE USER [$dbIntellixUser] FOR LOGIN [$dbIntellixUser]`n" + 
"GO`n" + `
    "exec sp_addrolemember 'db_owner', '$dbIntellixUser'"

sqlcmd -b -S $dataSource -Q $createUserCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Creating the Intelligent Indexing database user failed."
    exit $LASTEXITCODE
}


Write-Host "Enabling SQL Server Authentication..."
sqlcmd -S $dataSource -Q "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2"


Write-Host "Enabling TCP/IP and set port to 1433..."
Import-Module SQLPS -DisableNameChecking -Force
$wmi = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $env:COMPUTERNAME
$uri = "ManagedComputer[@Name='$env:COMPUTERNAME']/ ServerInstance[@Name='$serverInstance']/ServerProtocol[@Name='Tcp']"
$tcp = $wmi.GetSmoObject($uri)
$tcp.IsEnabled = $true
$wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties[0].Value = ""
$wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties[1].Value = "1433"
$tcp.Alter()


Write-Host "Restarting SQL Server..."
$wmi.Services | Where-Object { $_.Type -eq 'SqlServer' } | ForEach-Object { Restart-Service $_.Name }


Write-Host "Updating firewall rules..."
netsh advfirewall firewall add rule name="SQLPort 1433" dir=in action=allow protocol=TCP localport=1433
