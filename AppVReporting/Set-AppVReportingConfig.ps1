Function Set-AppVReportingConfig {
    <#
    .SYNOPSIS
        Set App-V Reporting module configuration.

    .DESCRIPTION
        Set App-V Reporting module configuration

    .PARAMETER ServerInstance
        Set the default App-V Reporting SQL Server Instance to use
    
    .PARAMETER DatabaseName
        Set the default App-V Reporting Database Name to use
    
    .Example
        Set-AppVReportingConfig -ServerInstance AppVDBServer -DatabaseName AppVReporting

    .Example
        Set-AppVReportingConfig -ServerInstance SomeOtherDBServer

    .FUNCTIONALITY
        App-V
    #>
    [cmdletbinding()]
    param(
        [string]$ServerInstance,
        [string]$DatabaseName
    )

    Try
    {
        $Existing = Get-AppVReportingConfig -ErrorAction stop
    }
    Catch
    {
        Throw "Error getting App-V Reporting config: $_"
    }

    if($ServerInstance)
    {
        $Existing.ServerInstance = $ServerInstance
    }
    If($DatabaseName)
    {
        $Existing.DatabaseName = $DatabaseName
    }

    $Existing | Export-Clixml -Path $PSScriptRoot\AppVReporting.xml -force

}