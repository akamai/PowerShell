
function Convert-EDNSZoneToSecondary {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $Zone,

        [Parameter(Mandatory)]
        [string[]]
        $Masters,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Secure transfer', Mandatory)]
        [string]
        $TSIGKeySecret,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[object]
    }

    process {
        # Handle option to provide just names, or both name and soaSerialLock object
        $Zone | Foreach-Object {
            if ($_ -is 'String') {
                $CollatedZones.Add(
                    @{
                        'name' = $_
                    }
                )
            }
            else {
                $CollatedZones.Add($_)
            }
        }
    }

    end {
        $Path = "/config-dns/v2/zones/convert-requests/secondary"
        $Body = @{
            'masters'  = $Masters
            'zoneList' = $CollatedZones
        }
        if ($TSIGKeyName) {
            $Body.tsigKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
        }
        if ($Comment) {
            $Body.comment = $Comment
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
