Function Get-AppVClient {
    <#
    .SYNOPSIS
        Get App-V client details according to App-V reporting server.

    .DESCRIPTION
        Get App-V client details according to App-V reporting server.

        Notes:
            Computers must have the App-V Reporting configuration applied
            Computers report back once a day
            The account running this query must have access to the App-V Reporting Database

    .PARAMETER host_name
        Filter on host_name.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER version
        Filter on version.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER os_type
        Filter on os_type.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER TOP
        Limits query to this many results

    .PARAMETER QueryOnly
        Build the T-SQL but do not invoke it.  Resulting object details:
            Query: T-SQL that would run if this command were executed
            Parameter: SQL parameters passed in to the query

    .PARAMETER ServerInstance
        SQL Server Instance hosting the App-V database

    .PARAMETER DatabaseName
        Name of the App-V Reporting database

    .PARAMETER Credential
        PSCredential to pass to Invoke-SqlCmd2.  Note that this will only take SQL credentials, it will not take domain credentials.

    .EXAMPLE
        #View all App-V clients in a grid
        Get-AppVClient | Out-Gridview

    .EXAMPLE
        #View app-v clients at version 5.0.3361.0
        Get-AppVClient -Version 5.0.3361.0

    .FUNCTIONALITY
        App-V
    #>
    [cmdletbinding()]
    param(
        [parameter( Position=0,
                    ValueFromPipelineByPropertyName=$true)]
        [string]$host_name,
        
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$version,
        
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$os_type,

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
        $shortcutParams = ql host_name version os_type #TOMODIFY

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
        SELECT $(if($top){" TOP $top "}) *
        FROM ClientInformation
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