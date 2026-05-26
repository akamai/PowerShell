function Get-IAMUser {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $UIIdentityID,

        [Parameter()]
        [switch]
        $Actions,

        [Parameter()]
        [switch]
        $AuthGrants,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $Notifications,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

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
        if ($UIIdentityID) {
            $Path = "/identity-management/v3/user-admin/ui-identities/$UIIdentityID"
        }
        else {
            $Path = "/identity-management/v3/user-admin/ui-identities"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $QueryParameters = @{
                'actions'       = $PSBoundParameters.Actions.IsPresent
                'authGrants'    = $PSBoundParameters.AuthGrants.IsPresent
                'notifications' = $PSBoundParameters.Notifications.IsPresent
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'actions'    = $PSBoundParameters.Actions.IsPresent
                'authGrants' = $PSBoundParameters.AuthGrants.IsPresent
                'groupId'    = $PSBoundParameters.GroupID
            }
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
