function Get-PropertyCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $CPCodeID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        if ($CPCodeID) {
            $Path = "/papi/v1/cpcodes/$CPCodeID"
        }
        else {
            $Path = "/papi/v1/cpcodes"
        }
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.cpcodes.items
    }
}
