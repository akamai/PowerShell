function Get-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $ListID,

        [Parameter()]
        [string]
        $Include,

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
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v1/lists/$ListID/items"
        $QueryParameters = @{
            'include'  = $Include
            'search'   = $Search
            'page'     = $PSBoundParameters.Page
            'pageSize' = $PageSize
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
