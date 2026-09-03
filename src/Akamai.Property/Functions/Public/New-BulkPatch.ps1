function New-BulkPatch {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        $Body,

        [Parameter()]
        [string]
        $GroupId,

        [Parameter()]
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
        $Path = "/papi/v1/bulk/rules-patch-requests"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams

        # Extract bulk patch ID
        $BulkPatchID = $Response.Body.bulkPatchLink -split '\?' | Select-Object -First 1
        $BulkPatchID = $BulkPatchID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkPatchID -NotePropertyValue $BulkPatchID -Force

        return $Response.Body
    }
}
