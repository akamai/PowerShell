function New-GTMGeoMap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('name')]
        [string]
        $MapName,

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
        $Path = "/config-gtm/v1/domains/$DomainName/geographic-maps/$MapName"
        $AdditionalHeaders = @{ 
            'Accept'       = 'application/vnd.config-gtm.v1.8+json'
            'Content-Type' = 'application/vnd.config-gtm.v1.8+json'
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.resource
    }

    end {} 
}

