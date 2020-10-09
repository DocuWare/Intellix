# Installation Instructions for Intelligent Indexing V2

__Beta Test__

> :heavy_exclamation_mark: This version of Intelligent Indexing is intended for closed beta testing only and must not be used in a production environment.

## Introduction

This document describes the installation of DocuWare Intelligent Indexing and all additional components required. Instructions for configuring Intelligent Indexing and working with Intelligent Indexing are available as separate documents in the [DocuWare Knowledge Center](https://help.docuware.com).

### System Requirements

The following requirements must be met for installation:

- Windows Server 2019 (Core, Standard or Datacenter Edition)
- 4 processor cores
- 8 GB RAM
- Optional: Access to SQL Server 2019

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

To install and run Intelligent Indexing, the content of the `scripts` directory is required. Copy this directory to a location that you want to use permanently. This directory will be referred to in the following as the _installation directory_.

An overview of the individual files can be found in the [Appendix](#overview-of-the-intelligent-indexing-setup-files). You also need your DocuWare license file, which you can download from the [DocuWare Partner Portal](https://login.docuware.com).

### Docker Containerization

Intelligent Indexing runs in Docker containers. A setup script configures the containers, so that the installation effort for Intelligent Indexing V2 is therefore very low.

The Docker containers are:

- __app__: The code for Intelligent Indexing
- __solr__: The SolR full text search engine
- __sql__: In case you do not want to use your SQL Server installation, we provide an SQL Express in a container.

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

For the database you can choose from the following options:

### Option 1: Use the SQL Server Express which comes as container image

This is recommended for most installations.
In this scenario, the installation of Intelligent Indexing is very simple, because no further configuration of the database server is needed. You do not care about configuring the database - this is fully managed by the setup script.

However, SQL Express limits the size of the stored data. If you expect a very high data volume (i.e. several thousands documents each day) then you should go for the other option. If the size limit becomes a problem later, you can migrate to your own database server.

### Option 2: Use your own database server

You should choose this option if you expect a high volume of documents, or if you want to have full control of the Intelligent Indexing database. Intelligent Indexing expects SQL Server 2019. On older versions of SQL Server, the fails. If you use a SQL Server 2019 for your DocuWare system, you can also use it for Intelligent Indexing.

If you want to setup your own SQL Server, you can start with an installation of
[SQL Server 2019 Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads). Download it and follow the setup instructions.

It is important, that your SQL Server is configured like this:

- TCP Connections on port 1433.
- SQL Server authentication must be enabled. The containers do not support integrated authentication.
- A SQL Server account should be available for the setup script. This account must have the permission to create a new database and to create database object inside the new database.
- The firewall must have the ports configured so that the Docker containers can connect to the database.

Note that Intelligent Indexing requires self-contained databases. Therefore, the following SQL is executed by the setup script:

```sql
sp_configure 'contained database authentication', 1
GO
RECONFIGURE
GO
```

If this is not what you want, you should install a separate SQL Server instance for Intelligent Indexing.

## Setup

The Intelligent Indexing setup configures the database and the container infrastructure. When the setup runs, some container images are pulled and the container, which contains the database setup, is built and executed.

The setup creates a directory structure at `C:\ProgramData\IntellixV2`, which is used to persist the data for Intelligent Indexing. Please consider this directory in you backups, use junctions to mount this
directory to an external storage.

The setup is triggered by running the `setup-intellix.ps1` in the `setup` folder. You must specify the following parameters:

- `IntellixDbUser` and `IntellixDbPassword`: These are the database credentials that Intelligent Indexing will use to access the database. You should use a strong password which matches the [SQL Server password policy](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15). These values must be specified only on the initial setup. If you run the setup a second time, the values are not needed anymore.

  This SQL account with the specified credentials is created in the intellixv2 database, and no logins are created on your SQL Server.
  
  :bulb: These values must be specified on the initial setup only. If you run the setup a second time, the values are not needed anymore.  

- `IntellixAdminUser` and `IntellixAdminPassword`: These are the credentials that DocuWare uses to access Intelligent Indexing. The password should be secure, but should not contain any of the following 5 special characters, as these can cause problems in the connection file: `& < > " '`.
  
  :bulb: These values must be specified on the initial setup only. If you run the setup a second time, the values are not needed anymore.

- `LicenseFile`: The path to the license file. If the license file is not specified on the setup, it can be uploaded after the setup in the Intelligent Indexing UI.

  :bulb: To make the service ready to use right after the installation, it is recommended to specify the license file when running the setup. If you do not have a license file, visit the [DocuWare Partner Portal](https://login.docuware.com).

- `SqlServerInstance`, `SqlServerInstanceUser` and `SqlServerInstancePassword`: This value specifies the instance and the credentials to access your own SQL Server.
  
  :warning: If you use the containerized SQL Server, you must not pass these parameters.

If you run an old version of Intelligent Indexing On-Premise on the same database server, you can install Intelligent Indexing V2 in parallel. The old version uses the `intellix` database, the current version uses the `intellixv2` database.
  
### Examples

There are two example scripts `Run-Setup-Example.ps1` and
`Run-Setup-With-Own-SqlServer-Example.ps1` provided. You can modify the scripts and use them
to run the setup and start the service when the setup is finished.

Simple Intelligent Indexing installation with Intelligent Indexing license file:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\setup\setup-intellix.ps1 `
  -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic' `
  -IntellixAdminUser intellix  `
  -IntellixAdminPassword ThIsiS_VarYYSecreTT001 `
  -IntellixDbUser IntellixAdminDb `
  -IntellixDbPassword htThIsiS_VarYYSecreTT001UUi649mj60Jffdf_f634 `
  -SqlServerInstance my-sql-2019-box `
```

Installing Intelligent Indexing with your own SQL Server, but without Intelligent Indexing license file:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\setup\setup-intellix.ps1 `
  -IntellixAdminUser intellix  `
  -IntellixAdminPassword ThIsiS_VarYYSecreTT001 `
  -IntellixDbUser IntellixAdminDb `
  -IntellixDbPassword htThIsiS_VarYYSecreTT001UUi649mj60Jffdf_f634 `
  -SqlServerInstance my-sql-2019-box `
  -SqlServerInstanceUser sa `
  -SqlServerInstancePassword MYAb0luTe1ySecre!tAKKSESS
```

### Troubleshooting

In case the setup fails, you should enable the _verbose output_ of Powershell and then run the setup again.
This can be enabled with:

```powershell
$VerbosePreference = "Continue"
$InformationPreference = "Continue"
```

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

The setup generates files, which are used by the containers to connect to the
database and to store the files and the index data for Apache Solr. The data
is stored at `C:\ProgramData\IntellixV2`. If you want to store the data
at a different location, we recommend to move the folder to a location of
your choice and create junctions or soft links using the [mklink](https://docs.microsoft.com/de-de/windows-server/administration/windows-commands/mklink) command or with `New-Item`:

```powershell
Stop-Intellix.ps1
Move-Item -Path C:\ProgramData\IntellixV2 -Destination d:\a-lot-of-space\intellixv2

New-Item -ItemType Junction -Path C:\ProgramData\IntellixV2 `
  -Value d:\a-lot-of-space\intellixv2

Start-Intellix.ps1
```

### Starting Intelligent Indexing

To start Intelligent Indexing, run the following script in PowerShell as administrator in the installation directory:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Start-Intellix.ps1
```

### Testing the Components of Intelligent Indexing

You can use the following script to check which Docker containers are currently running on the host computer:

```powershell
docker ps -a
```

You should get one line each as output for the Docker containers __intellix_app__ and __intellix_solr__. In the `Status` column, you can see whether the Docker containers are running (`Up...`) or have been ended (`Exited...`). You can also see in this column whether the containers are accessible in principle. At startup, (`health: starting`) is displayed here. If the containers respond successfully to requests, (`healthy`) is displayed.

After starting Intelligent Indexing, you can navigate to <http://localhost/intellix-v2/Html> on the host computer to call up the administration interface.

> :warning: Internet Explorer is not supported.

You can log in with the user name and password you specified via the parameters `IntellixAdminUser` and `IntellixAdminPasswird` in setup.

Also test here whether you can access the host computer via a browser from the computer on which DocuWare is installed. From another computer, call up the URL http://_computername_/intellix-v2/Html/, replacing _\_computername\__ with the name of the host computer.

### Logging

To view the live log of Intelligent Indexing, run the following PowerShell script:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-IntellixLogs.ps1
```

The output can be canceled by pressing `Ctrl+C`.

### Stopping Intelligent Indexing

To stop Intelligent Indexing, run the following script in PowerShell script:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Stop-Intellix.ps1
```

### Updating Intelligent Indexing

DocuWare is constantly improving Intelligent indexing. To apply the updates, it is enough to pull
updated images and restart the service.

Use the following script to check for and download any updates or hotfixes for Intelligent Indexing:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

You can run this script while Intelligent Indexing is running. The changes will not take effect until you 
run `Stop-Intellix.ps1` and `Start-Intellix.ps1` after this script is finished. This step can be simplfied
if the `WithRestart`parameter is added:

```powershell
# Only necessary if the PowerShell execution policy is not 'Unrestricted.'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1 -WithRestart
```

### Restarting the Host Computer

The Docker environment manages the running Intelligent Indexing containers. These are configured so that Intelligent Indexing shuts down and automatically restarts when the host computer is rebooted. If Intelligent Indexing was not running before the restart, it will not start after the restart.

## Licensing Intelligent Indexing

You can download the DocuWare license file from the [DocuWare Partner Portal](https://login.docuware.com). In the Intelligent Indexing administration interface, you can upload it under the Licensing section and in order to license your Intelligent Indexing installation.

## Connecting DocuWare with Intelligent Indexing

The setup generates a connection file for DocuWare. The installation directory contains this file at `\setup\run\intelligent-indexing-connection.xml`.

This file contains the connection URL. In case your server is exposed with a different name than the machine name, or you configured the IIS to use `https`, you should change this URL in this file.

You can now upload the Intelligent Indexing connection file to your DocuWare installation to establish the connection with Intelligent Indexing. To do this, log in to DocuWare Administration and navigate to `DocuWare System` -> `Data Connections` -> `Intelligent Indexing Service connections`. If a connection is already entered here, you can open it, remove your organization under Organizations, and click `Apply`. This disables the connection of your DocuWare system to your old Intelligent Indexing system, but it can be reactivated by adding the organization again. Then right-click `Intelligent Indexing Service connections` on the left side and select `Install Intelligent Indexing Service file`. In the dialog that opens, select the `intelligent-indexing-connection.xml` file you edited. Then click `Apply` and close DocuWare Administration.

## Appendix

### Overview of the Intelligent Indexing Script Files

- `Install-Docker.ps1` and `Install-IIS.ps1`: Scripts for installing Docker and the IIS web server

- `Update-Intellix.ps1`, `Start-Intellix.ps1`, `Stop-Intellix.ps1`: Scripts for updating, starting, and stopping Intelligent Indexing

- `Show-IntellixLogs.ps1`: Scripts for displaying log outputs of Intelligent Indexing and the SolR full text search

- `setup/Setup-Intellix.ps1`: Scripts for displaying log outputs of Intelligent Indexing and the SolR full text search
