Function Get-AppVReportingConfig {
    <#
    .SYNOPSIS
        Get App-V Reporting module configuration.

    .DESCRIPTION
        Get App-V Reporting module configuration

    .FUNCTIONALITY
        App-V
    #>
    [cmdletbinding()]
    param()

    Import-Clixml -Path $PSScriptRoot\AppVReporting.xml

}