function New-IVMPolicy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]  
        [string] 
        $PolicySetID,
        
        [Parameter(Mandatory)]
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

    Begin {
        try {
            $ExistingPolicy = Get-IVMPolicy -PolicySetID $PolicySetID -PolicyID $PolicyID -Network $Network -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        }
        catch {}
        
        if ($ExistingPolicy) {
            throw "Policy $PolicyID already exists in Policy Set $PolicySetID"
        }
    }

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

    End {}
}
