# Intelligent Indexing On Premises Upgrader Manual

## Introduction
In this manual we discuss how to operate the migration from an Intelligent Indexing On Premises version 1 (IOPV1) system to an Intelligent Indexing On Premises version 2 (IOPV2) system. This Upgrader copies data from the IOPV1 to the IOPV2 system. No data is deleted. The old IOPV1 system is fully functional afterwards. To use the Upgrader the IOPV2 system has to be running and fully functional. If that is not the case, please follow the [IOPV2 installation manual](windows-setup.md).

### What happens if you do not upgrade?
If you do not upgrade, you will have a fully functional, but blank IOPV2 system. IOPV2 will give poor results for the first few documents of each template, e.g., of each sender but will improve fast after that.

You can also first start with a blank IOPV2 system to train the new system consistently. If you are not satisfied with the results after a few weeks you can still run the Upgrader then to copy data from the IOPV1 system.

### Process of Migration
The process of migrating your documents from IOPV1 to IOPV2 consists of the following steps:

* Prepare both systems IOPV1 and IOPV2 to be fully functional. This means that the related database server/s is/are also up and running. If you are already using IOPV2 for some time, you should update IOPV2 as described in its [installation manual](windows-setup.md).
* Download the Upgrader from [our GitHub repository](https://github.com/DocuWare/Intellix/upgrader.zip). Unzip the file to any location on a machine that can reach the IOPV1 and IOPV2 systems.
* Prepare the configuration file `IntellixUpgraderConfigurations.xml` with all relevant settings.
* Start the Upgrader. If there are errors during Upgrader operation, you should address them and rerun the Upgrader.

For the sake of performance, i.e., less time for the upgrade, you are advised to run the Upgrader on the same machine as your IOPV2 system is running. 

## Configuring the Upgrader
The Upgrader consists of the following files:

* `IntellixOnPremisesUpgrader.exe`: The Upgrader itself 
* `IntellixUpgraderConfigurations.xml`: The Upgrader configurations, which contains all required elements without values.
* `IntellixUpgraderConfigurationsExample.xml`: An example of a filled Upgrader configurations file



### Mandatory Configurations

The configuration file consists of the two main parts `IntellixOnPremisesV1` and `IntellixOnPremisesV2` which configure the connection of the Upgrader to IOPV1 and IOPV2, respectively.

Both parts contain configuration values for `URI`, `Username` and `Password`. We advise you to check if you can login to IOPV1 and IOPV2 using the respective URI, user name and password with a browser running on the machine the Upgrader will be running on.

For the configuration of IOPV1 there are three additional mandatory values:

* `ModelspaceName`: The name of the modelspace in IOPV1 from which you want to transfer documents to IOPV2. You can check the modelspaces you have by browsing your IOPV1 system.
* `DBName`: The name of the database in IOPV1
* `DBConnectionString`: The connection string to the IOPV1 database server

### Optional Configurations

#### Name of IOPV2 Modelspace

With the setting `ModelspaceName` in `IntellixOnPremisesV2` you can specify the name of the target modelspace in the IOPV2 system where the documents from IOPV1 will be transferred to. If you do not provide this option the default modelspace in IOPV2 is chosen. An empty modelspace will be created if no modelspace with the given name exists.

The configuration is done in the same way as for the desired IOPV1 modelspace name. For example, if you have a modelspace with name `MyPrimaryIOPV2Modelspace` in your IOPV2 system, you should configure it as follows:

```text
<IntellixUpgraderConfigurations>
  ...
  <IntellixOnPremisesV2>
    ...
    <ModelspaceName> MyPrimaryIOPV2Modelspace </ModelspaceName>
  </IntellixOnPremisesV2>
</IntellixUpgraderConfigurations>
```

#### Number of Documents to Transfer
 With the setting `MaximalDesiredAmountOfDocumentsToTransfer` you can specify the the amount of documents to transfer from IOPV1 to IOPV2. The default is 50000 documents. The minimal value you can provide is 500. Lower values than 500 are ignored.
 
 This is only a desired amount of documents to transfer, since there may be fewer documents in the IOPV1 system or a few of the transfers may fail (for various reasons). One should keep in mind that transferring a larger number of documents may increase the time for the upgrade significantly (hours).

Example scenario when you may want to use this option: Your company overall stores ≈ 5000 documents per day. There are documents that occur monthly into the system. In order to encompass one month you should transfer ≈ 150000 documents. Here is an example on how to use the property in this scenario:

```text
<IntellixUpgraderConfigurations>
  ···
  <MaximalDesiredAmountOfDocumentsToTransfer> 150000 </MaximalDesiredAmountOfDocumentsToTransfer>
</IntellixUpgraderConfigurations>
```

#### Percentage of Failed Documents
The last optional configuration is `MaximalPercentageOfFailedDocuments`. By default it has the value 2%. It means that if the Upgrader does 50000 transfers and less than 1000 documents fail to transfer, then we consider this a normal operation and success. This is required since documents may fail to transfer for various reasons, e.g., the database record for the document is corrupted, IOPV2 fails to process some request on time (timeout), the internet may stop for a minute (timeout), etc. If several documents fail this is not an issue, since it is not important that every single document is transfered - even 3 samples of each document type (e.g., invoice) would be enough. Therefore if you provide a value lower than 2% it will be ignored. Only integer values are accepted.

If fewer than 500 documents have to be transferred, e.g., you have only 50 left in the IOPV1 that were not transferred, this configuration is ignored and any number of failures is accepted. For instance if you have 50 documents left and 5 fail to transfer, this is 10%, i.e., the tolerated percentage must be higher when low amounts of documents are transferred.

Example scenario when you may want to use this option: You know that 15000 IOPV1 documents got accidentally deleted from the hard disk two weeks ago. Therefore, there are 15000 records in the database that point to documents missing from the file system - all of these transfers will fail. You have run the Upgrader once and you have seen that too many failures occur. You want to transfer 50000 documents (the default, as we recommend) allowing that 16000 will fail, 1000 failures reserved for other reasons than the one above. This is 36% possible failure rate. Then you would use the configuration:

```text
<IntellixUpgraderConfigurations>
  ···
  <MaximalPercentageOfFailedDocuments> 36 </MaximalPercentageOfFailedDocuments>
</IntellixUpgraderConfigurations>
```

## Executing the Upgrader
After you are ready preparing the `IntellixUpgraderConfigurations.xml` file you can run the `IntellixOnPremisesUpgrader.exe` file. The Upgrader is a console application, no user interaction is needed (One exception: if you choose a name for IOPV2 modelspace that do not exist, we warn you and require confirmation to continue, in order to avoid misspellings of a desired existing IOPV2 modelspace's name), you just have to read the output text of the console application as it progresses.

By design the Upgrader fixes the console size to the maximum screen size and disables the Quick Edit Mode functionality, these are the optimal conditions for good performance and readability. If it is unable to setup these settings you will see corresponding warning messages. In these cases you could also do these steps - just maximize the console window and disable quick edit mode from CMD settings.

After the Upgrader finishes successfully it creates a file `IntellixUpgraderExecutionData.txt`. __Do not delete this file!__ It contains the date of creation for the last transferred training document. In case you run the Upgrader again this file is used in order to continue transferring documents. We present an example scenario when you might want to do this. The Upgrader transferred the default amount of 50000 documents successfully with a few failures. On the next day the users start to work with IOPV2 and they complain that they do not receive intellix suggestions
or the accuracy is not as good as before. You could therefore run the Upgrader once more in order to transfer another batch of 50000 documents.

If you want to benefit further from the Upgrader try to transfer as few documents as possible. This way you will get rid of old documents that serve no purpose but take GBs on your hard drives.

### Handling errors
Please read all error output and take action. Typical errors are missing required fields (e.g. Username for the IOPV1 system) or typos in the values. Check again that IOPV1 and IOPV2 are accessible with the provided values using a browser from the machine you are running the Upgrader on.

It might be helpful to take a screenshot of the Upgrader output
if you observe errors or confusing output!

## Testing the Migration
In general, if you see that the Upgrader reports that the upgrade is successful this should be correct. Therefore, what we discuss below is optional but recommended.

In order to test if the Upgrader really transferred your documents you should look up your IOPV2 system. Log in and check your default modelspace, you should find many new documents there which were transferred from your IOPV1 system. Notice that the creation date of these new documents should be the date on which you ran the Upgrader.

In the UI of the IOPV2 system you can see only the newest 10000 documents. A proficient user could also inspect if the IOPV2 database contains the expected amount of training documents after the upgrade. If you want to do this look up the amount of records in the `TrainingDocuments` table from the IOPV2 database.
