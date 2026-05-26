function New-EdgeWorkerAuthToken {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $Hostnames,

        [Parameter()]
        [int]
        $Expiry,

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

    $Path = "/edgeworkers/v1/secure-token"
    $Body = @{
        'hostnames' = @('/*')
    }

    if ($null -ne $PSBoundParameters.Expiry) {
        $Body['expiry'] = $Expiry
    }

    # Set default value for all hostnames and override if provided
    if ($null -ne $PSBoundParameters.Hostnames) {
        $Body['hostnames'] = ($Hostnames -split ',')
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
    return $Response.Body.akamaiEwTrace
}
