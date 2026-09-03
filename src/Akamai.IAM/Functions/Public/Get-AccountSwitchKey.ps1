function Get-AccountSwitchKey {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $Search,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Path = "/identity-management/v3/api-clients/self/account-switch-keys"
        $QueryParameters = @{
            'search' = $Search
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = 'none'
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
