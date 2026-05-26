
function Complete-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string[]]
        $ValidationScope,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('DNS_CNAME', 'DNS_TXT', 'HTTP')]
        [string[]]
        $ValidationMethod,

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
        $Path = "/domain-validation/v1/domains/validate-now"
        $Body = @{
            'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
        }
        for ($i = 0; $i -lt $DomainName.count; $i++) {
            $DomainObject = @{
                'domainName'       = $DomainName[$i]
                'validationScope'  = $ValidationScope[$i]
                'validationMethod' = $ValidationMethod[$i]
            }
            $Body.domains.Add($DomainObject)
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.domains
        }
        catch {
            throw $_
        }
    }
}