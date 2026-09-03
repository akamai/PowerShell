function Get-TestVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]
        $VariableID,

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
        if ($VariableID) {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables/$VariableID"
        }
        else {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables"
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
        if ($VariableID) {
            return $Response.Body
        }
        else {
            return $Response.Body.variables
        }
    }
}
