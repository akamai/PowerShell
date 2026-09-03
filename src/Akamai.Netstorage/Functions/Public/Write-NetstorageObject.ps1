function Write-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]
        $LocalPath,

        [Parameter(Mandatory)]
        [string]
        $RemotePath,

        [Parameter()]
        [string]
        $MTime,

        [Parameter()]
        [string]
        $Size,

        [Parameter()]
        [switch]
        $CheckHash,
        
        [Parameter()]
        [switch]
        $IndexZip,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'upload'
        # Assume if path ends with / we are uploading to a folder and append the filename
        if ($RemotePath.EndsWith("/")) {
            $File = Get-Item $LocalPath
            $RemotePath += $($File.Name)
        }
    
        $AdditionalOptions = @{
            'mtime' = $MTime
            'size'  = $Size
        }
    
        if ($CheckHash) {
            $Hash = (Get-FileHash -Path $LocalPath -Algorithm SHA256).Hash
            $AdditionalOptions['sha256'] = $Hash
        }

        if ($IndexZip) {
            $AdditionalOptions['index-zip'] = 1
        }
    
        $RequestParams = @{
            'Path'              = $RemotePath
            'Action'            = $Action
            'InputFile'         = $LocalPath
            'AdditionalOptions' = $AdditionalOptions
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
