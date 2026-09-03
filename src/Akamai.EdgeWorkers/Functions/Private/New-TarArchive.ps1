function New-TarArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $SourceDirectory,

        [Parameter(Mandatory)]
        [string]
        $OutputFile
    )

    if (Get-Command tar -ErrorAction SilentlyContinue) {
        $InDir = Get-Item $SourceDirectory | Select-Object -ExpandProperty FullName
        $OutFile = New-Item -ItemType File -Path $OutputFile -Force | Select-Object -ExpandProperty FullName

        Push-Location -Path $InDir
        try {
            # Pass arguments directly to avoid command injection and shell parsing issues.
            $TarItems = @(Get-ChildItem -Force -Name)
            $TarVersionOutput = (& tar --version 2>$null | Select-Object -First 1)
            $TarArgs = @(
                '-czf'
                $OutFile
                '--exclude=*.tgz'
            )

            # Add portability flags based on tar implementation.
            if ($TarVersionOutput -match 'GNU tar') {
                $TarArgs += @('--no-xattrs', '--no-acls')
            }
            elseif ($TarVersionOutput -match 'bsdtar|libarchive') {
                $TarArgs += '--disable-copyfile'
            }

            if ($TarItems.Count -gt 0) {
                $TarArgs += '--'
                $TarArgs += $TarItems
            }

            Write-Debug "New-TarArchive: Executing tar with source directory '$InDir' and output '$OutFile'"
            & tar @TarArgs | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "tar failed with exit code $LASTEXITCODE."
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        throw 'tar command not found. Please create .tgz file manually.'
    }
}