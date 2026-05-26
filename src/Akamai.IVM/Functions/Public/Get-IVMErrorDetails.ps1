function Get-IVMErrorDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,
        
        [Parameter()]
        [string]
        $PolicyID,

        [Parameter()] 
        [int] 
        $Limit,

        [Parameter()] 
        [string] 
        $Url,

        [Parameter()] 
        [int] 
        $Size,

        [Parameter()]
        [ValidateSet('REALTIME', 'OFFLINE')] 
        [string]
        $TransformationType,

        [Parameter()]
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network = 'Production',
        
        [Parameter()]
        [string]
        $ContractID,

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

    Process {
        $Network = $Network.ToLower()
        if ($TransformationType -ne '') {
            $TransformationType = $TransformationType.ToUpper()
        }
    
        $Path = "/imaging/v2/network/$Network/details/errors"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
    
        $QueryParameters = @{
            'limit'              = $PSBoundParameters.Limit
            'url'                = $PSBoundParameters.Url
            'size'               = $PSBoundParameters.Size
            'transformationtype' = $PSBoundParameters.TransformationType
            'policyid'           = $PSBoundParameters.policyId
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.items
    }
}
