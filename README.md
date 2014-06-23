AppVReporting
=============

This is a PowerShell module to simplify extracting data from the App-V reporting database.

At the moment, you can pull details on App-V clients, packages, and usage.  Usage data includes data with inner joins.

Get client version counts:
  ![Get client version counts](/Media/AppVClient.png)

Get details on App-V usage:
  ![Get App-V usage](/Media/AppVuse.png)

Find packages by location:
  ![Get App-V package](/Media/AppVPackage.png)

#Prerequisites
    
* Environment configured to send data to an App-V reporting server
* The account running this query must have access to read the App-V Reporting Database (PackageInformation, ClientInformation, ApplicationUsage tables)
  * Will add SQL credential support shortly, low priority in my case

#Instructions

    #One time setup:
        #Download the repository
        #Unblock the zip file
        #Extract AppVReporting folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)
        
    #Each PowerShell session
        Import-Module AppVReporting  #Alternatively, Import-Module "\\Path\To\AppVReporting"
        
    #List commands in the module
        Get-Command -Module AppVReporting
        
    #Get help for a command
        Get-Help Get-AppVUse -Full
        
    #Optional one time step: Set default reporting server SQL instance and database name
        Set-AppVReportingConfig -ServerInstance SomeSQLInstance -DatabaseName AppVReporting
 
    #View app-v packages stored on \\server\share\stream\*
        Get-AppVPackage -source \\server\share\stream\*
        
    #View app-v clients at version 5.0.3361.0
        Get-AppVClient -Version 5.0.3361.0
    
    #View all App-V usage in a grid
        Get-AppVUse | Out-Gridview
        