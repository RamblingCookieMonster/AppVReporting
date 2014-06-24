Function Get-AppVUse {
    <#
    .SYNOPSIS
        Get App-V usage according to App-V reporting server.

    .DESCRIPTION
        Get App-V usage according to App-V reporting server.

        Notes:
            Computers must have the App-V Reporting configuration applied
            Computers report back once a day
            The account running this query must have access to the App-V Reporting Database

    .PARAMETER App_Name
        Filter on App_Name.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER Username
        Filter on Username.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER host_name
        Filter on host_name.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER package_guid
        Filter on package_guid.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER TOP
        Limits query to this many results

    .PARAMETER QueryOnly
        Build the T-SQL but do not invoke it.  Resulting object details:
            Query: T-SQL that would run if this command were executed
            Parameter:  SQL parameters passed in to the query

    .PARAMETER ServerInstance
        SQL Server Instance hosting the App-V database

    .PARAMETER DatabaseName
        Name of the App-V Reporting database

    .PARAMETER Credential
        PSCredential to pass to Invoke-SqlCmd2.  Note that this will only take SQL credentials, it will not take domain credentials.

    .EXAMPLE
        #View all App-V usage in a grid
        Get-AppVUse | Out-Gridview

    .EXAMPLE
        #View app-v usage by any username with doe in the name
        Get-AppVUse -username *doe*

    .FUNCTIONALITY
        App-V
    #>
    [cmdletbinding()]
    param(
        [parameter( Position=0,
                    ValueFromPipelineByPropertyName=$true)]
        [string]$App_Name,
        
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Username,

        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$host_name,

        [parameter(ValueFromPipelineByPropertyName=$true)]
        [switch]$package_guid,

        [int]$top,
        [System.Collections.Hashtable]$QueryTable = $null,
        [switch]$QueryOnly,
        [string]$ServerInstance = $APPVReportingConfig.ServerInstance,
        [string]$DatabaseName = $APPVReportingConfig.DatabaseName,
        [System.Management.Automation.PSCredential]$Credential
    )

    
    #Set up invoke sql cmd params
        if(-not $ServerInstance -or -not $DatabaseName)
        {
            Throw "ServerInstance '$ServerInstance' and DatabaseName '$DatabaseName' must be defined."
        }
        $invokeParams = @{
            ServerInstance = $ServerInstance
            Database = $DatabaseName
        }
        if($Credential)
        {
            $invokeParams.add('Credential',$Credential)
        }

    #Predefined parameters we can use.  Loop through these and add to querytable and sql paraemters if they don't exist already.
        function ql {$args}
        $shortcutParams = ql app_name username host_name package_guid #TOMODIFY

        Foreach($parm in $shortcutParams){
            $value = Get-Variable -Name $parm -ValueOnly
            if($value){

                #substitute * for % for SQL query
                $value = $value.replace("*","%")

                if($queryTable){

                    #If query table is bound and has $parm key, and user provided name key, there is a conflict.  Don't make assumptions, throw error
                    if($queryTable.ContainsKey($parm)){
                        Write-Error "Error:  $parm defined as parameter and as key in QueryTable.  Use one or the other"
                    }
                    #Otherwise, add $parm key to querytable
                    Else{
                        $queryTable.add($parm, $value)
                    }
                }
                else{
                    #QueryTable doesn't exist, create it, and add it to params (it isn't bound and won't be added below)
                    $queryTable = @{
                        $parm = $value
                    }
                }
            }
        }

    #Start building the query.  Any suggestions on improving this would be appreciated, not fluent in T-SQL
    $query = "
        SELECT $(if($top){" TOP $top "})
            ApplicationUsage.app_name
            ,ApplicationUsage.app_version
            ,PackageInformation.source
            ,ApplicationUsage.username
            ,ClientInformation.host_name
            ,ApplicationUsage.start_time
            ,ApplicationUsage.end_time
            ,ApplicationUsage.launch_status
            ,ApplicationUsage.server_name
            ,ApplicationUsage.connection_group_version_guid
            ,PackageInformation.package_name
            ,PackageInformation.package_version
            ,PackageInformation.package_guid
            ,PackageInformation.version_guid
            ,PackageInformation.percent_cached
            ,ClientInformation.version AS [appv_version]
            ,ClientInformation.processor_architecture
            ,ClientInformation.os_version
            ,ClientInformation.os_service_pack
            ,ClientInformation.os_type
        FROM
            ApplicationUsage
            INNER JOIN ClientInformation
                ON ApplicationUsage.host_id = ClientInformation.host_id
            INNER JOIN PackageInformation
                ON ApplicationUsage.host_id = PackageInformation.host_id AND ApplicationUsage.version_guid = PackageInformation.version_guid
    "

    #If we have any parameters to filter on, add them to the T-SQL and build up sql parameters
        if( ( $qt = Get-Variable -name QueryTable ) -and $qt.value -notlike $null )
        {
            $query += "WHERE"
            foreach($key in @( $queryTable.keys))
            {
                $query += " $key LIKE @$key"
            }
            $invokeParams.Add("SqlParameters",$queryTable)
        }

    #Give some verbose output
        Write-Verbose "`nQuery = `n$($query | out-string)"
        Write-Verbose "`nInvokeParams = `n$($invokeParams | out-string)"
        Write-Verbose "`nSQLParams = `n$($queryTable | out-string)"

    #Return the query details or execute the query
    if($queryOnly)
    {
        New-Object -TypeName PSObject -Property @{
            Query = $query
            Parameter = $queryTable
        } | Select Query, Parameter
    }
    else{
        #We exclude some standard properties that can get in the way.  Feel free to add them back in...
            Invoke-Sqlcmd2 @invokeParams -Query $query | select -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
    }

}