function Get-Property {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one by name')]
        [Parameter(ParameterSetName = 'Get one by ID')]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('contractIds')]
        [object]
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
        if ($ContractId -is [Array]) {
            $ContractId = $ContractId[0]  # Only one is expected, even though it is an array, so take the first one
        }

        if ($PSCmdlet.ParameterSetName.Contains('one')) {
            $PropertyID, $null, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        }

        if ($PropertyID) {
            $Path = "/papi/v1/properties/$PropertyID"
        }
        else {
            $Path = "/papi/v1/properties"
        }
        $QueryParameters = @{
            contractId = $ContractId
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
    
            # Add to data cache
            if ($Response.Body.properties.items -and $AkamaiOptions.EnableDataCache) {
                foreach ($Property in $Response.Body.properties.items) {
                    Set-AkamaiDataCache -PropertyName $Property.propertyName -PropertyID $Property.propertyId
                }
            }
    
            return $Response.Body.properties.items
        }
        catch {
            throw $_
        }
    }
}
