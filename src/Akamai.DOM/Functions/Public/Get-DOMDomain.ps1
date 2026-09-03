
function Get-DOMDomain {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'single', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $DomainName,

        [Parameter(Mandatory, ParameterSetName = 'single')]
        [ValidateSet('HOST', 'WILDCARD', 'DOMAIN')]
        [string]
        $ValidationScope,

        [Parameter(ParameterSetName = 'single')]
        [switch]
        $IncludeDomainStatusHistory,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $Paginate,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $PageSize = 1000,

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
        if ($DomainName) {
            $Path = "/domain-validation/v1/domains/$DomainName"
            $QueryParameters = @{ 
                'validationScope'            = $ValidationScope
                'includeDomainStatusHistory' = $PSBoundParameters.IncludeDomainStatusHistory.IsPresent
            }
        }
        else {
            $Path = "/domain-validation/v1/domains"
            $QueryParameters = @{ 
                'paginate' = $PSBoundParameters.Paginate.IsPresent
                'page'     = $PSBoundParameters.Page
                'pageSize' = $PageSize
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters 
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($DomainName) {
                return $Response.Body
            }
            else {
                return $Response.Body.domains
            }
        }
        catch {
            throw $_
        }
    }
}
