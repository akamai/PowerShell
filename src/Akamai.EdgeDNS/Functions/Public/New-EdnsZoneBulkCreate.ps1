function New-EDNSZoneBulkCreate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ContractID,

        [Parameter()]
        [int] 
        $GroupID,

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
    
    process {
        $Method = 'POST'
        $Path = "/config-dns/v2/zones/create-requests"

        $QueryParameters = @{
            'contractId' = $ContractID
            'gid'        = $GroupID
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
