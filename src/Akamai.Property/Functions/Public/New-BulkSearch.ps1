function New-BulkSearch {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Position = 0, Mandatory)]
        [string]
        $Match,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $BulkSearchQualifier,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [switch]
        $Synchronous,

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
        if ($Synchronous) {
            $Path = "/papi/v1/bulk/rules-search-requests-synch"
        }
        else {
            $Path = "/papi/v1/bulk/rules-search-requests"
        }
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $BulkSearchQuery = @{
                'syntax' = 'JSONPATH'
                'match'  = $Match
            }
            if ($BulkSearchQualifier) {
                $BulkSearchQuery['bulkSearchQualifiers'] = @($BulkSearchQualifier)
            }
            $Body = @{'bulkSearchQuery' = $BulkSearchQuery }
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

        # Extract bulk search ID for async requests
        if (-not $Synchronous) {
            $BulkSearchID = $Response.Body.bulkSearchLink -split '\?' | Select-Object -First 1
            $BulkSearchID = $BulkSearchID -split '/' | Select-Object -Last 1
            $Response.Body | Add-Member -NotePropertyName BulkSearchID -NotePropertyValue $BulkSearchID -Force
        }

        return $Response.Body
    }
}

