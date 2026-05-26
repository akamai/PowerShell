function Get-MSLStream {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $StreamID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize = 100,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('cpcode', 'createdDate', 'dvrWindowInMin', 'format', 'modifiedDate', 'name', 'originHostName', 'status', 'zone')]
        [string]
        $SortKey,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('ASC', 'DESC')]
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
        if ($StreamID) {
            $Path = "/config-media-live/v2/msl-origin/streams/$StreamID"
        }
        else {
            $Path = "/config-media-live/v2/msl-origin/streams"
        }
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
        if ($StreamID) {
            return $Response.Body
        }
        else {
            return $Response.Body.streams
        }
    }
}
