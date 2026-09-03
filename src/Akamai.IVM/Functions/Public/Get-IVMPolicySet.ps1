
function Get-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
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
        if ($PolicySetID) {
            $Path = "/imaging/v2/policysets/$PolicySetID"
        }
        else {
            $Path = "/imaging/v2/policysets"
        }
    
        if ($ContractID -ne '') {
            $AdditionalHeaders = @{'Contract' = $ContractID }
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
        return $Response.Body
    }
}
