
function Restore-NetstorageCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $CpcodeID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $StorageGroupID,

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
        $Path = "/storage/v1/storage-groups/$StorageGroupID/cpcodes/$CpcodeID/cancel-delete"
        $RequestParams = @{
            Path             = $Path
            Method           = 'POST'
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
