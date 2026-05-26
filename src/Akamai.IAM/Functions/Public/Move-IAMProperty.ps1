function Move-IAMProperty {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PropertyID')]
        [int]
        $AssetID,

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
        $Path = "/identity-management/v3/user-admin/properties/$AssetID"
        $Body = @{
            'sourceGroupId'      = $SourceGroupID
            'destinationGroupId' = $DestinationGroupID
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
