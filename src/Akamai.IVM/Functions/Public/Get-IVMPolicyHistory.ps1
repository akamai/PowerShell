function Get-IVMPolicyHistory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory)]
        [string]
        $PolicyID,

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
        $Path = "/imaging/v2/network/$Network/policies/history/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
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
