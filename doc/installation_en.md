# Installation Instructions for Intelligent Indexing V2

__Beta Test__

> :warning: This version of Intelligent Indexing is intended for closed beta testing only and must not be used in a production environment.

## Introduction

This document describes the installation of DocuWare Intelligent Indexing and all additional components required. Instructions for configuring Intelligent Indexing and working with Intelligent Indexing are available as separate documents in the [DocuWare Knowledge Center](https://help.docuware.com).

### System Requirements

The following requirements must be met for installation:

- Newly installed Windows Server 2019 (build 1809, Standard or Datacenter Edition)
- 8 processor cores
- 16 GB RAM
- Access to SQL Server 2019

It is recommended that you install Intelligent Indexing on a separate server to achieve the best possible performance. Intelligent Indexing can be used in combination with DocuWare Version 6.1 or higher. If you use SQL Server 2019 for your DocuWare system or for an existing Intelligent Indexing installation, you can also use it for Intelligent Indexing V2. Otherwise, you must set up a separate SQL server.

For the installation described below, administrator rights and an Internet connection are required. All commands in these installation instructions must be entered in the Powershell. The Powershell ISE is not supported.

### Overview of the Required Files

To download the installation files, go to [https://github.com/DocuWare/Intellix](https://github.com/DocuWare/Intellix), click on the green Code button, then on Download ZIP, and extract the file. You can also download and extract the file with the following PowerShell script. First switch to the target directory for the download with PowerShell:

```powershell
$tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
Invoke-WebRequest https://github.com/DocuWare/Intellix/archive/master.zip -OutFile $tmp
Expand-Archive $tmp -DestinationPath master
$tmp | Remove-Item
```

To install and run Intelligent Indexing, the content of the `scripts` directory is required. Copy this directory to a location that you want to use permanently. This directory will be referred to in the following as the installation directory.

You can also move the complete directory to another location later.

An overview of the individual files can be found in the [Appendix](#overview-of-the-intelligent-indexing-setup-files). You also need your DocuWare license file, which you can download from the [DocuWare Partner Portal](https://login.docuware.com).

### Docker Containerization

Intelligent Indexing runs virtually in two Docker containers. These run independently of other applications installed on your host computer and are supplied preconfigured. The installation effort for Intelligent Indexing V2 is therefore very low.

The Docker containers are:

- __intellix_app__: The code for Intelligent Indexing
- __intellix_solr__: The SolR full text search engine

In addition, a SQL Server database that runs outside the Docker container is required.

### Overview of the Instructions

The installation is divided into the following steps:

- [Allowing Execution of Scripts](#allowing-execution-of-scripts)
- [Installation of the Docker Environment](#installation-of-the-docker-environment)
- [Installation of the Database Server](#installation-of-the-database-server)
- [Installation of the IIS Web Server](#installation-of-the-iis-web-server)
- [Management of Intelligent Indexing](#management-of-intelligent-indexing)
- [Licensing Intelligent Indexing](#licensing-intelligent-indexing)
- [Connection to DocuWare](#connection-to-docuWare)

## Allowing Execution of Scripts

By default, Windows Server prevents PowerShell scripts from running. The permissions therefore need to be adjusted for the installation process.

To check the current setting, run the following command in PowerShell as administrator:

```powershell
Get-ExecutionPolicy
```


If the result is displayed as `Unrestricted`, you do not need to change anything. If a value other than `Unrestricted` is displayed, you must use the following command to allow unsigned scripts to run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
```
After executing the command, all commands can be executed in the __current PowerShell session__. You have to execute this command again in every PowerShell window.

If you want to remove the block completely, you can also use `CurrentUser` or `LocalMachine` as the scope.

## Installation of the Docker Environment

Intelligent Indexing runs in Docker containers. Therefore, a Docker environment first needs to be installed. In PowerShell as administrator, switch to the installation directory and run the following command:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-Docker.ps1
```

You can ignore the warning that the `version` and `Properties` properties cannot be found.

Now start the host computer again:

```powershell
Restart-Computer
```

After the reboot, wait about one minute and then execute the following command in the PowerShell as administrator in the installation directory to test the Docker installation:

```powershell
docker run --rm --name helloworld hello-world:nanoserver
docker-compose --version
```

A Docker container with about 100 MB is downloaded and launched. If Docker is installed correctly, you will see the following output:

```text
Hello from Docker!

This message shows that your installation appears to be working correctly.
```

Also check whether you can see the line

```text
docker-compose version...
```

in the last line of the output. This ensures that Docker-Compose, which is required for the interaction of the Docker containers, has also been correctly installed.

## Installation of the Database Server

Intelligent Indexing works together with a SQL Server 2019 database. On older versions of SQL Server, the following installation may differ or fail. If you use a SQL Server 2019 for your DocuWare system, you can also use it for Intelligent Indexing. Otherwise, you must set up a separate SQL server.

If you set up a separate database server for Intelligent Indexing, you can use the free SQL Server 2019 Express. However, this is limited to 10 GB of memory, which is enough space for about 1,000,000 simple documents. You can download it from the following link: [https://www.microsoft.com/en-us/sql-server/sql-server-downloads](https://www.microsoft.com/en-us/sql-server/sql-server-downloads).

Direct download and installation is possible via the following commands:

```powershell
Invoke-WebRequest https://go.microsoft.com/fwlink/?linkid=866658 -OutFile SQL2019-SSEI-Expr.exe

.\SQL2019-SSEI-Expr.exe
```

At the beginning of the installation you can choose the Basic variant. If you are asked for a collation during the installation of the database server, we recommend the collation `SQL_Latin1_General_CP1_CI_AS`. At the end of the installation, you should opt to install the SQL Server Management Studio (SSMS) as well. The computer must be restarted after this.

If you are using a newly set up SQL Server, you can configure the database using a PowerShell script that you run locally on the database server machine. You may need to copy the Intelligent Indexing setup files to the computer with the database server.

The script will restart the database server. If you do not want to do this or if you have to adapt the setup to your situation, the [Appendix](#manual-setup-of-the-database-server) contains an overview of the required steps and how they can be performed manually in SQL Server Management Studio.

In a PowerShell, execute the following script on the computer with the database server as administrator in the installation directory. If you have just installed SQL Server Express, execute the following commands __in a new PowerShell window__:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Init-Database.ps1
```

You must specify the following parameters for this:

- `dbIntellixUser` and `dbIntellixUserPassword`: These are the database credentials that Intelligent Indexing will use to access the database. You must enter these values into the configuration file in the [Configuration of Intelligent Indexing](#configuration-of-intelligent-indexing) section. The SQL Server requires a strong password. For more information about this, go to <https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15>
- `serverInstance`: This value specifies the name of the database server instance, for example `SQLEXPRESS`.
- `intellixAdminUser` and `intellixAdminUserPassword`: These are the credentials that DocuWare uses to access Intelligent Indexing. You must enter these values into the Intelligent Indexing connection file in the [Connection to DocuWare](#connection-to-docuWare) section. The password should be secure, but should not contain any of the following 5 special characters, as these can cause problems in the connection file: `& < > " '`
  
The parameters can also be passed to the script:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Init-Database.ps1 -serverInstance SQLEXPRESS -dbIntellixUser intellix -dbIntellixUserPassword MyVerySeKRe!tPasSw0rD -intellixAdminUser intellixAdmin -intellixAdminUserPassword an00tHerVerySeKRe!tPasSw0rD
```

If you run an old version of Intelligent Indexing On-Premise on the same database server, you can install Intelligent Indexing V2 in parallel. The old version uses the `intellix` database, the current version uses the `intellixv2` database.

As a test, log in to the database server via the SQL Server Management Studio. Set the `Server name` as the name of the database server host, the server instance, and the port 1433, e.g. `intellix\SQLEXPRESS,1433`. Select the value `SQL Server Authentication` for `Authentication`. For the `Login` and `Password`, use the values you selected above for the parameters `dbIntellixUser` and `dbIntellixUserPassword`. On the database server, the database `intellixv2` must be available under the `Databases` entry.

## Installation of the IIS Web Server

To install, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-IIS.ps1
```

The script installs the IIS web server with the components `UrlRewrite` and `ARR`.

If you want to use a connection via `https`, you must click `Bindings...` on the right in the IIS interface under `Sites` -> `Default Web Site`, enter a valid certificate there under the `https` binding, and save the certificate in the corresponding certificate stores. In the connection file (see [Connection to DocuWare](#connection-to-docuware)) you can then enter `https` instead of `http`.

## Management of Intelligent Indexing

### Configuration of Intelligent Indexing

In the installation directory you will find a `configuration.env` file for configuring Intelligent Indexing. Adjust the following values to your installation and then save the file again:

- `ConnectionStrings:IntellixDatabaseEntities`: The connection string for the database connection. Change the values for `Server`, `user id`, and `password` according to your database server. `user id` and `password` correspond to the parameters `dbIntellixUser` and `dbIntellixUserPassword`, which you specified in the script for configuring the database in the [Installation of the Database Server](#installation-of-the-database-server) section. `Server` is the name of the database server. If the database server is installed on the host computer, you must use `$$internalgw$$` as the default name for the computer. If you are not using SQL Server Express or port `1433`, you must change the entries accordingly. The script for setting up the database in the [Installation of the Database Server](#installation-of-the-database-server) section uses port `1433`.

- The next entries define different directories on the host computer. Document information is stored under `E_FileStoragePath`. The data of the SolR full text search engine is stored under `E_SolRDataPath`. You can also change these directories later while Intelligent Indexing is stopped. To do this, you must also copy the contents of the directories to the new location. All these directories are independent of the installation directory where the Intelligent Indexing setup files are stored.

Changes to these values only take effect after a restart of Intelligent Indexing.

## Installation of Intelligent Indexing

To install, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

This will download the current Docker images from Intelligent Indexing. These are automatically managed by the Docker environment. The Docker images are several GB in size.

### Starting Intelligent Indexing

To start Intelligent Indexing, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Start-Intellix.ps1
```

The first time you start Intelligent Indexing, the directories you specified in the configuration file are created.

### Testing the Components of Intelligent Indexing and Changing the Password
You can use the following script to check which Docker containers are currently running on the host computer:

```powershell
docker ps -a
```

You should get one line each as output for the Docker containers __intellix_app__ and __intellix_solr__. In the `Status` column, you can see whether the Docker containers are running (`Up...`) or have been ended (`Exited...`). You can also see in this column whether the containers are accessible in principle. At startup, (`health: starting`) is displayed here. If the containers respond successfully to requests, (`healthy`) is displayed.

After starting Intelligent Indexing, you can navigate to <http://localhost/intellix-v2/Html> on the host computer to call up the administration interface. This can lead to problems when using Internet Explorer. In this case, use a different browser.

You can log in with the user name and password you specified via the parameters `intellixAdminUser` and `intellixAdminUserPassword` in the script for initializing the database in the [Installation of the Database Server](#installation-of-the-database-server) section.

Also test here whether you can access the host computer via a browser from the computer on which DocuWare is installed. From another computer, call up the URL http://_computername_/intellix-v2/Html/, replacing _\_computername\__ with the name of the host computer.

At <http://localhost:8983> you can access the SolR full text search engine from your host computer.

### Logging

To log Intelligent Indexing, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-IntellixLogs.ps1
```

To log the SolR full text search engine, execute the following script:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-SolrLogs.ps1
```

Both scripts display log outputs live. The output can be canceled by pressing `Ctrl+C`.

###Stopping Intelligent Indexing

To stop Intelligent Indexing, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Stop-Intellix.ps1
```

### Updating Intelligent Indexing

Use the following script to check for and download any updates or hotfixes for Intelligent Indexing:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

Docker images that are no longer needed are automatically deleted. The download size will in most cases be several 100 MB. You can run this script while Intelligent Indexing is running. The changes will not take effect until you run `Stop-Intellix.ps1` and `Start-Intellix.ps1` after this script is finished. Even restarting the host computer will not install a downloaded update.

### Restarting the Host Computer

The Docker environment manages the running Intelligent Indexing containers. These are configured so that Intelligent Indexing shuts down and automatically restarts when the host computer is rebooted. If Intelligent Indexing was not running before the restart, it will not start after the restart.

## Licensing Intelligent Indexing

You can download the DocuWare license file from the [DocuWare Partner Portal](https://login.docuware.com). In the Intelligent Indexing administration interface, you can upload it under the Licensing section and in order to license your Intelligent Indexing installation.

## Connection to DocuWare

The installation directory contains the Intelligent Indexing connection file `intelligent-indexing-connection.xml`, which DocuWare uses to establish the connection to Intelligent Indexing.

Open this file in a text editor. In line 3, enter the address at which the host computer was accessible from the computer with the DocuWare installation, but without the `Html` at the end. The name of the host computer or its static IP address must therefore be entered instead of `localhost`. For example, if you could reach Intelligent Indexing from your DocuWare computer at `http://intellix/intellix-v2/Html`, enter `http://intellix/intellix-v2/` here. If you have configured the web server for connection via `https` (see [Installation of the IIS Web Server](#installation-of-the-iis-web-server)), you can enter `https` instead of `http` here.

In lines 4 and 5, enter the user name and password you specified via the parameters `intellixAdminUser` and `intellixAdminUserPassword` in the script for initializing the database in the [Installation of the Database Server](#installation-of-the-database-server) section. The name of the model space is entered in line 6. Enter `Default_` here followed by the user you have selected. For example, if you have selected `admin` as user, you should enter `Default_admin` here. The remaining values do not need to be adjusted. Save the file again.

You can now upload the Intelligent Indexing connection file to your DocuWare installation to establish the connection with Intelligent Indexing. To do this, log in to DocuWare Administration and navigate to `DocuWare System` -> `Data Connections` -> `Intelligent Indexing Service connections`. If a connection is already entered here, you can open it, remove your organization under Organizations, and click `Apply`. This disables the connection of your DocuWare system to your old Intelligent Indexing system, but it can be reactivated by adding the organization again. Then right-click `Intelligent Indexing Service connections` on the left side and select `Install Intelligent Indexing Service file`. In the dialog that opens, select the `intelligent-indexing-connection.xml` file you edited. Then click `Apply` and close DocuWare Administration.

## Appendix

### Overview of the Intelligent Indexing Setup Files

You will need to modify the following files during the installation process:

- Configuration file `configuration.env`
- Intelligent Indexing connection file `intelligent-indexing-connection.xml` for establishing the connection between DocuWare and Intelligent Indexing

The remaining Intelligent Indexing setup files must not be modified:

- PowerShell scripts
  –	`Install-Docker.ps1`, `Install-IIS.ps1`, `Init-Database.ps1`: Scripts for installing Docker and the IIS web server and for initializing the database server
  –	`Update-Intellix.ps1`, `Start-Intellix.ps1`, `Stop-Intellix.ps1`: Scripts for updating, starting, and stopping Intelligent Indexing
  –	`Show-IntellixLogs.ps1` and `Show-SolRLogs.ps1`: Scripts for displaying log outputs of Intelligent Indexing and the SolR full text search
  –	`Read-IntellixConfiguration.ps1`: This script is used by the other scripts to read the configuration file
- Database script `init_database.sql` for initializing the database
- The `docker-compose.yml` file needed by the Docker environment to control the interaction between the Docker containers

### Manual Setup of the Database Server

The following steps are necessary to set up the Intelligent Indexing database. These are also executed by the script `Init-Database.ps1`.

- Run the `init_database.sql` script in SQL Server Management Studio in `SQLCMD Mode`. This sets up the `intellixv2` database.
- In SQL Server Management Studio, enable `SQL Server and Windows Authentication mode`.
- Create a login/user who is allowed to access the `intellixv2` database.
- Enable access to the database server via TCP on port `1433`.
- Restart the database server.
- Create a rule in the firewall on the database server machine to allow incoming connections via TCP port `1433`.

Note that access via TCP and the rule in the firewall are also necessary if the database server and Intelligent Indexing are installed on the same machine, since Intelligent Indexing runs within a Docker container.
