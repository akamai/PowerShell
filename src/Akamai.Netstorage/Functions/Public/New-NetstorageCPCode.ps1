function New-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $CPCodeName,
        
        [Parameter(Mandatory)]
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

    process {
        $Path = "/storage/v1/cpcodes"
        $Body = @{
            'contractId' = $ContractID
            'cpcodeName' = $CPCodeName
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}
