Import-Module SqlServer

$additionalWaitTime = 0

if ($env:sqlServerInstance) {
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
    $sqlServer = 'intellix-sql-setup'
    $sqlUser = 'sa'
    $sqlPw = 'Admin001'
    $additionalWaitTime = 3
}

$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder.Server = $sqlServer
$builder.User = $sqlUser
$builder.Password = $sqlPw
$connectionString = $builder.ConnectionString

$transient = @(0, 18401)

for ($i = 0; $i -lt 10; $i++) {
    $s = $i + $additionalWaitTime;
    if ($s -gt 0) {
        Write-Output "Connecting in $s seconds with the the SQL Server..."
        Start-Sleep $s
    }
    else {
        Write-Output "Connecting with the the SQL Server..."
    }

    try {        
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $sqlConnection.Open()

        $cmd = New-Object System.Data.SqlClient.SqlCommand -ArgumentList @(
            "sp_configure 'contained database authentication', 1;
            RECONFIGURE", $sqlConnection)
        $cmd.ExecuteScalar();
        $sqlConnection.Close()

        Write-Output "Successfully applied contained database authentication"
        $ok = $true
        break;
    }
    catch [System.Data.SqlClient.SqlException] {
        $ex = $_.Exception
        $err = $ex.Errors[0]

        if ($err.Number -eq 18401) {
            Write-Warning "The database service is in upgrade mode. We must be patient! I wait and continue in 20 seconds..."
            Start-Sleep 20
        }
        elseif ($err.Number -eq 0) {
            Write-Warning "The SQL Server cannot be reached. I will retry: $($ex.Message)"
        }
        elseif (($err.Number -eq 18456) -and (-not $env:sqlServerInstance)) {
            Write-Warning "The SQL Server password is not yet applied. This can happen if the initialization phase of the server is not completed. I will retry: $($ex.Message)"
        }        
        else {
            Write-Warning "There is an SQL Server connection problem with number $($err.Number) of class $($err.Class)"
            if ((-not $transient.Contains($err.Number)) -and $err.Class -lt 17) {
                Write-Warning "A non-recoverable error occured when connecting to the SQL Server: $($err.Message)"
                break
            }
        }
    }
    catch {
        Write-Warning "The SQL Server cannot be reached."
    }
}

if (!$ok) {
    Write-Error "The SQL Server is not there, or there is a problem with the network or with the credentials. Giving up."
    exit 1;
}

if ($IsWindows) {
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

    $alg = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($env:intellixUserPassword, 32, 5000, "SHA512");
    $salt = [System.Convert]::ToBase64String($alg.Salt);
    
    # Invoke-SqlCmd does not like '=' characters - they have to be escaped!
    # We work around this by replacing '=' with a special string - and revert this in the SQL query
    $salt = $salt.Replace("=", "*EQUALSIGN*")

    $hash = $alg.GetBytes(32);
    $seq = $hash | foreach-object { $_.ToString("X2") }
    $byteArray = "0x" + [System.String]::Join("", $seq)    

    $vars = "userName='$($env:intellixUserName)'", "hash=$byteArray", "salt='$salt'"
    $q = "declare @x varchar(100) = REPLACE(`$(salt),'*EQUALSIGN*','='); Execute AddOrUpdateAdminWithPasswordHash `$(userName), `$(hash), @x , 1"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Database intellixv2 -Query $q -Variable $vars -Verbose
    if (!$?) {
        exit -1
    }

    # Create default modelspace
    $q = 'DECLARE @userName varchar(100) = $(userName) 
    DECLARE @msName varchar(100) = ''Default_'' + @userName; 
    IF NOT EXISTS (SELECT 1 FROM Modelspaces where Name=@msName) 
    BEGIN
        PRINT ''Creating modelspace '' + @msName
        DECLARE @uid int;
        select top(1) @uid=Id from Users where Name = @userName
        insert into Modelspaces(Name, CreatedBy) values (@msName, @uid)
    END'

    $vars = "userName='$($env:intellixUserName)'"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Username $sqlUser -Password $sqlPw -Database intellixv2 -Query $q -Variable $vars -Verbose
    if (!$?) {
        exit -1
    }
}
