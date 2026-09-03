function Get-ClientList {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get all', Position = 0)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, Mandatory)]
        [string]
        $ListID,

        [Parameter()]
        [switch]
        $IncludeItems,

        [Parameter()]
        [switch]
        $IncludeNetworkList,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeDeprecated,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 1000,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Sort,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH', 'USER_ID')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Get all')]
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
        if ($ListID) {
            $Path = "/client-list/v1/lists/$ListID"
        }
        else {
            $Path = "/client-list/v1/lists"
        }
        $QueryParameters = @{
            'includeItems'       = $PSBoundParameters.IncludeItems.IsPresent
            'includeDeprecated'  = $PSBoundParameters.IncludeDeprecated.IsPresent
            'search'             = $Search
            'page'               = $PSBoundParameters.Page
            'pageSize'           = $PageSize
            'sort'               = $Sort
            'type'               = $Type
            'includeNetworkList' = $PSBoundParameters.IncludeNetworkList.IsPresent
            'name'               = $Name
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
                if ($ListID) {
                    Set-AkamaiDataCache -ClientListName $Response.Body.Name -ClientListID $Response.Body.listId
                }
                else {
                    foreach ($List in $Response.Body.content) {
                        Set-AkamaiDataCache -ClientListName $List.Name -ClientListID $List.listId
                    }
                }
            }
    
            # Return response
            if ($ListID -or $IncludeMetadata) {
                return $Response.Body
            }
            else {
                return $Response.Body.content
            }
        }
        catch {
            throw $_
        }
    }
}
