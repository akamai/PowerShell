function Set-EDNSTSIGKey {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("hmac-md5", "hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384", "hmac-sha512", "HMAC-MD5.SIG-ALG.REG.INT")]
        [Alias("algorithm")]
        [string]
        $TSIGKeyAlgorithm,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [Alias("name")]
        [string]
        $TSIGKeyName,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [Alias("secret")]
        [string]
        $TSIGKeySecret,

        [Parameter(ParameterSetName = 'Attributes', DontShow)]
        [int]
        $TSIGKeyZoneCount,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string[]]
        $Zone,

        [Parameter(ParameterSetName = 'Body', ValueFromPipeline, Mandatory)]
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
        $Method = 'POST'
        $Path = "/config-dns/v2/keys/bulk-update"

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $TSIGKey = @{
                'algorithm' = $TSIGKeyAlgorithm
                'name'      = $TSIGKeyName
                'secret'    = $TSIGKeySecret
            }
            if ($PSBoundParameters.TSIGKeyZoneCount) {
                $TSIGKey['zonesCount'] = $PSBoundParameters.TSIGKeyZoneCount
            }
            $Body = @{
                'zones' = $Zone
                'key'   = $TSIGKey
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
