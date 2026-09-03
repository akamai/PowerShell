function Get-DataStreamDatasets {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter()]
        [string]
        $ProductID,

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
        switch ($StreamType) {
            'cdn' {
                $Path = '/datastream-config-api/v3/log/cdn/datasets-fields'
            }
            'edgeworkers' {
                $Path = '/datastream-config-api/v3/log/edgeworkers/datasets-fields'
            }
            'edns' {
                $Path = '/datastream-config-api/v3/log/edns/datasets-fields'
            }
            'gtm' {
                $Path = '/datastream-config-api/v3/log/gtm/datasets-fields'
            }
            'appsec' {
                $Path = '/datastream-config-api/v3/log/appsec/datasets-fields'
            }
            'answerx' {
                $Path = '/datastream-config-api/v3/log/answerx/datasets-fields'
            }
        }
        $QueryParameters = @{
            'productId' = $ProductID
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
        return $Response.Body.datasetFields
    }
}

