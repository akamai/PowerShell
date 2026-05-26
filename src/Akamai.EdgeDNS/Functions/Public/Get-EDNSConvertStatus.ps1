
function Get-EDNSConvertStatus {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Get one', ValueFromPipelineByPropertyName)]
        [string]
        $RequestID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IsComplete,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $Page,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $PageSize,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $ShowAll,

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
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/config-dns/v2/zones/convert-requests/$RequestID"
        }
        else {
            $Path = "/config-dns/v2/zones/convert-requests"
            $QueryParameters = @{
                'isComplete' = $PSBoundParameters.IsComplete.IsPresent
                'page'       = $PSBoundParameters.Page
                'pageSize'   = $PSBoundParameters.PageSize
                'showAll'    = $PSBoundParameters.ShowAll.IsPresent
            }
        }

        $RequestParameters = @{
            Path             = $Path
            Method           = 'GET'
            QueryParameters  = $QueryParameters
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($PSCmdlet.ParameterSetName -eq 'Get one') {
                return $Response.Body
            }
            else {
                return $Response.Body.requests
            }
        }
        catch {
            throw $_
        }
    }
}
