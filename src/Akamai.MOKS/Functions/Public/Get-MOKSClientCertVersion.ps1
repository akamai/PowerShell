
function Get-MOKSClientCertVersion {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    Param(
        [Parameter(ParameterSetName = 'name', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CertificateID,

        [Parameter()]
        [switch]
        $IncludeAssociatedProperties,

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
        $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID/versions"
        $QueryParameters = @{
            'includeAssociatedProperties' = $PSBoundParameters.IncludeAssociatedProperties.IsPresent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.versions
    }
}