function Get-DataStreamMetrics {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [int]
        $StreamID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

        [Parameter()]
        [int]
        $GroupID,

        [Parameter()]
        [ValidateSet('FIVE_MINUTE', 'HOUR', 'DAY')]
        [string]
        $AggregationInterval,

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

    process {
        if ($IncludeDetails) {
            Write-Warning "$IncludeDetails is no longer supported, ignored if passed, and will be removed in v4."
        }
        $Path = "/datastream-config-api/v3/log/$StreamType/streams/metrics"
        $QueryParameters = @{
            'streamId'            = $StreamID
            'start'               = $Start
            'end'                 = $End
            'aggregationInterval' = $AggregationInterval
            'includeDetails'      = $PSBoundParameters.includeDetails
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

