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
