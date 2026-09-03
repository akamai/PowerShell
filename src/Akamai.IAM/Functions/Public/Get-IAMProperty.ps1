function Get-IAMProperty {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Mandatory, ValueFromPipeline)]
        [Alias('PropertyID')]
        [int]
        $AssetID,

        [Parameter(ParameterSetName = 'Get one', Mandatory)]
        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $GroupID,

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
        if ($AssetID) {
            $Path = "/identity-management/v3/user-admin/properties/$AssetID"
        }
        else {
            $Path = "/identity-management/v3/user-admin/properties"
        }
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $QueryParameters = @{
                'groupId' = $GroupID
            }
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
