function New-CloudAccessKey {
    [CmdletBinding(DefaultParameterSetName = 'attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string]
        $AccessKeyName,

        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [ValidateSet('AWS4_HMAC_SHA256', 'GOOG4_HMAC_SHA256')]
        [string]
        $AuthenticationMethod,
        
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string]
        $CloudAccessKeyId,

        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string]
        $CloudSecretAccessKey,

        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string]
        $ContractId,
        
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [int]
        $GroupID,
        
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [ValidateSet('ENHANCED_TLS', 'STANDARD_TLS')]
        [string]
        $SecurityNetwork,
        
        [Parameter(ParameterSetName = 'attributes')]
        [string]
        $AdditionalCDN,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'body')]
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
        $Path = "/cam/v1/access-keys"
        if ($PSCmdlet.ParameterSetName -eq 'attributes') {
            $Body = @{
                'accessKeyName'        = $AccessKeyName
                'authenticationMethod' = $AuthenticationMethod
                'credentials'          = @{
                    'cloudAccessKeyId'     = $CloudAccessKeyId
                    'cloudSecretAccessKey' = $CloudSecretAccessKey
                }
                'contractId'           = $ContractId
                'groupId'              = $GroupID
                'networkConfiguration' = @{
                    'securityNetwork' = $SecurityNetwork
                }
            }

            if ($AdditionalCDN) {
                $Body.networkConfiguration.additionalCdn = $AdditionalCDN
            }
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
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

