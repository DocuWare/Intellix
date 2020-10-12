Import-Module SqlServer

if ($env:sqlServerInstance) {
    $ownServer = $true
    $sqlServer = $env:sqlServerInstance
    $sqlUser = $env:sqlServerInstanceUser
    $sqlPw = $env:sqlServerInstancePassword

    if (!$sqlUser -or !$sqlPw) {
        Write-Error "User or password ar missing when specifying an own instance"
        exit 1
    }

    Write-Output "Configuring SQL Database on $sqlServer..."
}
else {
    $ownServer = $false
    $sqlServer = 'intellix-sql-setup'
    $sqlUser = 'sa'
    $sqlPw = 'Admin001'
}

if ($ownServer) {
    # If there is an own SQL Server, we must reconfigure the server to allow contained databases
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $env:sqlServerInstanceUser -Password $env:sqlServerInstancePassword -Query "sp_configure 'contained database authentication', 1" -Verbose
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $env:sqlServerInstanceUser -Password $env:sqlServerInstancePassword -Query "RECONFIGURE" -Verbose
}
else {
    for ($i = 0; $i -lt 10; $i++) {
        $s = $i + 3;
        Write-Output "Waiting $s seconds for the SQL Server..."
        Start-Sleep $s
        try {
            $r = Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Query "select 1 as [x]" -ErrorAction SilentlyContinue
            $ok = $r.Item.Count -eq 1
            if ($ok) {
                Write-Output "Ok"
                break
            }
        }
        catch {
            Write-Warning "The SQL Server cannot be reached."
        }
    }

    if (!$ok) {
        Write-Error "The SQL Server is not there. Giving up."
        $error
        exit 1;
    }

    if (-not (Test-Path 'c:\mssql\intellixv2.mdf')) {
        Write-Output "Creating intellixv2 database..."
        Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Query "IF NOT EXISTS (SELECT 1 FROM master.SYS.DATABASES WHERE name = N'intellixv2') create database intellixv2 on (NAME=intellix_data, FILENAME='c:\mssql\intellixv2.mdf') log on (NAME=intellix_log, FILENAME='c:\mssql\intellixv2.ldf')"
    }
}

Write-Output "Create or update the database..."
& /sqlpackage/sqlpackage /Action:Publish /SourceFile:IntellixDatabase.dacpac /TargetDatabaseName:intellixv2 /TargetServerName:$sqlServer /TargetUser:$sqlUser /TargetPassword:$sqlPw /p:BlockOnPossibleDataLoss=false

if ($env:intellixDbUser) {
    Write-Output "Create or update the database user..."
    $intellixDbUser = $env:intellixDbUser;
    $intellixDbPassword = $env:intellixDbPassword;
    $cuCommand = "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$intellixDbUser')
        BEGIN
            PRINT 'Change password of user ""$intellixDbUser""';
            ALTER USER [$intellixDbUser] WITH PASSWORD = '$intellixDbPassword'; 
        END
        ELSE BEGIN
            PRINT 'Create user ""$intellixDbUser""';
            CREATE USER [$intellixDbUser] WITH PASSWORD = '$intellixDbPassword'; 
            ALTER ROLE db_owner ADD MEMBER [$intellixDbUser];
        END"

    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Database intellixv2 -Query $cuCommand -Verbose
}

if ($env:intellixUserName) {
    Write-Output "Create or update the administrative Intelligent Indexing user..."
    $vars = "userName='$($env:intellixUserName)'", "password='$($env:intellixUserPassword)'" 
    $q = "Execute AddOrUpdateAdminUser `$(userName), `$(password)"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Database intellixv2 -Query $q -Variable $vars -Verbose

    $q = 'DECLARE @userName varchar(100) = $(userName) 
    DECLARE @msName varchar(100) = ''Default_'' + @userName; 
    IF NOT EXISTS (SELECT 1 FROM Modelspaces where Name=@msName) 
    BEGIN
        PRINT ''Creating modelspace '' + @msName
        DECLARE @uid int;
        select top(1) @uid=Id from Users where Name = @userName
        insert into Modelspaces(Name, CreatedBy) values (@msName, @uid)
    END'
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Database intellixv2 -Query $q -Variable $vars -Verbose
}
