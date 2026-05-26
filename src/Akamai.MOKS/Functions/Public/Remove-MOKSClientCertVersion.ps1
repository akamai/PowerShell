
function Remove-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [int]
        $CertificateID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|deployed|[0-9]+)$')]
        [string]
        $Version,

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
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions/$Version"

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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
