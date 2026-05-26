function Get-APIEndpoint {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    [Alias('Get-APIEndpoints')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [string]
        $APIEndpointName,

        [Parameter(ParameterSetName = 'ID', ValueFromPipeline)]
        [int]
        $APIEndpointID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Category,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Contains,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 10000,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $PIIOnly,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('ONLY_VISIBLE', 'ONLY_HIDDEN', 'ALL')]
        [string]
        $Show,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('Name', 'updateDate')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('asc', 'desc')]
        [string]
        $SortOrder,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('ACTIVATED_FIRST', 'LAST_UPDATED')]
        [string]
        $VersionPreference,

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
        # Simulate single endoint GET
        if ($PSCmdlet.ParameterSetName -in 'Name', 'ID') {
            $PSBoundParameters.Page = 0
            $PSBoundParameters.PageSize = 10000

            if ($APIEndpointName) {
                $PSBoundParameters.Contains = $APIEndpointName
            }
        }

        $Path = "/api-definitions/v2/endpoints"
        $QueryParameters = @{
            'page'              = $PSBoundParameters.Page
            'pageSize'          = $PSBoundParameters.PageSize
            'piiOnly'           = $PSBoundParameters.PIIOnly.ISPresent
            'category'          = $Category
            'contains'          = $Contains
            'sortBy'            = $SortBy
            'sortOrder'         = $SortOrder
            'versionPreference' = $VersionPreference
            'show'              = $Show
            'contractId'        = $ContractID
            'groupId'           = $PSBoundParameters.GroupID
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
        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                foreach ($Endpoint in $Response.Body.apiEndpoints) {
                    Set-AkamaiDataCache -APIEndpointName $Endpoint.apiEndpointName -APIEndpointID $Endpoint.apiEndpointId
                }
            }
    
            if ($PSCmdlet.ParameterSetName -eq 'Name') {
                return $Response.Body.apiEndpoints | Where-Object apiEndpointName -eq $APIEndpointName
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ID') {
                return $Response.Body.apiEndpoints | Where-Object apiEndpointId -eq $APIEndpointID
            }
            else {
                return $Response.Body.apiEndpoints
            }
        }
        catch {
            throw $_
        }
    }
}

