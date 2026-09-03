function Get-GTMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string]
        $DomainName,

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

    Process {
        if ($DomainName) {
            $Path = "/config-gtm/v1/domains/$DomainName"
        }
        else {
            $Path = "/config-gtm/v1/domains"
        }
        $AdditionalHeaders = @{ 'Accept' = 'application/vnd.config-gtm.v1.8+json' }
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
        if ($DomainName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

