function New-EdgeDiagnosticsContentProblem {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RunFromSiteshield,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = 'Body')]
        $Body,

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
        $Path = "/edge-diagnostics/v1/content-problems"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($EdgeLocationID) { $Body['edgeLocationId'] = $EdgeLocationID }
            if ($IPVersion) { $Body['ipVersion'] = $IPVersion }
            if ($RequestHeaders) { $Body['requestHeaders'] = $RequestHeaders }
            if ($RunFromSiteshield) { $Body['runFromSiteShield'] = 'true' }
            if ($SensitiveRequestHeaderKeys) { $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys }
            if ($SpoofEdgeIP) { $Body['spoofEdgeIp'] = $SpoofEdgeIP }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
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

