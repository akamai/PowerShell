function Get-IAMUserProfile {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $Actions,

        [Parameter()]
        [switch]
        $AuthGrants,

        [Parameter()]
        [switch]
        $Notifications,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/identity-management/v3/user-profile"
        $QueryParameters = @{
            'actions'       = $PSBoundParameters.Actions.IsPresent
            'authGrants'    = $PSBoundParameters.AuthGrants.IsPresent
            'notifications' = $PSBoundParameters.Notifications.IsPresent
        }
        $RequestParams = @{
            'Path'            = $Path
            'Method'          = 'GET'
            'QueryParameters' = $QueryParameters
            'EdgeRCFile'      = $EdgeRCFile
            'Section'         = $Section
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
