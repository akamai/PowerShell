function New-BulkActivation {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
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
        $Path = "/papi/v1/bulk/activations"
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

        # Extract bulk activation ID
        $BulkActivationID = $Response.Body.bulkActivationLink -split '\?' | Select-Object -First 1
        $BulkActivationID = $BulkActivationID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkActivationID -NotePropertyValue $BulkActivationID -Force
        
        return $Response.Body
    }
}