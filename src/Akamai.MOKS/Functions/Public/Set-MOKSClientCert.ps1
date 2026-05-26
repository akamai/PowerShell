
function Set-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $CertificateName,

        [Parameter(ParameterSetName = 'ID &attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CertificateID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID &attributes', Mandatory)]
        [string]
        $NewName,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID &attributes', Mandatory)]
        [string]
        $NotificationEmails,

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
        $CertificateID, $null = Expand-MOKSClientCertDetails @PSBoundParameters
        $Path = "/mtls-origin-keystore/v1/client-certificates/$CertificateID"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'certificateName'    = $NewName
                'notificationEmails' = ($NotificationEmails.Replace(' ', '') -split ',')
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'Body'             = $Body
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
