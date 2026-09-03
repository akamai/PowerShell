
function Remove-NetstorageGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

        [Parameter()]
        [switch]
        $ForceDelete,

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
        $Path = "/storage/v1/storage-groups/$StorageGroupID"
        $QueryParameters = @{ 
            'forceDelete' = $PSBoundParameters.ForceDelete.IsPresent
        }
        $RequestParams = @{
            Path             = $Path
            Method           = 'DELETE'
            QueryParameters  = $QueryParameters 
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

}
