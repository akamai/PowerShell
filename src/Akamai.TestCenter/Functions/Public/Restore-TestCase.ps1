function Restore-TestCase {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,
        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestCaseId,

        [Parameter()]
        [switch]
        $IncludeStatus,

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

    begin {
        $CollatedCaseIDs = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        $CollatedCaseIDs.Add($TestCaseId)
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases/restore"
        $Body = $CollatedCaseIDs
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}
