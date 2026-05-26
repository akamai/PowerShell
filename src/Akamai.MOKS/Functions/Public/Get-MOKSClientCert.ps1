
function Get-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets__')]
    Param(
        [Parameter(ParameterSetName = 'Name')]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline)]
        [int]
        $CertificateID,

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
        if ($PSCmdlet.ParameterSetName -eq 'Name' -or $PSCmdlet.ParameterSetName -eq 'ID') {
            $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
            $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID"
        }
        else {
            $Path = "/mtls-origin-keystore/v1/client-certificates"
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                if ($CertificateID) {
                    Set-AkamaiDataCache -MOKSClientCertName $Response.Body.certificateName -MOKSClientCertID $Response.Body.certificateId
                }
                else {
                    foreach ($ClientCert in $Response.Body.certificates) {
                        Set-AkamaiDataCache -MOKSClientCertName $ClientCert.certificateName -MOKSClientCertID $ClientCert.certificateId
                    }
                }
            }

            if ($CertificateID) {
                return $Response.Body
            }
            else {
                return $Response.Body.certificates
            }
        }
        catch {
            throw $_
        }
    }
}
