function Get-NetstorageGroup {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $CPCodeID,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('NETSTORAGE', 'EDGESTREAM', 'EDGESTREAM_IPHONE', 'ADAPTIVEEDGE', 'AD_INSERTION', 'CONTENT_PREPARATION', 'MSL_ORIGIN', 'FEO')]
        [string]
        $StorageGroupPurpose,

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
        if ($StorageGroupID) {
            $Path = "/storage/v1/storage-groups/$StorageGroupID"
        }
        else {
            $Path = "/storage/v1/storage-groups"
        }
        $QueryParameters = @{
            'cpcodeId'            = $PSBoundParameters.CPCodeID
            'storageGroupPurpose' = $StorageGroupPurpose
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($StorageGroupID) {
            return $Response.Body
        }
        else {
            return $Response.Body.items
        }
    }
}
