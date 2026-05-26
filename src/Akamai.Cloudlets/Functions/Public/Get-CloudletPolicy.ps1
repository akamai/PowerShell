function Get-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, ValueFromPipeline)]
        [int]
        $PolicyID,

        [Parameter()]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IncludeDeleted,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CloudletID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $All,

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

    Process {
        if ($Legacy) {
            if ($PolicyID) {
                $Path = "/cloudlets/api/v2/policies/$PolicyID"
            }
            else {
                $Path = "/cloudlets/api/v2/policies"
            }
            $QueryParameters = @{
                'gid'            = $PSBoundParameters.GroupID
                'includedeleted' = $PSBoundParameters.IncludeDeleted
                'cloudletId'     = $CloudletId
                'offset'         = $PSBoundParameters.Page
                'pageSize'       = $PSBoundParameters.PageSize
            }
        }
        else {
            if ($PolicyID) {
                $Path = "/cloudlets/v3/policies/$PolicyID"
            }
            else {
                $Path = "/cloudlets/v3/policies"
            }
            $QueryParameters = @{
                'page' = $PSBoundParameters.Page
                'size' = $PSBoundParameters.PageSize
            }
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

        # If -all is selected, loop through paged responses until you get to the end.
        if ($All) {
            if ($Response.Headers.Link) {
                $NextPresent = $Response.Headers.Link | Select-Object -First 1 | Select-String -pattern '^.*,.*offset=([\d]+).*pageSize=([\d]+)>;\s+rel=\"next\".*$'
                if ($NextPresent) {
                    $NextOffset = $NextPresent.Matches.Groups[1].Value
                    $NextPageSize = $NextPresent.Matches.Groups[2].Value
                    if ($NextOffset -and $NextPageSize) {
                        Write-Debug "Loading next request with offset $NextOffset and page size $NextPageSize"
                        $PSBoundParameters.Page = $NextOffset
                        $PSBoundParameters.PageSize = $NextPageSize
                        $PagedResult = Get-CloudletPolicy @PSBoundParameters
                        if ($Legacy) {
                            $Response.Body += $PagedResult
                        }
                        else {
                            $Response.Body.Content += $PagedResult
                        }
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get all' -and -not $Legacy) {
            return $Response.Body.content
        }
        else {
            return $Response.Body
        }
    }
}

