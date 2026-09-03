function Get-APIOperations {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('ACTIVE_IN_PRODUCTION', 'ACTIVE_IN_STAGING', 'ACTIVE_WITHIN_DATE_RANGE')]
        [string]
        $QueryType,

        [Parameter()]
        [string]
        $ActiveStartTime,

        [Parameter()]
        [string]
        $ActiveEndTime,

        [Parameter()]
        [switch]
        $IncludeDetails,

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

    $Path = "/api-definitions/v2/search-operations"
    $QueryParameters = @{
        'queryType'       = $QueryType
        'activeStartTime' = $ActiveStartTime
        'activeEndTime'   = $ActiveEndTime
        'includeDetails'  = $PSBoundParameters.IncludeDetails
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

