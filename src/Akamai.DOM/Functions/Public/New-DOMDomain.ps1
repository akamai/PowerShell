
function New-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'attributes')]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string[]]
        $ValidationScope,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'body')]
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

    process {
        $Path = "/domain-validation/v1/domains"
        if ($PSCmdlet.ParameterSetName -eq 'attributes') {
            $Body = @{
                domains = New-Object -TypeName System.Collections.Generic.List[Object]
            }
            for ($i = 0; $i -lt $DomainName.Count; $i++) {
                $DomainObject = @{
                    'domainName'      = $DomainName[$i]
                    'validationScope' = $ValidationScope[$i]
                }
                $Body.domains.Add($DomainObject)
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
