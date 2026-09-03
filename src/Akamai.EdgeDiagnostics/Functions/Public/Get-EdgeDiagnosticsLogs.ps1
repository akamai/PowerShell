function Get-EdgeDiagnosticsLogs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $EdgeIP,

        [Parameter(Mandatory)]
        [int]
        $CPCode,

        [Parameter()]
        [string]
        $ClientIP,

        [Parameter()]
        [string]
        $ObjectStatus,

        [Parameter()]
        [string]
        $HttpStatusCode,

        [Parameter()]
        [string]
        $UserAgent,

        [Parameter()]
        [string]
        $ARL,

        [Parameter()]
        [string]
        $Start,

        [Parameter(Mandatory)]
        [string]
        $End,

        [Parameter()]
        [ValidateSet('R', 'F')]
        [string]
        $LogType,

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

    $ISO8601Match = '[\d]{4}-[\d]{2}-[\d]{2}(T[\d]{2}:[\d]{2}(:[\d]{2})?(Z|[+-]{1}[\d]{2}[:][\d]{2})?)?'
    if ($Start) {
        if ($Start -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }
    }
    if ($End) {
        if ($End -notmatch $ISO8601Match) {
            throw "ERROR: Start & End must be in the format 'YYYY-MM-DDThh:mm(:ss optional) and (optionally) end with: 'Z' for UTC or '+/-XX:XX' to specify another timezone"
        }
    }

    $Path = "/edge-diagnostics/v1/grep"
    $QueryParameters = @{
        'edgeIp'         = $EdgeIP
        'cpCode'         = $PSBoundParameters.CPCode
        'clientIp'       = $ClientIP
        'objectStatus'   = $ObjectStatus
        'httpStatusCode' = $HTTPStatusCode
        'userAgent'      = $UserAgent
        'arl'            = $ARL
        'start'          = $Start
        'end'            = $End
        'logType'        = $LogType
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

