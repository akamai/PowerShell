function Set-EdgeKVDefaultAccessPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $AllowNamespacePolicyOverride,

        [Parameter(ParameterSetName = 'Attributes')]
        [switch]
        $RestrictDataAccess,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
        $Body,

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
        $Path = "/edgekv/v1/auth/database"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'dataAccessPolicy' = @{
                    'allowNamespacePolicyOverride' = $AllowNamespacePolicyOverride.IsPresent
                    'restrictDataAccess'           = $RestrictDataAccess.IsPresent
                }
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
}