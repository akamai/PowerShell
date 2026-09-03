function Remove-DataStream {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm')]
        [string]
        $LogType = 'cdn', # Defaulting to CDN for backward compatibility
        
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

    begin {}
    process {
        $Path = "/datastream-config-api/v3/log/$logType/streams/$StreamID"
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
    end {}
}
