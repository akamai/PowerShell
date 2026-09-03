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
