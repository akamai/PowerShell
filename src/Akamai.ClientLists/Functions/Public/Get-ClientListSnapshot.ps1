function Get-ClientListSnapshot {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ListID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $Version,

        [Parameter()]
        [string]
        $Search,

        [Parameter()]
        [int]
        $Page,

        [Parameter()]
        [int]
        $PageSize = 1000,

        [Parameter()]
        [string]
        $Sort,

        [Parameter()]
        [switch]
        $IncludeMetadata,

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
        $ListID, $Version = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/versions/$Version/snapshot"
        $QueryParameters = @{
            'search'   = $Search
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PSBoundParameters.PageSize
            'sort'     = $Sort
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
        if ($IncludeMetadata) {
            return $Response.Body
        }
        else {
            return $Response.Body.content
        }
    }
}
