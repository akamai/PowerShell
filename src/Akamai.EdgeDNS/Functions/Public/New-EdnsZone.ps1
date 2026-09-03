function New-EDNSZone {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("PRIMARY", "SECONDARY", "ALIAS")]
        [string]
        $Type,

        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Comment,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $EndCustomerID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Masters,

        [Parameter(ParameterSetName = 'Attributes')]
        [bool]
        $SignAndServe,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet("RSA_SHA1", "RSA_SHA256", "RSA_SHA512", "ECDSA_P256_SHA256", "ECDSA_P384_SHA384")]
        [string]
        $SignAndServeAlgorithm,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Target,

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
        [int]
        $TSIGKeyZoneCount,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
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
        $Path = "/config-dns/v2/zones"

        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $PSBoundParameters.GroupID
        }

        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            $Body = @{
                'zone'                  = $Zone
                'type'                  = $Type
                'comment'               = $PSBoundParameters.Comment
                'signAndServe'          = $PSBoundParameters.SignAndServe
                'signAndServeAlgorithm' = $PSBoundParameters.SignAndServeAlgorithm
                'endCustomerId'         = $PSBoundParameters.EndCustomerID
                'target'                = $PSBoundParameters.Target
                'masters'               = $Masters
            }
        }

        if ($TSIGKeyName -or $TSIGKeyAlgorithm -or $TSIGKeySecret -or $TSIGKeyZoneCount) {
            $TSIGKey = @{
                'algorithm' = $PSBoundParameters.TSIGKeyAlgorithm
                'name'      = $PSBoundParameters.TSIGKeyName
                'secret'    = $PSBoundParameters.TSIGKeySecret
            }
            if ($PSBoundParameters.TSIGKeyZoneCount) {
                $TSIGKey['zonesCount'] = $PSBoundParameters.TSIGKeyZoneCount
            }
            $Body['tsigKey'] = $TSIGKey
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
