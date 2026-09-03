function Get-APIEndpointVersion {
    [CmdletBinding(DefaultParameterSetName = 'All by name')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Version by name', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'All by name', Position = 0)]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'Version by ID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'All by ID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory, ParameterSetName = 'Version by name')]
        [Parameter(Mandatory, ParameterSetName = 'Version by ID')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'All by name')]
        [Parameter(ParameterSetName = 'All by ID')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'All by name')]
        [Parameter(ParameterSetName = 'All by ID')]
        [int]
        $PageSize = 1000,

        [Parameter(ParameterSetName = 'All by name')]
        [Parameter(ParameterSetName = 'All by ID')]
        [ValidateSet('ONLY_VISIBLE', 'ONLY_HIDDEN', 'ALL')]
        [string]
        $Show,

        [Parameter(ParameterSetName = 'All by name')]
        [Parameter(ParameterSetName = 'All by ID')]
        [ValidateSet('updateDate', 'updatedBy', 'description', 'versionNumber', 'basedOn', 'stagingStatus', 'productionStatus')]
        [string]
        $SortBy,

        [Parameter(ParameterSetName = 'All by name')]
        [Parameter(ParameterSetName = 'All by ID')]
        [ValidateSet('asc', 'desc')]
        [string]
        $SortOrder,

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
        if ($VersionNumber) {
            $APIEndpointID, $VersionNumber = Expand-APIEndpointDetails @PSBoundParameters
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/resources-detail"
            $QueryParameters = @{
                'page'      = $PSBoundParameters.Page
                'pageSize'  = $PageSize
                'sortBy'    = $SortBy
                'sortOrder' = $SortOrder
                'show'      = $Show
            }
        }
        else {
            $APIEndpointID, $null = Expand-APIEndpointDetails @PSBoundParameters
            $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions"
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
        if ($VersionNumber) {
            return $Response.Body
        }
        else {
            return $Response.Body.apiVersions
        }
    }
}

