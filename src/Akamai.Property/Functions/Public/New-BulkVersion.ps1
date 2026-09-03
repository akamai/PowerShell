function New-BulkVersion {
    [CmdletBinding(DefaultParameterSetName = 'pipeline')]
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
        $Path = "/papi/v1/bulk/property-version-creations"
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

        # Extract bulk version ID
        $BulkCreateID = $Response.Body.bulkCreateVersionLink -split '\?' | Select-Object -First 1
        $BulkCreateID = $BulkCreateID -split '/' | Select-Object -Last 1
        $Response.Body | Add-Member -NotePropertyName BulkCreateID -NotePropertyValue $BulkCreateID -Force

        return $Response.Body
    }
}