function Set-IVMPolicySet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]  
        [string] 
        $PolicySetID,
        
        [Parameter()] 
        [string] 
        $Name,

        [Parameter()] 
        [ValidateSet('US', 'EMEA', 'ASIA', 'AUSTRALIA', 'JAPAN', 'CHINA')] 
        [string] 
        $Region,

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
        if ($ContractID -ne '') {
            $AdditionalHeaders = @{ 'Contract' = $ContractID }
        }
    
        $Body = @{}
        if ($Name) { $Body.name = $Name }
        if ($Region) { $Body.region = $Region }
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
