function Initialize-EdgeKV {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $AllowNamespacePolicyOverride,
        
        [Parameter()]
        [switch]
        $RestrictDataAccess,

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

    $Path = "/edgekv/v1/initialize"
    $Body = @{
        'dataAccessPolicy' = @{
            'allowNamespacePolicyOverride' = $AllowNamespacePolicyOverride.IsPresent
            'restrictDataAccess'           = $RestrictDataAccess.IsPresent
        }
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

