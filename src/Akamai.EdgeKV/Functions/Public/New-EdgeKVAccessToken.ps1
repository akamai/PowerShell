function New-EdgeKVAccessToken {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(, ParameterSetName = 'Attributes')]
        [switch]
        $AllowOnProduction,

        [Parameter(, ParameterSetName = 'Attributes')]
        [switch]
        $AllowOnStaging,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Namespace,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Permissions,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RestrictToEdgeWorkerIds,

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
        $Path = "/edgekv/v1/tokens"
        if ($PSCmdlet.ParameterSetName -eq "Attributes") {
            $Body = @{
                'name'                 = $Name
                'allowOnProduction'    = $AllowOnProduction.IsPresent
                'allowOnStaging'       = $AllowOnStaging.IsPresent
                'namespacePermissions' = @{ $Namespace = @() }
            }

            $Permissions.ToCharArray() | ForEach-Object {
                if ($_ -ne 'r' -and $_ -ne 'w' -and $_ -ne 'd') {
                    throw "Permissions must be 'r', 'w' or 'd'"
                }
                $Body.namespacePermissions.$Namespace += $_
            }

            if ($RestrictToEdgeWorkerIds) {
                $Body.restrictToEdgeWorkerIds = $RestrictToEdgeWorkerIds
            }
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