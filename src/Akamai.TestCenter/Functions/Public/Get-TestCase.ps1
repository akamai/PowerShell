function Get-TestCase {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

        [Parameter(ParameterSetName = 'single')]
        [int]
        $TestCaseID,

        [Parameter(ParameterSetName = 'single')]
        [switch]
        $IncludeRecentlyDeleted,

        [Parameter()]
        [switch]
        $ResolveVariables,

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
        if ($TestCaseID) {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases/$TestCaseID"
        }
        else {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases"
        }
        $QueryParameters = @{ 
            'includeRecentlyDeleted' = $PSBoundParameters.IncludeRecentlyDeleted.IsPresent
            'resolveVariables'       = $PSBoundParameters.ResolveVariables.IsPresent
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
        if ($TestCaseID) {
            return $Response.Body
        }
        else {
            return $Response.Body.testCases
        }
    }

}
