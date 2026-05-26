function New-IAMCIDRBlock {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $CIDRBlock,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [switch]
        $Enabled,

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
        $Path = "/identity-management/v3/user-admin/ip-acl/allowlist"
        $Body = @{ 
            'cidrBlock' = $CIDRBlock 
            'comments'  = $Comments
            'enabled'   = $Enabled.IsPresent
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
