
function New-EDNSProxyZone {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('NONE', 'ALL', 'MANUAL', 'AUTOMATIC')]
        [string]
        $FilterMode,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $ApexAlias,

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

    begin {
        $CollatedProxyZones = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Body') {
            if ($Body -isnot 'String' -and $Body -isnot 'Array') {
                $CollatedProxyZones.Add($Body)
            }
        }
    }

    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/create-requests"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'proxyZones' = @(
                    @{
                        'name'       = $Name
                        'filterMode' = $FilterMode
                    }
                )
            }
            if ($FilterMode -eq 'AUTOMATIC') {
                $Body.proxyZones[0].tsigKey = @{
                    'algorith' = $TSIGKeyAlgorithm
                    'name'     = $TSIGKeyName
                    'secret'   = $TSIGKeySecret
                }
            }

            if ($ApexAlias) {
                $Body.proxyZones[0].apexAlias = $ApexAlias
            }
        }
        else {
            if ($CollatedProxyZones.count -gt 1) {
                $Body = $CollatedProxyZones
            }
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
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
