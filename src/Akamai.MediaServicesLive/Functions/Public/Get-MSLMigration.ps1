function Get-MSLMigration {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [int]
        $Page,
        
        [Parameter()]
        [int]
        $PageSize = 100,

        [Parameter()]
        [ValidateSet('migrationType', 'migrationStatus', 'migrationTime')]
        [String]
        $SortKey,

        [Parameter()]
        [ValidateSet('ASC', 'DESC')]
        [String]
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
        $Path = "/config-media-live/v2/msl-origin/streams/migrate"
        $QueryParameters = @{
            'page'      = $PSBoundParameters.Page
            'pageSize'  = $PageSize
            'sortKey'   = $SortKey
            'sortOrder' = $SortOrder
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
        return $Response.Body
    }   
}