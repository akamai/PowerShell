function Set-EdgeHostname {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $RecordName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $DNSZone,

        [Parameter(Mandatory)]
        [ValidateSet('ttl', 'ipVersionBehavior')]
        [string]
        $Attribute,

        [Parameter(Mandatory)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [string]
        $StatusUpdateEmail,

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

    process {
        $Path = "/hapi/v1/dns-zones/$DNSZone/edge-hostnames/$RecordName"
        $QueryParameters = @{
            'comments'          = $Comments
            'statusUpdateEmail' = $StatusUpdateEmail
        }
        $AdditionalHeaders = @{
            'Content-Type' = 'application/json-patch+json'
        }
        $Body = @(
            @{
                'op'    = 'replace'
                'path'  = "/$Attribute"
                'value' = $Value
            }
        )
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PATCH'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
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
