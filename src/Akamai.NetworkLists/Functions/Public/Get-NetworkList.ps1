function Get-NetworkList {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('uniqueId')]
        [string]
        $NetworkListID,

        [Parameter()]
        [switch]
        $Extended,

        [Parameter()]
        [switch]
        $IncludeElements,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('IP', 'GEO')]
        [string]
        $ListType,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Search,

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
        if ($NetworkListID) {
            $Path = "/network-list/v2/network-lists/$NetworkListID"
        }
        else {
            $Path = "/network-list/v2/network-lists"
        }
        $QueryParameters = @{
            'extended'        = $PSBoundParameters.Extended.IsPresent
            'includeElements' = $PSBoundParameters.IncludeElements.IsPresent
            'listType'        = $ListType
            'search'          = $Search
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
        if ($NetworkListID) {
            return $Response.Body
        }
        else {
            return $Response.Body.networkLists
        }
    }
}

