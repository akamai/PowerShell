function Restore-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string] 
        $PolicySetID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicyID,

        [Parameter(Mandatory)]  
        [ValidateSet('Staging', 'Production')] 
        [string] 
        $Network,

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
        $Path = "/imaging/v2/network/$Network/policies/rollback/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
