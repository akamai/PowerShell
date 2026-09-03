function New-EdgeDiagnosticsMetadataTrace {
    [CmdletBinding(DefaultParameterSetName = 'IP & attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'IP & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Location & attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [ValidateSet('HEAD', 'POST', 'GET')]
        [string]
        $HTTPMethod,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [string]
        $EdgeIP,

        [Parameter(ParameterSetName = 'Location & attributes')]
        [string]
        $MDTLocationID,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [string[]]
        $SensitiveRequestHeaderKeys,

        [Parameter(ParameterSetName = 'IP & attributes')]
        [Parameter(ParameterSetName = 'Location & attributes')]
        [switch]
        $UseStaging,

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
        $Path = "/edge-diagnostics/v1/metadata-tracer"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'url'        = $URL
                'useStaging' = $UseStaging.IsPresent
            }

            if ($HTTPMethod) { $Body['httpMethod'] = $HTTPMethod }
            if ($EdgeIP) { $Body['edgeIp'] = $EdgeIP }
            if ($MDTLocationID) { $Body['mdtLocationId'] = $MDTLocationID }
            if ($RequestHeaders) {
                $Body['requestHeaders'] = $RequestHeaders
            }
            if ($SensitiveRequestHeaderKeys) {
                $Body['sensitiveRequestHeaderKeys'] = $SensitiveRequestHeaderKeys
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
