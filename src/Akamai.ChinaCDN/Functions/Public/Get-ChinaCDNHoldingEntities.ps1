function Get-ChinaCDNHoldingEntities {
    Param(
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

    $Path = "/chinacdn/v1/icp-holding-entities"
    $AdditionalHeaders = @{
        Accept = 'application/vnd.akamai.chinacdn.icp-holding-entities.v1+json'
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
    return $Response.Body.icpHoldingEntities
}

