function New-EdgeDiagnosticsCurl {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $URL,

        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $EdgeLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $SpoofEdgeIP,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $RunFromSiteshield,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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
        $Path = "/edge-diagnostics/v1/curl"

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                url       = $URL
                ipVersion = $IPVersion
            }

            if ($EdgeIP) {
                $Body['edgeIp'] = $EdgeIP
            }

            if ($EdgeLocationID) {
                $Body['edgeLocationId'] = $EdgeLocationID
            }

            if ($SpoofEdgeIP) {
                $Body['spoofEdgeIP'] = $SpoofEdgeIP
            }

            if ($RequestHeaders) {
                $Body['requestHeaders'] = $RequestHeaders
            }

            if ($RunFromSiteshield) {
                $Body['runFromSiteshield'] = $true
            }
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

