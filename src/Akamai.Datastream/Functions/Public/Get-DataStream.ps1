function Get-DataStream {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter()]
        [ValidateSet('cdn', 'edgeworkers', 'edns', 'gtm')]
        [string]
        $LogType = 'cdn', # Defaulting to CDN for backward compatibility

        [Parameter(ParameterSetName = 'Get one')]
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

    if ($StreamID) {
        $Path = "/datastream-config-api/v3/log/$LogType/streams/$StreamID"
    }
    else {
        $Path = "/datastream-config-api/v3/log/$LogType/streams"
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
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}
