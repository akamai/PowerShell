function Get-DataStreamMetrics {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $StreamID,
        
        [Parameter()]
        [string]
        $Start,
        
        [Parameter()]
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

    $Path = "/datastream-config-api/v3/log/streams/metrics"
    $QueryParameters = @{
        'streamId'            = $PSBoundParameters.StreamID
        'start'               = $PSBoundParameters.Start
        'end'                 = $PSBoundParameters.End
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

