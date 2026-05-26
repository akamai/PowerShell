function Remove-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,

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
        $Path = "/imaging/v2/policysets/$PolicySetID"
        $AdditionalHeaders = @{}
    
        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'DELETE'
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
