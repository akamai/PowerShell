function Move-IAMGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $SourceGroupID,

        [Parameter(Mandatory)]
        [int]
        $DestinationGroupID,

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
        $Path = "/identity-management/v3/user-admin/groups/move"
        $Body = @{
            'sourceGroupId'      = $SourceGroupID
            'destinationGroupId' = $DestinationGroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
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
