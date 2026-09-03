function Get-TestSuite {
    [CmdletBinding(DefaultParameterSetName = 'all')]
    Param(
        [Parameter(ParameterSetName = 'single', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

        [Parameter(ParameterSetName = 'single')]
        [switch]
        $IncludeChildObjects,

        [Parameter(ParameterSetName = 'single')]
        [switch]
        $ResolveVariables,

        [Parameter(ParameterSetName = 'all')]
        [switch]
        $IncludeRecentlyDeleted,

        [Parameter(ParameterSetName = 'all')]
        [int]
        $PropertyID,

        [Parameter(ParameterSetName = 'all')]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'all')]
        [int]
        $PropertyVersion,

        [Parameter(ParameterSetName = 'all')]
        [string]
        $User,

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
        if ($IncludeChildObjects) {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/with-child-objects"
        }
        elseif ($PSBoundParameters.TestSuiteID) {
            $Path = "/test-management/v3/functional/test-suites/$TestSuiteID"
        }
        else {
            $Path = "/test-management/v3/functional/test-suites"
        }
        $QueryParameters = @{ 
            'includeRecentlyDeleted' = $PSBoundParameters.IncludeRecentlyDeleted.IsPresent
            'propertyId'             = $PSBoundParameters.PropertyID
            'propertyName'           = $PropertyName
            'propertyVersion'        = $PSBoundParameters.PropertyVersion
            'user'                   = $User
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
        if ($TestSuiteID) {
            return $Response.Body
        }
        else {
            return $Response.Body.testSuites
        }
    }
}
