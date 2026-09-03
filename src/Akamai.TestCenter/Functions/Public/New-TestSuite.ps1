function New-TestSuite {
    [CmdletBinding(DefaultParameterSetName = 'parameters-id')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'parameters-name')]
        [Parameter(Mandatory, ParameterSetName = 'parameters-id')]
        [string]
        $TestSuiteName,
        
        [Parameter(ParameterSetName = 'parameters-name')]
        [Parameter(ParameterSetName = 'parameters-id')]
        [string]
        $TestSuiteDescription,
        
        [Parameter(ParameterSetName = 'parameters-name')]
        [Parameter(ParameterSetName = 'parameters-id')]
        [switch]
        $IsStateful,
        
        [Parameter(ParameterSetName = 'parameters-name')]
        [Parameter(ParameterSetName = 'parameters-id')]
        [switch]
        $IsLocked,
        
        [Parameter(Mandatory, ParameterSetName = 'parameters-name')]
        [string]
        $PropertyName,

        [Parameter(Mandatory, ParameterSetName = 'parameters-id')]
        [int]
        $PropertyID,
        
        [Parameter(Mandatory, ParameterSetName = 'parameters-name')]
        [Parameter(Mandatory, ParameterSetName = 'parameters-id')]
        [int]
        $PropertyVersion,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'body')]
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
        if ($PSCmdlet.ParameterSetName.StartsWith('parameters')) {
            $Path = '/test-management/v3/functional/test-suites'
            $Type = 'basic'
            $Body = @{
                'testSuiteName' = $TestSuiteName
                'isStateful'    = $IsStateful.IsPresent
                'isLocked'      = $IsLocked.IsPresent
                'configs'       = @{
                    'propertyManager' = @{
                        'propertyVersion' = $PropertyVersion
                    }
                }
            }

            if ($TestSuiteDescription) {
                $Body.testSuiteDescription = $TestSuiteDescription
            }
            if ($PropertyName) {
                $Body.configs.propertyManager.propertyName = $PropertyName
            }
            if ($PropertyID) {
                $Body.configs.propertyManager.propertyId = $PropertyID
            }
        }
        else {
            $Body = Get-BodyObject -Source $Body
            if ($null -ne $Body.testCases -or $null -ne $Body.variables) {
                $Path = '/test-management/v3/functional/test-suites/with-child-objects'
                $Type = 'withChild'
            }
            else {
                $Path = '/test-management/v3/functional/test-suites'
                $Type = 'basic'
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
        if ($Type -eq 'withChild') {
            return $Response.Body.success
        }
        else {
            return $Response.Body
        }
    }

}
