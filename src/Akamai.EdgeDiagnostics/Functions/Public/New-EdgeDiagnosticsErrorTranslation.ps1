function New-EdgeDiagnosticsErrorTranslation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ErrorCode,

        [Parameter()]
        [switch]
        $TraceForwardLogs,

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

    $Path = "/edge-diagnostics/v1/error-translator"
    $Body = @{
        'errorCode'        = $ErrorCode
        'traceForwardLogs' = $TraceForwardLogs.IsPresent
    }
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'POST'
        'Body'             = $Body
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}

