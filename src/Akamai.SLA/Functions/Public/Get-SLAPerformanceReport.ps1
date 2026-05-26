function Get-SLAPerformanceReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $SLATestID,

        [Parameter(Mandatory)]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

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
        try {
            Test-ISO8601 -DateTime $Start -RequireTime
            Test-ISO8601 -DateTime $End -RequireTime
        }
        catch {
            Write-Error "Parameters `Start` and `End` must match ISO8601 format, including the time."
            Write-Error $_
            return
        }
        $Path = "/sla-api/v1/tests/$SLATestID/reports/performance"
        $QueryParameters = @{
            'start' = $Start
            'end'   = $End
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
