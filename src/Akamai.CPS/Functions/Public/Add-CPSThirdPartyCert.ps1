function Add-CPSThirdPartyCert {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory)]
        [int]
        $EnrollmentID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $ChangeID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Certificate,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TrustChain,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet('RSA', 'ECDSA')]
        [string]
        $KeyAlgorithm,

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
        $Path = "/cps/v2/enrollments/$EnrollmentID/changes/$ChangeID/input/update/third-party-cert-and-trust-chain"
        $AdditionalHeaders = @{
            'accept'       = 'application/vnd.akamai.cps.change-id.v1+json'
            'content-type' = 'application/vnd.akamai.cps.certificate-and-trust-chain.v2+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'certificatesAndTrustChains' = @(
                    @{
                        'certificate'  = $Certificate
                        'keyAlgorithm' = $KeyAlgorithm
                    }
                )
            }

            if ($TrustChain) {
                $Body.certificatesAndTrustChains[0]['trustChain'] = $TrustChain
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body | Format-CPSResponse
    }
}
