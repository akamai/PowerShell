function Get-IVMPolicy {
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
        if ($PolicyID) {
            $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        }
        else {
            $Path = "/imaging/v2/network/$Network/policies"
        }
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
        if ($PolicyID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
