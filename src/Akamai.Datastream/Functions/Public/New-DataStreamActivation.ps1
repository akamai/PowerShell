function New-DataStreamActivation {
    [CmdletBinding()]
    [Alias('Deploy-DataStream')]
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
                $Path = "/datastream-config-api/v3/log/cdn/streams/$StreamID/activate"
            }
            'edgeworkers' {
                $Path = "/datastream-config-api/v3/log/edgeworkers/streams/$StreamID/activate"
            }
            'edns' {
                $Path = "/datastream-config-api/v3/log/edns/streams/$StreamID/activate"
            }
            'gtm' {
                $Path = "/datastream-config-api/v3/log/gtm/streams/$StreamID/activate"
            }
            'appsec' {
                $Path = "/datastream-config-api/v3/log/appsec/streams/$StreamID/activate"
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Add stream type to response
            $Response.Body | Add-Member -MemberType NoteProperty -Name 'streamType' -Value $StreamType
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
