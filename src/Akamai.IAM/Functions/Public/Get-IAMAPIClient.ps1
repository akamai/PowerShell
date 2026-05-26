function Get-IAMAPIClient {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ClientID,

        [Parameter()]
        [switch]
        $Actions,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $GroupAccess,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $APIAccess,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $Credentials,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $IPACL,

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
        if ($ClientID) {
            if ($ClientID -eq 'self') {
                $Path = "/identity-management/v3/api-clients/self"
            }
            else {
                $Path = "/identity-management/v3/api-clients/$ClientID"
            }
        }
        else {
            $Path = "/identity-management/v3/api-clients"
        }
        $QueryParameters = @{
            'actions'     = $PSBoundParameters.Actions.IsPresent
            'groupAccess' = $PSBoundParameters.GroupAccess.IsPresent
            'apiAccess'   = $PSBoundParameters.APIAccess.IsPresent
            'credentials' = $PSBoundParameters.Credentials.IsPresent
            'ipAcl'       = $PSBoundParameters.IPACL.IsPresent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
