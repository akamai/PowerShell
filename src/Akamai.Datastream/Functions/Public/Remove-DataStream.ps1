function Remove-DataStream {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StreamID,

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
                $Path = "/datastream-config-api/v3/log/cdn/streams/$StreamID"
            }
            'edgeworkers' {
                $Path = "/datastream-config-api/v3/log/edgeworkers/streams/$StreamID"
            }
            'edns' {
                $Path = "/datastream-config-api/v3/log/edns/streams/$StreamID"
            }
            'gtm' {
                $Path = "/datastream-config-api/v3/log/gtm/streams/$StreamID"
            }
            'appsec' {
                $Path = "/datastream-config-api/v3/log/appsec/streams/$StreamID"
            }
            'answerx' {
                $Path = "/datastream-config-api/v3/log/answerx/streams/$StreamID"
            }
        }
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
