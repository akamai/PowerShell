function Add-NetstorageUploadAccountSSHKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UploadAccountID,
        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Key,
        
        [Parameter()]
        [string]
        $EmailID,
        
        [Parameter()]
        [string]
        $Comments,
        
        [Parameter()]
        [switch]
        $Update,
        
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
        $Path = "/storage/v1/upload-accounts/$UploadAccountID/keys/ssh/$Identity"
        $QueryParameters = @{
            'update' = $PSBoundParameters.Update
        }
        $Body = @{
            key = $Key
        }
        if ($EmailID) {
            $Body.emailId = $EmailID
        }
        if ($Comments) {
            $Body.comments = $Comments
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
