function Get-DataStreamHistory {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $StreamID,

        [Parameter()]
        [int]
        $StartVersion,

        [Parameter()]
        [int]
        $EndVersion,

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
                $Path = "/datastream-config-api/v3/log/cdn/streams/$StreamID/history"
            }
            'edgeworkers' {
                $Path = "/datastream-config-api/v3/log/edgeworkers/streams/$StreamID/history"
            }
            'edns' {
                $Path = "/datastream-config-api/v3/log/edns/streams/$StreamID/history"
            }
            'gtm' {
                $Path = "/datastream-config-api/v3/log/gtm/streams/$StreamID/history"
            }
            'appsec' {
                $Path = "/datastream-config-api/v3/log/appsec/streams/$StreamID/history"
            }
            'answerx' {
                $Path = "/datastream-config-api/v3/log/answerx/streams/$StreamID/history"
            }
        }

        $HasStartVersion = $PSBoundParameters.ContainsKey('StartVersion')
        $HasEndVersion = $PSBoundParameters.ContainsKey('EndVersion')

        if ($HasStartVersion -and $HasEndVersion -and $StartVersion -gt $EndVersion) {
            throw 'StartVersion cannot be greater than EndVersion.'
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        if ($HasStartVersion -or $HasEndVersion) {
            $QueryParameters = @{}
            if ($HasStartVersion) {
                $QueryParameters['startVersion'] = $StartVersion
            }
            if ($HasEndVersion) {
                $QueryParameters['endVersion'] = $EndVersion
            }
            $RequestParams['QueryParameters'] = $QueryParameters
        }

        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

