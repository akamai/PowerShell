
function New-MOKSClientCert {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $CertificateName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('CORE', 'RUSSIAN_AND_CORE', 'CHINA_AND_CORE')]
        [string]
        $Geography = 'CORE',

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('STANDARD_TLS', 'ENHANCED_TLS')]
        [string]
        $SecureNetwork,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('AKAMAI', 'THIRD_PARTY')]
        [string]
        $Signer,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $NotificationEmails,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $PreferredCA,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('RSA', 'ECDSA')]
        [string]
        $KeyAlgorithm,

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

    process {
        $Path = "/mtls-origin-keystore/v1/client-certificates"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'certificateName'    = $CertificateName
                'contractId'         = $ContractID
                'groupId'            = $GroupID
                'geography'          = $Geography
                'notificationEmails' = ($NotificationEmails.Replace(' ', '') -split ',')
                'secureNetwork'      = $SecureNetwork
                'signer'             = $Signer
            }
            if ($PreferredCA) { $Body.preferredCa = $PreferredCA }
            if ($KeyAlgorithm) { $Body.keyAlgorithm = $KeyAlgorithm }
            if ($Subject) { $Body.subject = $Subject }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
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
                Set-AkamaiDataCache -MOKSClientCertName $Response.Body.certificateName -MOKSClientCertID $Response.Body.certificateId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
