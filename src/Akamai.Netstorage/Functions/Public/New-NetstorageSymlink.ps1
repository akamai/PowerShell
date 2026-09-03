function New-NetstorageSymlink {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $TargetPath,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'symlink'
        $Body = ''
        $EncodedTargetPath = [System.Web.HttpUtility]::UrlEncode($TargetPath)
        $AdditionalOptions = @{
            'target' = $EncodedTargetPath
        }
    
        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'Body'              = $Body
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}