function Get-ReportingArea {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    process {
        $CommonParams = @{
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        $Reports = Get-ReportType @CommonParams
        return $Reports.ReportingArea | Sort-Object -Unique
    }
}