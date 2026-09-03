function Get-ReportType {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Report,

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
        # Throw error for bad parameter combinations
        if ($Report -and -not ($ProductFamily -and $ReportingArea)) {
            throw "Report parameter requires ProductFamily and ReportingArea parameters."
        }
        if ($ReportingArea -and -not $ProductFamily) {
            throw "ReportingArea parameter requires ProductFamily parameter."
        }

        $Path = "/reporting-api/v2/reports"
        if ($ProductFamily) {
            $Path = "/reporting-api/v2/reports/$ProductFamily"
            if ($ReportingArea) {
                $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea"
                if ($Report) {
                    $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report"
                }
            }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        if ($Report) {
            return $Response.body
        }
        else {
            foreach ($ResponseReport in $Response.body.reports) {
                $LinkElements = $ResponseReport.reportLink -Split "/"
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "ProductFamily" -Value $LinkElements[4]
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "ReportingArea" -Value $LinkElements[5]
                $ResponseReport | Add-Member -MemberType NoteProperty -Name "Report" -Value $LinkElements[6]
            }
            return $Response.body.reports
        }
    }
}