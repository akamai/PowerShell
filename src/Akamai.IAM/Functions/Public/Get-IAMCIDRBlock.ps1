function Get-IAMCIDRBlock {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CIDRBlockID,

        [Parameter()]
        [switch]
        $Actions,

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
        if ($CIDRBlockID) {
            $Path = "/identity-management/v3/user-admin/ip-acl/allowlist/$CIDRBlockID"
        }
        else {
            $Path = "/identity-management/v3/user-admin/ip-acl/allowlist"
        }
        $QueryParameters = @{
            'actions' = $Actions.IsPresent
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
