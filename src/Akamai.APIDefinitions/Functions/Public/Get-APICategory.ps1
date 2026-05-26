function Get-APICategory {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Get one')]
        [int]
        $APICategoryID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $WithUsageInfo,

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

    if ($APICategoryID) {
        $Path = "/api-definitions/v2/categories/$ApiCategoryID"
    }
    else {
        $Path = "/api-definitions/v2/categories"
    }
    $QueryParameters = @{
        'withUsageInfo' = $PSBoundParameters.WithUsageInfo
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

