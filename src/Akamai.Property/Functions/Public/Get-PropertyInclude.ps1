function Get-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one by name', Position = 0, Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Get one by ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $IncludeID,

        [Parameter(ParameterSetName = 'Get one by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one by name', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get one by ID', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get all', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('contractIds')]
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
        $IncludeID, $null, $GroupID, $ContractID = Expand-PropertyIncludeDetails @PSBoundParameters
        if ($IncludeID) {
            $Path = "/papi/v1/includes/$IncludeID"
        }
        else {
            $Path = "/papi/v1/includes"
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
            if ($AkamaiOptions.EnableDataCache) {
                foreach ($Include in $Response.Body.includes.items) {
                    Set-AkamaiDataCache -IncludeName $Include.includeName -IncludeID $Include.includeId
                }
            }
    
            return $Response.Body.includes.items
        }
        catch {
            throw $_
        }
    }
}
