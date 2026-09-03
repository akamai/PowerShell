function Set-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]  
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

        [Parameter(Mandatory, ValueFromPipeline)]
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

    Process {
        $Network = $Network.ToLower()
        $Path = "/imaging/v2/network/$Network/policies/$PolicyID"
        $AdditionalHeaders = @{ 'Policy-Set' = $PolicySetID }

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
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
