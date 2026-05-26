function Get-GTMDomainAuthority {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [Alias('name')]
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
        $Path = "/config-gtm/v1/domains/$DomainName/authorities"

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
        return $Response.Body
    }
}