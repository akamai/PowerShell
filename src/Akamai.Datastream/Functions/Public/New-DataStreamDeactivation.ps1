function New-DataStreamDeactivation {
    [CmdletBinding()]
    [Alias('Disable-DataStream')]
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
                $Path = "/datastream-config-api/v3/log/cdn/streams/$StreamID/deactivate"
            }
            'edgeworkers' {
                $Path = "/datastream-config-api/v3/log/edgeworkers/streams/$StreamID/deactivate"
            }
            'edns' {
                $Path = "/datastream-config-api/v3/log/edns/streams/$StreamID/deactivate"
            }
            'gtm' {
                $Path = "/datastream-config-api/v3/log/gtm/streams/$StreamID/deactivate"
            }
            'appsec' {
                $Path = "/datastream-config-api/v3/log/appsec/streams/$StreamID/deactivate"
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
