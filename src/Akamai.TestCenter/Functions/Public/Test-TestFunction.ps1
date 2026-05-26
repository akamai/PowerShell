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
