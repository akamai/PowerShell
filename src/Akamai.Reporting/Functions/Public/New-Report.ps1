function New-Report {
    [CmdletBinding(DefaultParameterSetName = 'Time range')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Report,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ProductFamily,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ReportingArea,

        [Parameter(Mandatory, ParameterSetName = 'Date range')]
        [String]
        $Start,

        [Parameter(Mandatory, ParameterSetName = 'Date range')]
        [String]
        $End,

        [Parameter(Mandatory, ParameterSetName = 'Time range')]
        [string]
        [ValidateSet("LAST_15_MINUTES", "LAST_30_MINUTES", "LAST_1_HOUR", "LAST_3_HOURS", "LAST_6_HOURS", "LAST_12_HOURS", "LAST_1_DAY", "LAST_2_DAYS", "LAST_1_WEEK", "LAST_30_DAYS", "LAST_90_DAYS")]
        $TimeRange,

        [Parameter()]
        $Body,

        [Parameter()]
        [switch]
        $Async,

        [Parameter()]
        [int]
        $PageSize = 50000,

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
        if ($PSCmdlet.ParameterSetName -eq 'Date range') {
            $ISO8601Match = '^[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?$'
            if ($Start -notmatch $ISO8601Match -or $End -notmatch $ISO8601Match) {
                throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
            }
        }

        $Path = "/reporting-api/v2/reports/$ProductFamily/$ReportingArea/$Report/data"

        $QueryParameters = @{
            'start'     = $Start
            'end'       = $End
            'timeRange' = $TimeRange
            'async'     = $Async
            'pageSize'  = $PageSize
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Handle 303 response, which does not error in PS5.1
            if ($Response.Status -eq 303) {
                $QueryID = $Response.Headers.Location | Where-Object { $_ -Match '\/queries\/([^\?]+)' }
                $QueryID = $matches[1]
                $Response = [PSCustomObject] @{
                    QueryID       = $QueryID
                    ProductFamily = $ProductFamily
                    ReportingArea = $ReportingArea
                    Report        = $Report
                }
                return $Response
            }

            return $Response.body
        }
        catch {
            if ([int]$_.Exception.Response.StatusCode -eq 303) {
                $QueryID = $_.Exception.Response.Headers.Location | Where-Object { $_ -Match '\/queries\/([^\?]+)' }
                $QueryID = $matches[1]
                $Response = [PSCustomObject] @{
                    QueryID       = $QueryID
                    ProductFamily = $ProductFamily
                    ReportingArea = $ReportingArea
                    Report        = $Report
                }
                return $Response
            }

            else {
                throw $_
            }
        }
    }
}