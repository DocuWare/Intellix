# Installing Intelligent On-Premise on Linux

## Introduction

This documentation explains how to setup Intelligent On-Premise on an Ubuntu Host.
This documentation is working for Ubuntu 20.04 and Debian 10.

Instructions for configuring Intelligent Indexing and working with
Intelligent Indexing are available as separate documents in the
[DocuWare Knowledge Center](https://help.docuware.com).

### System Requirements

The following minimum requirements must be met for installation:

- Ubuntu 20.04 or Debian 10. The installation may or may not work on other Linux versions.
- 2 processor cores
- 4 GB RAM
- Optional: Access to SQL Server 2019

It is recommended that you install Intelligent Indexing on a separate server to achieve
the best possible performance.
If you install Intelligent Indexing on a machine together with other services,
you should ensure that no other application is using port 80.

Intelligent Indexing can be used in combination with all
[supported DocuWare Versions](https://support.docuware.com/en-US/support/docuware-support-lifecycle-policy/).
If you use SQL Server 2019 for your DocuWare system or for an existing
Intelligent Indexing installation, you can also use it for Intelligent Indexing V2.
Otherwise, you must set up a separate SQL server.

### Overview of the Required Files

To get the installation files, just clone our repository from Github:

```bash
sudo apt-get install git -y
git clone https://github.com/DocuWare/Intellix.git
```

or get it as ZIP file and extract it:

```bash
tmp=$(mktemp) && curl -SL https://github.com/DocuWare/Intellix/archive/master.zip -o $tmp && unzip $tmp && rm $tmp
```

To install and run Intelligent Indexing, the content of the `linux` directory is required.
Copy this directory to a location that you want to use permanently.

You also need your DocuWare license file, which you can download from the
[DocuWare Partner Portal](http://go.docuware.com/partnerportal-login).

### Docker Containerization

Intelligent Indexing runs in Docker containers. A setup script configures the containers,
so that the installation effort for Intelligent Indexing Version 2 is therefore very low.

The Docker containers are:

- __intellix-app__: The Intelligent Indexing service
- __intellix-solr__: The SolR full text search engine
- __intellix-sql__: In case you do not want to use your SQL Server installation,
  we provide an SQL Express in a container.

### Overview of the Instructions

The installation is divided into the following steps:

- [Installation of the Docker Environment](#installation-of-the-docker-environment)
- [Installation of the Database Server](#installation-of-the-database-server)
- [Setup](#setup)
- [Management of Intelligent Indexing](#management-of-intelligent-indexing)
- [Licensing Intelligent Indexing](#licensing-intelligent-indexing)
- [Connecting DocuWare with Intelligent Indexing](#connecting-docuware-with-intelligent-indexing)

## Installation of the Docker Environment

We assume that you start with a fresh Linux system. If Docker not installed, you can install it from the distribution's repository:

```bash
sudo apt-get install docker docker-compose -y
```

> **Warning**: If you installed Docker on Ubuntu with snap, please uninstall
> the Docker snap. When Intelligent Indexing is installed, some volume mounts
> are created in `/var`, where the Docker snap does not have access.

If you want to install the recent version of Docker, consult the installation instructions for [Ubuntu](https://docs.docker.com/engine/install/ubuntu/) or [Debian](https://docs.docker.com/engine/install/debian/).

In order to make the current user able to execute docker commands, it is convenient to add the current user to the group `docker`:

```bash
sudo usermod -aG docker $USER
```

Log out and log in after executing this command, so that the new membership is evaluated.

## Installation of the Database Server

For the database you can choose from the following options:

### Option 1: Use the SQL Server which comes as container image

This is recommended for most installations.
In this scenario, the installation of Intelligent Indexing is very simple, because no further
configuration of the database server is needed. You do not need to care about the
database setup and configuration - this is fully managed by the setup script.

By default, the container is setup to run the SQL Server as Express edition. If needed, you can change this later by
[applying a product key](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-environment-variables?view=sql-server-ver15).

### Option 2: Use your own database server

You should choose this option if you expect a high volume of documents,
or if you want to have full control of the Intelligent Indexing database.
Intelligent Indexing expects SQL Server 2019. On older
versions of SQL Server, the setup fails. If you use a SQL Server 2019 for your
DocuWare system, you can also use it for Intelligent Indexing.

It is important, that your SQL Server is configured like this:

- TCP Connections on port 1433.
- SQL Server authentication must be enabled.
  The containers do not support integrated authentication.
- A SQL Server account should be available for the setup script.
  This account must have the permission to create a new database.
- The firewall must have the ports configured so that the Docker
  containers can connect to the database.

Note that Intelligent Indexing requires self-contained databases.
Therefore, the following SQL is executed by the setup script:

```sql
sp_configure 'contained database authentication', 1
GO
RECONFIGURE
GO
```

If this is not what you want, you should install a separate
SQL Server instance for Intelligent Indexing.

## Setup

The Intelligent Indexing setup configures the database and the container infrastructure.
When the setup runs, some container images are pulled and the container,
which contains the database setup, is built and executed.

The setup creates a directory structure at `/var/intellix`,
which is used to persist the data for Intelligent Indexing.
Please consider this directory in you backups, use junctions to mount this
directory to an external storage.

> :bulb: If you expect a high volume of documents,
> you should consider mounting this
> directory on a separate volume.

The setup is triggered by running the `setup-intellix.sh` in the `setup` folder.
You can apply the following parameters:

- `--intellix-db-user` and `--intellix-db-password`: These are the database credentials that
  Intelligent Indexing will use to access the database.
  You should use a strong password which matches the
  [SQL Server password policy](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15).
  These values need be specified only on the initial setup.

  This SQL account with the specified credentials is created in the intellixv2 database,
  and no logins are created on your SQL Server.
  
  :bulb: These values should be specified on the initial setup only.
  If you run the setup a second time, the values are not needed anymore.  

- `--intellix-admin-user` and `--intellix-admin-password`: These are the credentials that DocuWare
  uses to access Intelligent Indexing. The password should be secure, but should not contain any
  of the following 5 special characters, as these can cause problems in the connection file:
  `& < > " '`.
  
  :bulb: These values should be specified on the initial setup only.
  If you run the setup a second time, the values are not needed anymore.

- `--license-file`: The path to the license file. If the license file is not specified on the setup,
  it can be uploaded after the setup in the Intelligent Indexing UI.

  :bulb: To make the service ready to use right after the installation,
  it is recommended to specify the
  license file when running the setup. If you do not have a license file, visit the
  [DocuWare Partner Portal](http://go.docuware.com/partnerportal-login).

- `--sql-server-instance`, `--sql-server-instanceUser` and `--sql-server-instance-password`:
  These values specify the instance and the credentials to access your own SQL Server.
  
  :warning: If you use the containerized SQL Server, you must not pass these parameters.

If you run an old version of Intelligent Indexing On Premises on the same
database server, you can install
Intelligent Indexing Version 2 in parallel. The old version uses the
`intellix` database, the current version uses the `intellixv2` database.
  
This is an example of running the setup:

```bash
sudo ./setup/setup-intellix.sh \
    --license-file='~/Peters Engineering_Enterprise.lic' \
    --intellix-admin-user=intellix \
    --intellix-admin-password=ddj749Kdhg-ddj_3+498djk34dj30sLcsdfBbvKl \
    --intellix-db-user=intellix-sql \
    --intellix-db-password=In092DSjsDej4dsjdJdsd
```

Then you can run Intelligent Indexing:

```bash
sudo ./start-intellix.sh
```

### Examples

There are two example scripts `run-setup-example.sh` and
`run-setup-with-own-sqlserver-example.sh` provided. You can modify the scripts and use them
to run the setup and start the service when the setup is finished.

In order to get strong passwords, these scripts use a password generator to generate passwords
for the Web UI and the database user.
If you do not like to generate random passwords, just modify the examples
depending on your need.

- Simple Intelligent Indexing installation with license file:

  ```bash
  intellixAdminPassword=$(./random-password.sh)
  intellixDbPassword=$(./random-password.sh)
  
  sudo ./setup/setup-intellix.sh \
    --license-file='~/Peters Engineering_Enterprise.lic' \
    --intellix-admin-user=intellix \
    --intellix-admin-password=$intellixAdminPassword \
    --intellix-db-user=intellix-sql \
    --intellix-db-password=$intellixDbPassword
  echo "Intelligent Indexing Web UI user: intellix"
  echo "Intelligent Indexing Web UI password: $intellixAdminPassword"
  ```

- Installing Intelligent Indexing with your own SQL Server,
but without license file:

  ```bash
  intellixAdminPassword=$(./random-password.sh)
  intellixDbPassword=$(./random-password.sh)
  
  sudo ./setup/setup-intellix.sh \
    --license-file='~/Peters Engineering_Enterprise.lic' \
    --intellix-admin-user=intellix \
    --intellix-admin-password=$intellixAdminPassword \
    --intellix-db-user=intellix-sql \
    --intellix-db-password=$intellixDbPassword \
    --sql-server-instance=my-sql-2019-box \
    --sql-server-instance-user=sa \
    --sql-server-instance-password=Admin001
  
  echo "Intelligent Indexing Web UI user: intellix"
  echo "Intelligent Indexing Web UI password: $intellixAdminPassword"
  ```

## Management of Intelligent Indexing

### Configuration of Intelligent Indexing

The setup generates files, which are used by the containers to connect to the
database and to store the files and the index data for Apache Solr. The data
is stored at `/var/intellix`.

If you expect a high throughput for Intelligent Indexing, you should consider mounting
this directory on a fast storage.

### Starting Intelligent Indexing

To start Intelligent Indexing, run the following script:

```bash
sudo ./start-intellix.sh
```

### Testing the Components of Intelligent Indexing

You can use the following script to check which Docker containers are
currently running on the host computer:

```bash
docker ps -a
```

You should get one line each as output for the Docker containers whose names start with __intellix__.
In the `Status` column, you can see whether the Docker containers are running (`Up...`)
or have been ended (`Exited...`). You can also see in this column whether the containers
are accessible in principle. At startup, (`health: starting`) is displayed here.
If the containers respond successfully to requests, (`healthy`) is displayed.

A quick test shows if the service runs. The following request
should be responded with status code 200:

```bash
curl -I http://localhost/intellix-v2/
```

Also test here whether you can access the host computer via a browser from the computer on which
DocuWare is installed. From another computer, call up the URL
http://_computername_/intellix-v2/Html/, replacing _\_computername\__
with the name of the host computer.
You can log in with the user name and password you specified via the parameters
`--intellix-admin-user` and `--intellix-admin-password` in the setup.

### Logging

To view the live log of Intelligent Indexing, run:

```bash
sudo ./show-intellix-logs.sh
```

The output can be canceled by pressing `Ctrl+C`.

### Stopping Intelligent Indexing

To stop Intelligent Indexing, run:

```bash
sudo ./stop-intellix.sh
```

### Updating Intelligent Indexing

DocuWare is constantly improving Intelligent indexing. To apply the updates, it is enough to pull
updated images and restart the service.

Use the following script to check for and download any updates or hotfixes for Intelligent Indexing:

```bash
./update-intellix.sh
```

You can run this script while Intelligent Indexing is running. The changes will not take effect until you
run `stop-intellix.sh` and `start-intellix.sh` after this script is finished.
This services can be restarted immediately after the update if the `--with-restart` parameter is added:

```bash
../update-intellix.sh --with-restart
```

### Restarting the Host Computer

The Docker environment manages the running Intelligent Indexing containers. These are configured so that
Intelligent Indexing shuts down and automatically restarts when the host computer is rebooted. If
Intelligent Indexing was not running before the restart, it will not start after the restart.

## Licensing Intelligent Indexing

To use Intelligent Indexing, you must apply a license file to the service.
You can download the license file from the
[DocuWare Partner Portal](http://go.docuware.com/partnerportal-login).

If you have the file downloaded, we recommend to pass the file when
[configuring](#setup) Intelligent Indexing. Alternatively,
you can upload the file in the Intelligent Indexing Web UI at the _Licensing_ section.

## Connecting DocuWare with Intelligent Indexing

The setup generates a connection file for DocuWare. The installation directory
contains this file at `./setup/run/intelligent-indexing-connection.xml`.

This file contains the connection URL. In case your server is exposed with a different name
than the machine name, or you configured the IIS to use `https`, you should change this URL in this file.

You can now upload the Intelligent Indexing connection file to your DocuWare installation to establish
the connection with Intelligent Indexing. To do this, log in to DocuWare Administration and
navigate to `DocuWare System` → `Data Connections` → `Intelligent Indexing Service connections`.
If a connection is already entered here, you can open it, remove your organization
under _Organizations_, and click `Apply`. This disables the connection of your
DocuWare system to your old Intelligent Indexing system, but it can be reactivated
by adding the organization again. Then right-click `Intelligent Indexing Service connections`
on the left side and select `Install Intelligent Indexing Service file`.
In the dialog that opens, select the `intelligent-indexing-connection.xml`
file. Then click `Apply` and close the DocuWare Administration.

> :point_up: When you upload the configuration file in the DocuWare Configuration, you may receive an error message, saying Intelligent Indexing cannot be connected.
However, this message is misleading, and the connection is established. We fix this wrong message in a future version of DocuWare.
