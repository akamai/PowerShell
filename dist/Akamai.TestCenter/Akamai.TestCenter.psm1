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
# MIIKmAYJKoZIhvcNAQcCoIIKiTCCCoUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+e2tlHudpltJM
# 2nngPcnmcRUBZA7I9sUcskIWI4owW6CCB1owggdWMIIFPqADAgECAhAGRzH371Sh
# X6hjGl1wSSyYMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBD
# b2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjYwMjI1MDAw
# MDAwWhcNMjcwMzEwMjM1OTU5WjCB3jETMBEGCysGAQQBgjc8AgEDEwJVUzEZMBcG
# CysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6
# YXRpb24xEDAOBgNVBAUTBzI5MzM2MzcxCzAJBgNVBAYTAlVTMRYwFAYDVQQIEw1N
# YXNzYWNodXNldHRzMRIwEAYDVQQHEwlDYW1icmlkZ2UxIDAeBgNVBAoTF0FrYW1h
# aSBUZWNobm9sb2dpZXMgSW5jMSAwHgYDVQQDExdBa2FtYWkgVGVjaG5vbG9naWVz
# IEluYzCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAJeMKuhiUI5WSRdG
# IPhNWLpaVPlXbSazhGuvzZxTi623Ht46hiPejDtWB8F8dT2pd+nOWsx5NVgkv7x/
# Tz35cZcWVMDxq/K7wYe9R2GndGgfEL02/j5rslwHr8e6qFzy1axuL/xaGXuBTVrS
# Qw25019l1KalUHwInKLIP7Hw1HLPTacyJNNTsYmOpZNqKIiQe9ivzBd7SuPU0cGi
# 1YHUk4ZQh6Ig5tBx8XZYjTmzbiQr2WWwk/CufaoIPME5zAvmW99S05rAtOqvoUr7
# eoLUQ/TcMMA6eOliAbO5m0w/pv5YDgzhzt9hQez189zZNOkMO6AcHNitJzzsEvCg
# 7fhPHxoXvasRJ0EaCEze0nuVakLPf+mGCLoZYGRctayOn4HP6LEEOGmAnQBZkwFR
# 6zxk0hzAMOkK/p7MV9V6QwOuk9q7WKnIdzS/4RjRtXNxXb2fMNyBEwrwJhdmEhWF
# 0eS0Wd6Uz3IbSr0+XH8FHLflQXFCkPcZKiGPgSCp8rTP3KHr6wIDAQABo4ICAjCC
# Af4wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFKT3
# RICOlmcsnPu7KwUf9HL4YegLMD0GA1UdIAQ2MDQwMgYFZ4EMAQMwKTAnBggrBgEF
# BQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmlu
# Z1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hB
# Mzg0MjAyMUNBMS5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNB
# NDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQAD
# ggIBAGSBrSnUReHUzGTy9VC6hy2oDSpu2QNu5j3o/uoaaAy2CgI0hVJRL/OfYinL
# R4hJofuNNKORp2MWXpy52L5PCGtD6/Hf92bMkDl1AP6nXuplt5HvkFPh5kVDbQ7o
# HfI1Pup2IOpKxb00UNwjtKy+38ZCX0dgkASP2vQFamBCG0eTaGUh/9ZH9rz11Nkr
# 9p83Snz/3eW3vOeKAFL3S5RDEMkTvv09540mnzA4J5lKGES2eje/FhwCCQUQBvqC
# voNFNZHyXvW9v8KqX/3CcN1LAtGCy4XnkFjQRPyn+o/OJv5M5yX2Rm5kq9dYpWnD
# U2xgxMR1BZaDf+uDoqGsLo4OqbPV4Dftp2FDs8DHMD8xP6i/k4htaWShkdyjdijr
# 9TBOi+pS9vNlcCKjwLq6aibcbkUk7ef3wxR5imhajsX22vy8Zd9ByAk07BJrccgg
# JGczCtiKcD6LZtP3VjnqhYPSQ4jk6wCruqcTCTwwO7FrIROVrWb2Ro+ph+/a5Llj
# 5ryLyp+6NAgtNwyrkp2WxZviLbh5AXnmg9Pnwrz64UE93LEjI23AWBJsLFdJTbis
# Z/tTgozdVdPZf2Dy2k8xfYZoIq6V1oWiAoQCzb5B9nETV5NGjiMPskJ4GwnlzOvz
# +4IgLQjl0V5I08Qw+3uvPQ8rHHMLbKgncTqSxqtZ73kItOztMYIClDCCApACAQEw
# fTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hB
# Mzg0IDIwMjEgQ0ExAhAGRzH371ShX6hjGl1wSSyYMA0GCWCGSAFlAwQCAQUAoGow
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILFj7cAGiJ7uV9wqeCsa0iIwduSENnsj
# hBe5Up2etQI5MA0GCSqGSIb3DQEBAQUABIIBgA9XH9MHtI2Hc0fxdQ2DMyBMwMEF
# G0nqfOgpnP/DYaA/n9P2vo9OLPsYE869Oj3XRLYuV5XmKelfN1fIIheJfsvA/9Yu
# +LAhtwUaY8S6f61ZQQS4xILt4caqqW/uZDJTZRiVmlvL06DP2wsC7e7ud6O2+KSY
# FyTgtjbqCBCJtzfNxyDYWPw1Og0MgVz7I4zdnB2mhWTtJxxXtevVPt6JE6Vvij/X
# qqZYd6igq9bq1DSAdIzm/uNwNYn7l7d+j9Es3ED8Jq8ijV7iU73+LmBF0NfasMPQ
# iS04tyYE+02ZeQRAje8WHJ1J+R0U3soEiYUORqdGpupTNOOLZ/0giY5CnlIKEx5R
# XJZ1sH14oW/HDnT+6yll2uqDl3pNdOxcx0CACVwjXf7zdkmYFFQ/07DsDAoDKUn9
# JrrfN1gkXE6OR7wyuUaq689c/fqJCqJ3BRbFcFg4X3r8oJ0aV1TAG0VXdnybS7ap
# QuyQOKPS23FBpGDVs3rmQEqEmbEfvHPxrlL0uQ==
# SIG # End signature block
