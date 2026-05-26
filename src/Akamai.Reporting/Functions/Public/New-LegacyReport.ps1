
function New-LegacyReport {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [int]
        $Version,

        [Parameter(Mandatory)]
        [String]
        $Start,

        [Parameter(Mandatory)]
        [String]
        $End,

        [Parameter()]
        [String]
        $DataWrapLabel,

        [Parameter()]
        [int]
        $DataWrapNumberOfItems,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $ObjectIDs,

        [Parameter(Mandatory)]
        [ValidateSet('FIVE_MINUTES', 'HOUR', 'DAY', 'WEEK', 'MONTH')]
        [String]
        $Interval,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Filters,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Metrics,

        [Parameter(ParameterSetName = 'Body', ValueFromPipeline, Mandatory)]
        $Body,

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
            'start'                 = $Start
            'end'                   = $End
            'interval'              = $Interval
            'dataWrapLabel'         = $DataWrapLabel
            'dataWrapNumberOfItems' = $PSBoundParameters.DataWrapNumberOfItems
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'objectIds' = $ObjectIds
            }
            if ($Metrics) { $Body['metrics'] = $Metrics }
            if ($Filters) {
                $Body['filters'] = @{}
                $Filters | ForEach-Object {
                    $Key, $Value = $_.Split('=', 2)
                    if (-not $key -or -not $Value) {
                        throw "ERROR: Filters must be in the format 'filterName=filterValue'"
                    }
                    if ($Key -in $Body['filters'].Keys) {
                        # If the filter already exists, convert to array or append to existing array
                        $Body['filters'][$Key] += $Value
                    }
                    else {
                        $Body['filters'][$Key] = @($Value)
                    }
                }
            }
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
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}