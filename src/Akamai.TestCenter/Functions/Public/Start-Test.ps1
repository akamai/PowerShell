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
