function Get-LegacyReportType {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Get one')]
        [String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Get one')]
        [String]
        $Version,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $ShowDeprecated,

        [Parameter(ParameterSetName = 'All')]
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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/reporting-api/v1/reports/$Name/versions/$Version"
        }
        else {
            $Path = "/reporting-api/v1/reports"
            $QueryParameters = @{
                'showDeprecated'  = $PSBoundParameters.ShowDeprecated
                'showUnavailable' = $PSBoundParameters.ShowUnavailable
            }
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