function Rename-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $NewFilename,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'rename'
        $Body = ''
        $OldFilename = $Path.Substring($Path.LastIndexOf("/") + 1)
        $NewPath = $Path.Replace($OldFilename, $NewFilename)
        $EncodedNewPath = [System.Web.HttpUtility]::UrlEncode($NewPath)
        $AdditionalOptions = @{
            'destination' = $EncodedNewPath
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