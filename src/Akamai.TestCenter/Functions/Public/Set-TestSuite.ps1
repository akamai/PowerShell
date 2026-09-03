function Set-TestSuite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ValueFromPipeline)]
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
        $Body = Get-BodyObject -Source $Body
        if ($null -ne $Body.testCases -or $null -ne $Body.variables) {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/with-child-objects"
        }
        else {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID"
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        $Body.PSObject.Members.Remove('createdDate')
        $Body.PSObject.Members.Remove('modifiedDate')
        if ($null -ne $Body.testCases) {
            foreach ($TestCase in $Body.testCases) {
                $TestCase.PSObject.Members.Remove('createdDate')
                $TestCase.PSObject.Members.Remove('modifiedDate')
            }
            foreach ($Variable in $Body.variables) {
                $Variable.PSObject.Members.Remove('createdDate')
                $Variable.PSObject.Members.Remove('modifiedDate')
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
