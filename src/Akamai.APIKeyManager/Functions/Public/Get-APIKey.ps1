function Get-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $KeyID,

        [Parameter(ParameterSetName = 'Get all')]
        [int64]
        $CollectionID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Filter,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('PENDING_DEPLOYMENT', 'DEPLOYED', 'PENDING_REVOCATION', 'REVOKED')]
        [string]
        $KeyStatus,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('asc', 'desc')]
        [string]
        $SortDirection,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('createdAt', 'id', 'label', 'description')]
        [string]
        $SortColumn,

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
        if ($null -ne $PSBoundParameters.KeyID) {
            $Path = "/apikey-manager-api/v2/keys/$KeyID"
        }
        else {
            $Path = "/apikey-manager-api/v2/keys"
        }

        $QueryParameters = @{
            'collectionId' = $PSBoundParameters.CollectionID
            'filter'       = $Filter
            'keyType'      = $KeyType
            'page'         = $PSBoundParameters.Page
            'pageSize'     = $PSBoundParameters.PageSize
            'sortDirect'   = $SortDirection
            'sortColumn'   = $SortColumn
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
        if ($null -ne $PSBoundParameters.KeyID) {
            return $Response.Body
        }
        else {
            return $Response.Body.keys
        }
    }
}

