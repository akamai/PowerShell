function Get-IAMRole {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $RoleID,

        [Parameter()]
        [switch]
        $Actions,

        [Parameter(ParameterSetName = 'Get one')]
        [switch]
        $GrantedRoles,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $Users,

        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $IgnoreContext,

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
        if ($RoleID) {
            $Path = "/identity-management/v3/user-admin/roles/$RoleID"
        }
        else {
            $Path = "/identity-management/v3/user-admin/roles"
        }
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $QueryParameters = @{
                'actions'      = $Actions.IsPresent
                'grantedRoles' = $GrantedRoles.IsPresent
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            $QueryParameters = @{
                'actions'       = $Actions.IsPresent
                'groupId'       = $GroupID
                'users'         = $Users.IsPresent
                'ignoreContext' = $IgnoreContext.IsPresent
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
