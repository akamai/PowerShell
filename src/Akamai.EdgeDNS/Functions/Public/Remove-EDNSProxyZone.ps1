
function Remove-EDNSProxyZone {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter()]
        [switch]
        $BypassSafetyChecks,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string[]]
        $ProxyZones,

        [Parameter()]
        [string]
        $Comment,

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

    begin {
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($ProxyZones.count -gt 1) {
            $CollatedProxyZones.AddRange($ProxyZones)
        }
        else {
            $CollatedProxyZones.Add($ProxyZones)
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/delete-requests"
        $QueryParameters = @{ 
            'bypassSafetyChecks' = $PSBoundParameters.BypassSafetyChecks.IsPresent
        }
        $Body = @{
            'proxyZones' = $CollatedProxyZones
        }
        if ($Comment) {
            $Body.comment = $Comment
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters 
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}
