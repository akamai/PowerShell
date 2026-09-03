function New-ChinaCDNProvisionStateChange {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
        [switch]
        $ForceDeprovision,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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
        $Path = "/chinacdn/v1/property-hostnames/$Hostname/provision-state-changes"
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.provision-state-change.v1+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}

    
}

