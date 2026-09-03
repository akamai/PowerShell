function Get-LegacyReport {
    [CmdletBinding(DefaultParameterSetName = 'Get by IDs')]
    Param(

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Version,

        [Parameter(Mandatory)]
        [String]
        $Start,

        [Parameter(Mandatory)]
        [String]
        $End,

        [Parameter(ParameterSetName = 'Get by IDs')]
        [String[]]
        $ObjectIDs,

        [Parameter(ParameterSetName = 'Get all IDs')]
        [Switch]
        $AllObjectIDs,

        [Parameter(Mandatory)]
        [ValidateSet("FIVE_MINUTES", "HOUR", "DAY", "WEEK", "MONTH")]
        [String]
        $Interval,

        [Parameter()]
        [String]
        $Filters,

        [Parameter()]
        [String[]]
        $Metrics,

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
        $ISO8601Match = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
        if ($Start -notmatch $ISO8601Match -or $End -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }

        $Path = "/reporting-api/v1/reports/$Name/versions/$Version/report-data"

        $QueryParameters = @{
            'start'        = $Start
            'end'          = $End
            'interval'     = $Interval
            'allObjectIds' = $PSBoundParameters.AllObjectIDs
            'filters'      = $Filters
            'metrics'      = ($Metrics -join ',')
            'objectIds'    = ($ObjectIds -join ',')
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