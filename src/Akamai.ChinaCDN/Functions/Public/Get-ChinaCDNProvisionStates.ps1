function Get-ChinaCDNProvisionStates {
    Param(
        [Parameter()]
        [string]
        $ProvisionState,

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

    $Path = "/chinacdn/v1/current-provision-states"
    $QueryParameters = @{
        'provisionState' = $ProvisionState
    }

    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.provision-states.v1+json'
    }
    $RequestParams = @{
        'Path'              = $Path
        'Method'            = 'GET'
        'AdditionalHeaders' = $AdditionalHeaders
        'QueryParameters'   = $QueryParameters
        'EdgeRCFile'        = $EdgeRCFile
        'Section'           = $Section
        'AccountSwitchKey'  = $AccountSwitchKey
        'Debug'             = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body.provisionStates
}

