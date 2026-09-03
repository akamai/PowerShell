function New-TarArchive {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $SourceDirectory,

        [Parameter(Mandatory)]
        [string]
        $OutputFile
    )

    if ( Get-Command tar -ErrorAction SilentlyContinue) {
        # Work out if we're using 5.1 or later
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $PowerShellBinary = 'pwsh'
        }
        else {
            $PowerShellBinary = 'powershell'
        }

        $InDir = Get-Item $SourceDirectory | Select-Object -ExpandProperty FullName
        $OutFile = New-Item -ItemType File -Path $OutputFile -Force | Select-Object -ExpandProperty FullName

        $TarCommand = "$PowerShellBinary -NoProfile -Command `"Set-Location $InDir; tar -czf $OutFile --exclude='*.tgz' *`""

        # Execute tar
        Write-Debug "New-TarArchive: Executing command '$TarCommand'"
        Invoke-Expression $TarCommand | Out-Null
    }
    else {
        throw "tar command not found. Please create .tgz file manually."
    }
}