function Get-IAMGroupMoveAffectedUsers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $SourceGroupID,

        [Parameter(Mandatory)]
        [int]
        $DestinationGroupID,

        [Parameter()]
        [ValidateSet('lostAccess', 'gainAccess')]
        [string]
        $UserType,

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
        $Path = "/identity-management/v3/user-admin/groups/move/$SourceGroupID/$DestinationGroupID/affected-users"
        $QueryParameters = @{
            'userType' = $UserType
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
