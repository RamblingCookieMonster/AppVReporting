Function Get-AppVPackage {
    <#
    .SYNOPSIS
        Get App-V package details according to App-V reporting server.

    .DESCRIPTION
        Get App-V package details according to App-V reporting server.

        Notes:
            Computers must have the App-V Reporting configuration applied
            Computers report back once a day
            The account running this query must have access to the App-V Reporting Database

    .PARAMETER package_name
        Filter on package_name.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER package_guid
        Filter on package_guid.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER version_guid
        Filter on version_guid.  Accepts wildcards.  Use * or % as wildcard.

    .PARAMETER source
        Filter on source.  Accepts wildcards.  Use * or % as wildcard.

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

    .EXAMPLE
        #View all App-V packages in a grid
        Get-AppVPackage | Out-Gridview

    .EXAMPLE
        #View app-v packages stored on \\server\share\stream\*
        Get-AppVPackage -source \\server\share\stream\*

    .FUNCTIONALITY
        App-V
    #>
    [cmdletbinding()]
    param(
        [parameter( Position=0,
                    ValueFromPipelineByPropertyName=$true)]
        [string]$package_name,
        
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$package_guid,
        
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$version_guid,

        [parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$source,

        [int]$top,
        [System.Collections.Hashtable]$QueryTable = $null,
        [switch]$QueryOnly,
        [string]$ServerInstance = $APPVReportingConfig.ServerInstance,
        [string]$DatabaseName = $APPVReportingConfig.DatabaseName
    )

    
    #Set up invoke sql cmd params
        $invokeParams = @{
            ServerInstance = $ServerInstance
            Database = $DatabaseName
        }

    #Predefined parameters we can use.  Loop through these and add to querytable and sql paraemters if they don't exist already.
        function ql {$args}
        $shortcutParams = ql package_name package_guid version_guid source #TOMODIFY

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
        FROM PackageInformation
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