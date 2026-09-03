function Read-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $RemotePath,

        [Parameter()]
        [string]
        $LocalPath,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "download"
    
        if (!$LocalPath) {
            $FileName = $RemotePath.Substring($RemotePath.LastIndexOf("/") + 1)
            $LocalPath = ".\$FileName"
        }
    
        # Track path creation
        $NewItemCreated = $false
        # Create local path with parents
        if (-not (Test-Path $LocalPath)) {
            New-Item -Path $LocalPath -Force | Out-Null
            $NewItemCreated = $true
        }
        Write-Host "Downloading Netstorage file '" -NoNewline
        Write-Host -ForegroundColor Cyan $RemotePath -NoNewline
        Write-Host "' to '" -NoNewline
        Write-Host -ForegroundColor Cyan $LocalPath -NoNewline
        Write-Host "'."
        $RequestParams = @{
            'Path'       = $RemotePath
            'Action'     = $Action
            'Outputfile' = $LocalPath
            'NSRCFile'   = $NSRCFile
            'Section'    = $Section
        }
        try {
            Invoke-NetstorageRequest @RequestParams
        }
        catch {
            if ($NewItemCreated) {
                Remove-Item -Force -Path $LocalPath
            }
            throw $_
        }
    }
}
