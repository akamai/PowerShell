function Get-BodyObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Source
    )

    if ($Source -is 'String') {
        # Trim whitespace
        $Source = $Source.Trim()
        # Handle JSON array
        if ($Source.StartsWith('[')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source -AsArray -NoEnumerate
        }
        # Handle standard JSON object
        elseif ($Source.StartsWith('{') -and $Source.EndsWith('}')) {
            $BodyObject = ConvertFrom-Json -InputObject $Source
        }
        # If none of the above, just use string as-is
        else {
            $BodyObject = $Source
        }
    }
    elseif ($Source -is 'Hashtable') {
        $BodyObject = [PScustomObject] $Source
    }
    elseif ($Source -is 'PSCustomObject' -or $Source -is 'Object' -or $Source -is 'Object[]') {
        $BodyObject = $Source
    }
    else {
        throw "Source param is of an unhandled type '$($Source.GetType().Name)'"
    }

    return $BodyObject
}

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

function Get-TestCatalogTemplate {
    [CmdletBinding()]
    Param(
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
        $Path = "/test-management/v3/functional/test-catalog/template"
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
        return $Response.Body.conditionTypes
    }

}

function Get-TestCondition {
    [CmdletBinding()]
    Param(
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
        $Path = "/test-management/v3/functional/test-catalog/conditions"
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
        return $Response.Body.conditions
    }

}

function Get-TestRequest {
    [CmdletBinding()]
    Param(
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
        $Path = "/test-management/v3/functional/test-requests"
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
        return $Response.Body.testRequests
    }

}

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

function Get-TestRunResults {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestRunID,

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
        $Path = "/test-management/v3/test-runs/$TestRunID/raw-request-response"
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
        return $Response.Body
    }
}

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

function Initialize-TestSuite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Property Name')]
        [string]
        $PropertyName,

        [Parameter(Mandatory, ParameterSetName = 'Property ID')]
        [int]
        $PropertyID,

        [Parameter(Mandatory, ParameterSetName = 'Property Name')]
        [Parameter(Mandatory, ParameterSetName = 'Property ID')]
        [int]
        $PropertyVersion,

        [Parameter(Mandatory, ParameterSetName = 'Property Name')]
        [Parameter(Mandatory, ParameterSetName = 'Property ID')]
        [string[]]
        $TestRequestURL,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'POST body')]
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
        $Path = '/test-management/v3/functional/test-suites/auto-generate'
        if ($PSCmdlet.ParameterSetName.StartsWith('Property')) {
            $Body = @{
                'configs'         = @{
                    'propertyManager' = @{
                        'propertyVersion' = $PropertyVersion
                    }
                }
                'testRequestUrls' = @($TestRequestURL)
            }

            if ($PropertyName) {
                $Body.configs.propertyManager.propertyName = $PropertyName
            }
            else {
                $Body.configs.propertyManager.propertyId = $Property
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
        return $Response.Body
    }

}

