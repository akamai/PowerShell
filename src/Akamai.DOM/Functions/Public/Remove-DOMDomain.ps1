
function Remove-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $DomainName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $ValidationScope,

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
        $Body = @{
            'domains' = New-Object -TypeName System.Collections.Generic.List[Object]
        }
        for ($i = 0; $i -lt 1; $i++) {
            $DomainObject = @{
                'domainName'      = $DomainName[$i]
                'validationScope' = $ValidationScope[$i]
            }
            $Body.domains.Add($DomainObject)
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters 
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
