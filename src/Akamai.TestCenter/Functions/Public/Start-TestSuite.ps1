function Start-TestSuite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,
        
        [Parameter()]
        [int[]]
        $TestCaseID,

        [Parameter(Mandatory)]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $TargetEnvironment,

        [Parameter()]
        [string]
        $Note,

        [Parameter()]
        [switch]
        $PurgeOnstaging,
        
        [Parameter()]
        [switch]
        $SendEmailOnCompletion,

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
        $Path = "/test-management/v3/test-runs"
        $Body = @{
            'functional'        = @{
                'testSuiteExecutions' = @(
                    @{
                        'testSuiteId' = $TestSuiteID
                    }
                )
            }
            'targetEnvironment' = $TargetEnvironment
        }

        if ($TestCaseID) {
            $Body.functional.testSuiteExecutions[0].testCaseExecutions = New-Object -TypeName System.Collections.Generic.List['object']
            $TestCaseID | ForEach-Object {
                $Body.functional.testSuiteExecutions[0].testCaseExecutions.Add(
                    @{
                        'testCaseId' = $_
                    }
                )
            }
        }

        if ($null -ne $PSBoundParameters.note) {
            $Body.note = $Note
        }
        if ($null -ne $PSBoundParameters.PurgeOnstaging) {
            $Body.purgeOnStaging = $PurgeOnstaging.IsPresent
        }
        if ($null -ne $PSBoundParameters.SendEmailOnCompletion) {
            $Body.sendEmailOnCompletion = $SendEmailOnCompletion
        }

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
        return $Response.Body
    }

}
