function New-EdgeDiagnosticsESIDebug {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $URL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ClientIP,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $ClientRequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $OriginServer,

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
        $Path = "/edge-diagnostics/v1/esi-debugger-api/v1/debug"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'url' = $URL
            }

            if ($ClientIP) { $Body['clientIp'] = $ClientIP }
            if ($ClientRequestHeaders) {
                $Body['clientRequestHeaders'] = @{}
                foreach ($Header in $ClientRequestHeaders) {
                    $SplitHeader = $Header.Split(":", 2)
                    if ($SplitHeader.Count -eq 2) {
                        $HeaderName = $SplitHeader[0].Trim()
                        $HeaderValue = $SplitHeader[1].Trim()
                        $Body['clientRequestHeaders'][$HeaderName] = $HeaderValue
                    }
                    else {
                        Write-Warning "Invalid header format: '$Header'. Expected format is 'Header-Name: Header Value'. Skipping this header."
                    }
                }
            }
            if ($OriginServer) { $Body['originServer'] = $OriginServer }
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

