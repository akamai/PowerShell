
function Complete-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'Name & file')]
    Param(
        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'Name & body')]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID & file')]
        [Parameter(ParameterSetName = 'ID & body')]
        [int]
        $CertificateID,

        [Parameter(Mandatory)]
        [ValidatePattern('^(latest|deployed|[0-9]+)$')]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $AcknowledgeAllWarnings,

        [Parameter(Mandatory, ParameterSetName = 'Name & file')]
        [Parameter(Mandatory, ParameterSetName = 'ID & file')]
        [string]
        $CertificateFile,

        [Parameter(ParameterSetName = 'Name & file')]
        [Parameter(ParameterSetName = 'ID & file')]
        [string]
        $TrustChainFile,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name & body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ID & body')]
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
        $CertificateID, $Version = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions/$Version/certificate-block"
        $QueryParameters = @{
            'acknowledgeAllWarnings' = $PSBoundParameters.AcknowledgeAllWarnings.IsPresent
        }
        if ($PSCmdlet.ParameterSetName.Contains('file')) {
            if (-not (Test-Path $CertificateFile)) {
                throw "Certificate file '$CertificateFile' not found."
            }
            $CertData = Get-Content -Raw $CertificateFile
            $Body = @{
                'certificate' = $CertData
            }
            if ($TrustChainFile) {
                if (-not (Test-Path $TrustChainFile)) {
                    throw "Trust chain file '$TrustChainFile' not found."
                }
                $TrustData = Get-Content -Raw $TrustChainFile
                $Body.trustChain = $TrustData
            }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters
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
