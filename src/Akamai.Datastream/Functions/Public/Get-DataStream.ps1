function Get-DataStream {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogType')]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm', 'appsec', 'answerx')]
        [string]
        $StreamType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StreamID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ObjectName,

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
        if ($StreamID) {
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
        }
        else {
            switch ($StreamType) {
                'cdn' {
                    $Path = '/datastream-config-api/v3/log/cdn/streams'
                }
                'edgeworkers' {
                    $Path = '/datastream-config-api/v3/log/edgeworkers/streams'
                }
                'edns' {
                    $Path = '/datastream-config-api/v3/log/edns/streams'
                }
                'gtm' {
                    $Path = '/datastream-config-api/v3/log/gtm/streams'
                }
                'appsec' {
                    $Path = '/datastream-config-api/v3/log/appsec/streams'
                }
                'answerx' {
                    $Path = '/datastream-config-api/v3/log/answerx/streams'
                }
            }
        }
        $QueryParameters = @{
            'groupId'    = $PSBoundParameters.GroupID
            'objectName' = $ObjectName
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
        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Add stream type to response
            foreach ($Stream in $Response.Body) {
                $Stream | Add-Member -MemberType NoteProperty -Name 'streamType' -Value $StreamType
            }
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
