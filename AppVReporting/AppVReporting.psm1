#Get public and private function definition files.
    $Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue 
    $Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue 

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname)"
        }
    }

#Read config
    Try
    {
        $APPVReportingConfig = $null
        $APPVReportingConfig = Get-AppvReportingConfig -ErrorAction Stop
    }
    Catch
    {
        Write-Warning "Error reading AppVReporting.xml: $_"
    }

#Give feedback on the config
    $VerboseString = "Current App-V Reporting Configuration: $($APPVReportingConfig | Format-List | Out-String)Use Set-AppVReportingConfig and Get-AppVReportingConfig as needed."
    Write-Verbose $VerboseString

    if(-not $_.ServerInstance -or -not $_.DatabaseName -or -not $APPVReportingConfig)
    {
        Write-Host $VerboseString
    }

#Only export public functions
    Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName) -Variable *