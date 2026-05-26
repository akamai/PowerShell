function Set-IAMCIDRBlock {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [int]
        $CIDRBlockID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $CIDRBlock,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Comments,

        [Parameter(ValueFromPipelineByPropertyName)]
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
        $Path = "/identity-management/v3/user-admin/ip-acl/allowlist/$CIDRBlockID"
        $Body = @{ 
            'cidrBlock' = $CIDRBlock 
            'comments'  = $Comments
            'enabled'   = $Enabled.IsPresent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
