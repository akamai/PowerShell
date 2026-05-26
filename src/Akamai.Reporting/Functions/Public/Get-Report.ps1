function Get-Report {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Report,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $QueryID,

        [Parameter()]
        [string]
        $AccountSwitchKey,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report/queries/$QueryID"

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

        if ($Response.Status -eq 303) {
            Write-Warning "Reporting pending. Please try again in a few seconds."
            return
        }

        return $Response.Body
    }
}