function New-TestCase {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('GET', 'POST', 'HEAD')]
        [string]
        $RequestMethod,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $TestRequestURL,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $ConditionExpression,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('CHROME', 'CURL')]
        [string]
        $Client,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [ValidateSet('US')]
        [string]
        $GeoLocation,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $RequestBody,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $EncodeRequestBody,

        [Parameter(ParameterSetName = 'Attributes')]
        [hashtable[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Variables,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Tags,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'POST body')]
        $Body,

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
        $CollatedCases = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        if ($Body -isnot 'String' -and $Body -IsNot 'Array') {
            $CollatedCases.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $TestCase = @{
                'clientProfile' = @{
                    'client'    = $Client
                    'ipVersion' = $IPVersion
                }
                'condition'     = @{
                    'conditionExpression' = $ConditionExpression
                }
                'testRequest'   = @{
                    'requestMethod'  = $RequestMethod
                    'testRequestUrl' = $TestRequestURL
                }
            }

            # Add geo location to profile
            if ($GeoLocation) {
                $TestCase.clientProfile.geoLocation = $GeoLocation
            }

            # Add variables by splitting key=value pairs
            if ($Variables) {
                $TestCase.variables = New-Object -TypeName System.Collections.Generic.List['object']
                $Variables | ForEach-Object {
                    $Key, $Value = $_ -split '=', 2
                    $TestCase.variables.Add(
                        @{
                            'variableName'  = $Key
                            'variableValue' = $Value
                        }
                    )
                }
            }

            # Add testRequest elements
            if ($RequestBody) {
                $TestCase.testRequest.requestBody = $RequestBody
            }
            if ($EncodeRequestBody) {
                $TestCase.testRequest.encodeRequestBody = $true
            }
            if ($RequestHeaders) {
                $TestCase.testRequest.requestHeaders = $RequestHeaders
            }
            if ($Tags) {
                $TestCase.tags = @($Tags)
            }

            $Body = @($TestCase)
        }
        else {
            if ($CollatedCases.count -gt 0) {
                $Body = $CollatedCases
            }
            # Add array wrapper if missing
            else {
                $Body = Get-BodyObject -Source $Body
                if ($Body -isnot 'Array') {
                    $Body = @($Body)
                }
            }
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($TestCase in $Body) {
            $TestCase.PSObject.Members.Remove('createdDate')
            $TestCase.PSObject.Members.Remove('modifiedDate')
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}

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

function New-TestVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Single variable')]
        [Parameter(Mandatory, ParameterSetName = 'Attributes - Variable group')]
        [string]
        $VariableName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Single variable')]
        [string]
        $VariableValue,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Variable group')]
        [hashtable[]]
        $VariableGroupValue,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'POST body')]
        $Body,

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
        $CollatedVariables = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'POST body' -and $Body -isnot 'String') {
            $CollatedVariables.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes - Single variable') {
            $Body = @(
                @{
                    'variableName'  = $VariableName
                    'variableValue' = $VariableValue
                }
            )
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Attributes - Variable group') {
            $Body = @(
                @{
                    'variableName'       = $VariableName
                    'variableGroupValue' = $VariableGroupValue
                }
            )
        }
        elseif ($CollatedVariables.count -gt 0) {
            $Body = $CollatedVariables
        }

        # Add array wrapper if missing
        $Body = Get-BodyObject -Source $Body
        if ($Body -isnot 'Array') {
            $Body = @($Body)
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($Variable in $Body) {
            $Variable.PSObject.Members.Remove('createdDate')
            $Variable.PSObject.Members.Remove('modifiedDate')
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}

function Remove-TestCase {
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
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases/remove"
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

function Remove-TestSuite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

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
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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

function Remove-TestVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $VariableID,

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
        $CollatedVariableIDs = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        $CollatedVariableIDs.Add($VariableID)
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables/remove"
        $Body = $CollatedVariableIDs
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

function Restore-TestSuite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

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
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/restore"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
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

function Set-TestCase {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases = New-Object -TypeName System.Collections.Generic.List['object']
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases"
        if ($CollatedCases.count -gt 0) {
            $Body = $CollatedCases
        }
        # Add array wrapper if missing
        else {
            $Body = Get-BodyObject -Source $Body
            if ($Body -isnot 'Array') {
                $Body = @($Body)
            }
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($TestCase in $Body) {
            $TestCase.PSObject.Members.Remove('createdDate')
            $TestCase.PSObject.Members.Remove('modifiedDate')
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}

function Set-TestCaseOrder {
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

    begin {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases = New-Object -TypeName System.Collections.Generic.List['object']
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases/order"
        if ($CollatedCases.count -gt 0) {
            $Body = $CollatedCases
        }
        # Add array wrapper if missing
        else {
            $Body = Get-BodyObject -Source $Body
            if ($Body -isnot 'Array') {
                $Body = @($Body)
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

function Set-TestVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedVariables = New-Object -TypeName System.Collections.Generic.List['object']
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedVariables.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables"
        if ($CollatedVariables.count -gt 0) {
            $Body = $CollatedVariables
        }
        # Add array wrapper if missing
        else {
            $Body = Get-BodyObject -Source $Body
            if ($Body -isnot 'Array') {
                $Body = @($Body)
            }
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($Variable in $Body) {
            $Variable.PSObject.Members.Remove('createdDate')
            $Variable.PSObject.Members.Remove('modifiedDate')
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}

function Start-PropertyVersionTest {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $TestSuiteID,

        [Parameter()]
        [int[]]
        $TestCaseID,

        [Parameter(ParameterSetName = 'name', Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'id', Mandatory)]
        [int]
        $PropertyID,

        [Parameter(Mandatory)]
        [int]
        $PropertyVersion,

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
                'propertyManagerExecution' = @{
                    'testSuiteExecutions' = @(
                        @{
                            'testSuiteId' = $TestSuiteID
                        }
                    )
                    'propertyVersion'     = $PropertyVersion
                }
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

        if ($PropertyName) {
            $Body.functional.propertyManagerExecution.propertyName = $PropertyName
        }
        elseif ($PropertyID) {
            $Body.functional.propertyManagerExecution.propertyId = $PropertyId
        }

        if ($null -ne $PSBoundParameters.note) {
            $Body.note = $Note
        }
        if ($null -ne $PSBoundParameters.PurgeOnstaging) {
            $Body.purgeOnStaging = $PurgeOnstaging.IsPresent
        }
        if ($null -ne $PSBoundParameters.SendEmailOnCompletion) {
            $Body.sendEmailOnCompletion = $SendEmailOnCompletion.IsPresent
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

function Start-Test {
    [CmdletBinding(DefaultParameterSetName = 'Specify test attributes')]
    Param(
        [Parameter(ParameterSetName = 'Specify test attributes', Mandatory)]
        [ValidateSet('CHROME', 'CURL')]
        [string]
        $Client,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [ValidateSet('IPV4', 'IPV6')]
        [string]
        $IPVersion,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [ValidateSet('US')]
        [string]
        $GeoLocation,

        [Parameter(ParameterSetName = 'Specify test attributes', Mandatory)]
        [string]
        $ConditionExpression,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [string]
        $TestRequestURL,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [string]
        $RequestMethod,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [hashtable[]]
        $RequestHeaders,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [string]
        $RequestBody,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [switch]
        $EncodeRequestBody,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'Specify test attributes', Mandatory)]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $TargetEnvironment,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [switch]
        $PurgeOnstaging,

        [Parameter(ParameterSetName = 'Specify test attributes')]
        [switch]
        $SendEmailOnCompletion,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Request body')]
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
        $Path = "/test-management/v3/test-runs"
        if ($PSCmdlet.ParameterSetName -eq 'Specify test attributes') {
            $Body = @{
                'functional'        = @{
                    'testCaseExecution' = @{
                        'clientProfile' = @{
                            'client'    = $Client
                            'ipVersion' = $IPVersion
                        }
                        'condition'     = @{
                            'conditionExpression' = $ConditionExpression
                        }
                        'testRequest'   = @{
                            'requestMethod'  = $RequestMethod
                            'testRequestUrl' = $TestRequestURL
                        }
                    }
                }
                'targetEnvironment' = $TargetEnvironment
            }

            if ($GeoLocation) {
                $Body.functional.testCaseExecution.clientProfile.geoLocation = $GeoLocation
            }
            if ($null -ne $PSBoundParameters.EncodeRequestBody) {
                $Body.functional.testCaseExecution.testRequest.encodeRequestBody = $EncodeRequestBody.IsPresent
            }
            if ($RequesBody) {
                $Body.functional.testCaseExecution.testRequest.requestBody = $RequestBody
            }
            if ($RequestHeaders) {
                $Body.functional.testCaseExecution.requestHeaders = $RequestHeaders
            }
            if ($Tags) {
                $Body.functional.testCaseExecution.testRequest.tags = $Tags
            }
            if ($Note) {
                $Body.note = $Note
            }
            if ($null -ne $PSBoundParameters.PurgeOnstaging) {
                $Body.purgeOnStaging = $PurgeOnstaging.IsPresent
            }
            if ($null -ne $PSBoundParameters.SendEmailOnCompletion) {
                $Body.sendEmailOnCompletion = $SendEmailOnCompletion
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
        return $Response.Body
    }

}

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

function Test-TestFunction {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $FunctionExpression,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $StatusText,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $HTTPVersion,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Headers,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Cookies,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $Variables,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Request Body')]
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
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'functionExpression' = $FunctionExpression
                'responseData'       = @{
                    'response' = @{
                        'statusText'  = $StatusText
                        'httpVersion' = $HTTPVersion
                    }
                }
            }

            if ($Headers) {
                $Body.responseData.response.headers = New-Object -TypeName System.Collections.Generic.List[object]
                foreach ($Header in $Headers) {
                    $Name, $Value = $Header -split '=', 2
                    $Body.responseData.response.headers.Add(
                        @{
                            'name'  = $Name.Trim()
                            'value' = $Value.Trim()
                        }
                    )
                }
            }

            if ($Cookies) {
                $Body.responseData.response.cookies = New-Object -TypeName System.Collections.Generic.List[object]
                foreach ($Cookie in $Cookies) {
                    $Name, $Value = $Cookie -split '=', 2
                    $Body.responseData.response.cookies.Add(
                        @{
                            'name'  = $Name.Trim()
                            'value' = $Value.Trim()
                        }
                    )
                }
            }

            if ($Variables) {
                $Body.variables = New-Object -TypeName System.Collections.Generic.List[object]
                foreach ($Variable in $Variables) {
                    $Name, $Value = $Variable -split '=', 2
                    $Body.variables.Add(
                        @{
                            'variableName'  = $Name.Trim()
                            'variableValue' = $Value.Trim()
                        }
                    )
                }
            }
        }
        $Path = "/test-management/v3/functional/functions/try-it"
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


# SIG # Begin signature block
# MIIo2AYJKoZIhvcNAQcCoIIoyTCCKMUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1Akiq2IbCgJLA
# 7glLntm6fqTWDV5z90ZJFHzghnQosaCCDg4wggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggdWMIIFPqADAgECAhAGRzH371ShX6hjGl1wSSyYMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAwMDAwWhcNMjcwMzEw
# MjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgEC
# EwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEDAOBgNV
# BAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1NYXNzYWNodXNldHRz
# MRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1haSBUZWNobm9sb2dp
# ZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVzIEluYzCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdGIPhNWLpaVPlXbSaz
# hGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/Tz35cZcWVMDxq/K7
# wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrSQw25019l1KalUHwI
# nKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi1YHUk4ZQh6Ig5tBx
# 8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7eoLUQ/TcMMA6eOli
# AbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg7fhPHxoXvasRJ0Ea
# CEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR6zxk0hzAMOkK/p7M
# V9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF0eS0Wd6Uz3IbSr0+
# XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCCAf4wHwYDVR0jBBgw
# FoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3RICOlmcsnPu7KwUf
# 9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEFBQcCARYbaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEz
# ODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5j
# cmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAGSBrSnUReHU
# zGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinLR4hJofuNNKORp2MW
# Xpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7oHfI1Pup2IOpKxb00
# UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr9p83Snz/3eW3vOeK
# AFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqCvoNFNZHyXvW9v8Kq
# X/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnDU2xgxMR1BZaDf+uD
# oqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr9TBOi+pS9vNlcCKj
# wLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccggJGczCtiKcD6LZtP3
# VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj5ryLyp+6NAgtNwyr
# kp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbisZ/tTgozdVdPZf2Dy
# 2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz+4IgLQjl0V5I08Qw
# +3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIaIDCCGhwCAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBtfuSgQ9ay8F/gKsViHjt3L
# wHy4yP+RV7rSeSac6doNMA0GCSqGSIb3DQEBAQUABIIBgAbrmK54oSKGi/nQef5b
# xNu47qhci4p4Kr7ji/DXNWr6qWDsG7hTr3YTCG9VWqGEwOEkcsv/dTa+7C1SjpS+
# nMTjgVF8KuJ0BR/rEj1Brq+KOLaoymqeNvoUzKRLfLKESyFW/KkdbUpWtLYVMXvw
# i3LrgczafsQdkmx6V1fYNcfgjslhDG2dihKJG8JTC60PG6IJMBb2NK8FdMWUVAUW
# uXWRoe/v1kbMYoA3Q3GJv09gfyAo9MfReSteWKmljX7AygYrEBGHcd4JoOvN3aq4
# kQHgaTHByMJ1vVaGt41j2VuYOXspqhD1Oq7UyEJ6GmX2+Vu7yDJE3ZlZsapuME/8
# MxdyftaIUTqOA9MaPhmVr78ZlN7F8lJdxxAjYkMB4/kczcjnvwStlDItw5hV5nxx
# h+Hj48ETE8m049686M+N6IjiBVkYl2lrm0EAQz085yRnohfUqtwKh8owCJRiIP54
# c6NTnY3wATC5sP9kN0NL1h7Ci12DSHw94PnYILHqwIsyTaGCF3YwghdyBgorBgEE
# AYI3AwMBMYIXYjCCF14GCSqGSIb3DQEHAqCCF08wghdLAgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG/WwHATAxMA0GCWCG
# SAFlAwQCAQUABCCKieNZb7x2LYxaIgt/NKm8kJvxlMH6+lqF+cG7fh9+qwIQJ2Fu
# 5zBwLRzIWAYrkjwU4BgPMjAyNjA4MjUyMjQwNDhaoIITOjCCBu0wggTVoAMCAQIC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMx
# FzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVz
# dGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0y
# NTA2MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJT
# QTQwOTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBj
# MqiZ3xTWcfsLwOvRxUwXcGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNke
# ECqVQ+3bzWYesFtkepErvUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4
# vEjoT1FpS54dNApZfKY61HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7
# VA1R0V3Zp3DjjANwqAf4lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqg
# r6UnbksIcFJqLbkIXIPbcNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3
# NR39iTTFS+ENTqW8m6THuOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETk
# VWz0dVVZw7knh1WZXOLHgDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1
# p6llN3QgshRta6Eq4B40h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uc
# k5Wggn8O2klETsJ7u8xEehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYR
# NMmSF3voIgMFtNGh86w3ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5
# pwIDAQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X
# 85FxYxlQQ89hjOgwHwYDVR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYD
# VR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcB
# AQSBiDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0G
# CCsGAQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOC
# AgEAZSqt8RwnBLmuYEHs0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavX
# zWjZhY+hIfP2JkQ38U+wtJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4
# pvP/ciZmUnthfAEP1HShTrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluH
# WiKk6FxRPyUPxAAYH2Vy1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WD
# l/FQUSntbjZ80FU3i54tpx5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaasl
# NXdCG1+lqvP4FbrQ6IwSBXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCE
# H1Y58678IgmfORBPC1JKkYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXS
# d+V08X1JUPvB4ILfJdmL+66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUt
# wq1qmcwbdUfcSYCn+OwncVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5
# SlfYxJ7La54i71McVWRP66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn
# 5PhDBf3Froguzzhk++ami+r3Qrx5bIbY3TVzgiFI7Gq3zWcwgga0MIIEnKADAgEC
# AhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcw
# MDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1l
# U3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZ
# loMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM
# 2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj
# 7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQ
# Sku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZ
# lDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+
# 8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRx
# ykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yG
# OP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqI
# MRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm
# 1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBj
# UwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729T
# SunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaA
# HP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQ
# M2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt
# 6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7
# bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmS
# Nq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69
# M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnF
# RsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmM
# Thi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oa
# Qf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx
# 9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3
# /BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIFjTCCBHWgAwIBAgIQDpsYjvnQ
# Lefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAw
# WhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QN
# xDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DC
# srp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTr
# BcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17l
# Necxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WC
# QTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1
# EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KS
# Op493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAs
# QWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUO
# UlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtv
# sauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCC
# ATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQD
# AgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9D
# XFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6
# Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuW
# cqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLih
# Vo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBj
# xZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02f
# c7cBqZ9Xql4o4rmUMYIDfDCCA3gCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQg
# VGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8YS43xBYLR
# xHanlXRoMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjYwODI1MjI0MDQ4WjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTdYjCshgotMGvaOLFoeVIwB/tBfjAvBgkqhkiG9w0BCQQxIgQg
# piL7LM+QXRFFH3vwT+CVZmzr3N3FenQbjG4Nlg+sJ5owNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgSqA/oizXXITFXJOPgo5na5yuyrM/420mmqM08UYRCjMwDQYJKoZI
# hvcNAQEBBQAEggIAAQftV4QetY1Jr75R4BoqUe8WT4W5OtdRY5/zJdYISBWgqkKS
# MhODOSetb2eg+cA48izhbVvaMqGyL+ohy5ufO8hItGp+TpPzepbPsFTWDiO7+ynU
# 8H+bDYC0iRESGq3NkvUKBB52oM7nDCoH54bli1A17a5oucQ17bbxJpxDhLgp9FwV
# M1VK946bdEoE5zIn3ncBdUT8ISEZ2bA36KtBAjxGBPWUg5JciMrlnN97CHX+MU4E
# Bm8pOE88JMI0dYR6VKjnk2tvdyEUJcvsdK2d8cINc04kyZuBjWSzKdAJgm/Qd46g
# VnYa6l0IHDc+evZHujdJaPsN2QKChiAq1HZig9ZLJ+XjNWyHqQmIlxhGjkjUtsbA
# H4Ld1X7bje59R7uYsH1FRQiEsit8WTshnKoINC2WyiySrUeHUEdw0joJXSughokO
# j8WEO/gpvo09F6aaXYbW5JuxvsfNyf6xCSQFw/Q+yJqV1HMINeNrpqwhVdKDOUJt
# unSPkxXNHWXKJk8TFFRH8yqdwCGXK+6PDQlZ0XMpwnCKx677BVEcV8AVyQPokG43
# jh98+kCCjYQklbmSy41WxRlALu/dISTC0xll+m+/VnsQrDJguPMxJCWrpCL/+8ZR
# zLT2DNrE5d/v8WpLM/Jjn3CVTHZgz4O2V1cGCI9pZmjJzlkNudykDrBVBSI=
# SIG # End signature block
