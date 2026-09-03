function Get-TestRun {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestRunID,

        [Parameter()]
        [switch]
        $IncludeContext,

        [Parameter()]
        [switch]
        $IncludeSkipped,

        [Parameter()]
        [switch]
        $IncludeAuditInfoInContext,

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
        if ($TestRunID) {
            $Path = "/test-management/v3/test-runs/$TestRunID"
        }
        else {
            $Path = "/test-management/v3/test-runs"
        }
        $QueryParameters = @{ 
            'includeContext'            = $PSBoundParameters.IncludeContext.IsPresent
            'includeSkipped'            = $PSBoundParameters.IncludeSkipped.IsPresent
            'includeAuditInfoInContext' = $PSBoundParameters.IncludeAuditInfoInContext.IsPresent
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
        if ($TestRunID) {
            return $Response.Body
        }
        else {
            return $Response.Body.testRuns
        }
    }

}
