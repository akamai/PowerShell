function Get-LegacyReportTypeVersions {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [switch]
        $ShowDeprecated,

        [Parameter()]
        [switch]
        $ShowUnavailable,

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
        $Path = "/reporting-api/v1/reports/$Name/versions"
        $QueryParameters = @{
            'showDeprecated'  = $PSBoundParameters.ShowDeprecated
            'showUnavailable' = $PSBoundParameters.ShowUnavailable
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}