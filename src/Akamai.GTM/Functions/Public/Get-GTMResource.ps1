function Get-GTMResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('name')]
        [string]
        $DomainName,

        [Parameter()]
        [string]
        $ResourceName,

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
        if ($ResourceName) {
            $Path = "/config-gtm/v1/domains/$DomainName/resources/$ResourceName"
        }
        else {
            $Path = "/config-gtm/v1/domains/$DomainName/resources"
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
        if ($ResourceName) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}

