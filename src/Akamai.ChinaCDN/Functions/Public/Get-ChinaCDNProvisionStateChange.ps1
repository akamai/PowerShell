function Get-ChinaCDNProvisionStateChange {
    Param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
        [int]
        $ChangeID,

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

    if ($ChangeID) {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes/$ChangeID"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
        }
    }
    else {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes/current"
        $AdditionalHeaders = @{
            Accept = 'application/vnd.akamai.chinacdn.provision-state-changes.v1+json'
        }
    }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'GET'
        'AdditionalHeaders' = $AdditionalHeaders
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    if ($ChangeID) {
        return $Response.Body
    }
    else {
        return $Response.Body.provisionStateChanges
    }
}

