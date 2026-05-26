function Set-ChinaCDNDeprovisionPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeHostname,

        [Parameter(ParameterSetName = 'Attributes')]
        [bool]
        $UnmapSharedEdgeHostname,

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

    begin {}

    process {
        $Path = "/chinacdn/v1/edge-hostnames/$EdgeHostname/deprovision-policy"
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.deprovision-policy.v1+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'unmapSharedEdgeHostname' = $UnmapSharedEdgeHostname
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}
}

