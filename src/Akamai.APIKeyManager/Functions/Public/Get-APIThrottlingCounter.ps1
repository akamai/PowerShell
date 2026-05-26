function Get-APIThrottlingCounter {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CounterID,

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
        if ($CounterID) {
            $Path = "/apikey-manager-api/v2/counters/$CounterID"
        }
        else {
            $Path = "/apikey-manager-api/v2/counters"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($CounterID) {
            return $Response.Body
        }
        else {
            return $Response.Body.throttlingCounters
        }
    }
}

