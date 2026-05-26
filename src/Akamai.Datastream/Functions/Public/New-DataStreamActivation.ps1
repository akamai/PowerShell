function New-DataStreamActivation {
    [CmdletBinding()]
    [Alias('Deploy-DataStream')]
    Param(
        [Parameter()]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm')]
        [string]
        $LogType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(Mandatory)]
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

    $Path = "/datastream-config-api/v3/log/$LogType/streams/$StreamID/activate"
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'POST'
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}
