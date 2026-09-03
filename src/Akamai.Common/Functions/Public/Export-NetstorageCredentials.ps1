function Export-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $NSRCFile = '~/.nsrc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Key,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Group,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $Hostname,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $CPCode,

        [Parameter()]
        [switch]
        $Force
    )

    process {
        $NewSection = @(
            "[$Section]"
            "cpcode = $CPCode"
            "group = $Group"
            "host = $Hostname"
            "id = $ID"
            "key = $Key"
        ) -Join "`n"
    
        # Check for existing file
        if (Test-Path -Path $NSRCFile) {
            # Get file contents
            $AuthFileContents = Get-Content -Path $NSRCFile -Raw

            $AppendNewEntry = $false

            # Retrieve existing credentials for section, if any
            try {
                $ExistingCredentials = Get-NetstorageCredentials -Section $Section -NSRCFile $NSRCFile
            }
            catch {
                Write-Debug "Export-NetstorageCredentials: No existing credentials found in $NSRCFile for section $Section"
                $AppendNewEntry = $true
            }
    
            if ($ExistingCredentials) {
                if (-not $Force) {
                    throw "Credentials for section '$Section' already exist in '$NSRCFile'. Use -Force to overwrite."
                }

                # Extract entire entry
                $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
                $SectionMatch = $AuthFileContents | Select-String -Pattern $SectionPattern

                if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
                    $ExistingSection = $SectionMatch.Matches[0].Groups[1].Value.Trim()

                    $UpdatedSection = $ExistingSection -replace "(\r?\n)key[ ]*=[ ]*$($ExistingCredentials.key)", "`$1key = $Key"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)id[ ]*=[ ]*$($ExistingCredentials.id)", "`$1id = $ID"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)group[ ]*=[ ]*$($ExistingCredentials.group)", "`$1group = $Group"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)host[ ]*=[ ]*$($ExistingCredentials.Host)", "`$1host = $HostName"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)cpcode[ ]*=[ ]*$($ExistingCredentials.cpcode)", "`$1cpcode = $CPCode"
                    
                    # Update file
                    Write-Debug "Export-NetstorageCredentials: Replacing existing entry:`n$ExistingSection`nwith updated entry:`n$UpdatedSection"
                    $UpdatedFileContents = $AuthFileContents.Replace($ExistingSection, $UpdatedSection)
                    Write-Host "Updating section '" -NoNewline
                    Write-Host -ForegroundColor Cyan $Section -NoNewline
                    Write-Host "' in '" -NoNewline
                    Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
                    Write-Host "' with new credentials."
                    $UpdatedFileContents | Set-Content -Path $NSRCFile -NoNewLine
                }
            }
            else {
                $AppendNewEntry = $true
            }

            if ($AppendNewEntry) {
                # Append new entry
                Write-Debug "Export-NetstorageCredentials: Appending new entry:`n$NewSection"
                $LineBreak = "`n"
                if ($AuthFileContents.Contains("`r`n")) {
                    Write-Debug "Export-NetstorageCredentials: Detected Windows line endings in existing file"
                    $LineBreak = "`r`n"
                }
                
                if (!$AuthFileContents.EndsWith($LineBreak)) {
                    Write-Debug "Export-NetstorageCredentials: Adding line break before new entry"
                    Add-Content -Path $NSRCFile -Value $LineBreak -NoNewline
                }

                Write-Host "Added new section '" -NoNewline
                Write-Host -ForegroundColor Cyan $Section -NoNewline
                Write-Host "' to '" -NoNewline
                Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
                Write-Host "' with new credentials."
                Add-Content -Path $NSRCFile -Value "$LineBreak$NewSection"
                return
            }
        }
        else {
            # Create new file with entry
            Write-Host "Creating new .nsrc file at '" -NoNewline
            Write-Host -ForegroundColor Cyan $NSRCFile -NoNewline
            Write-Host "' with section '" -NoNewline
            Write-Host -ForegroundColor Cyan $Section -NoNewline
            Write-Host "'."
            Write-Debug "Export-NetstorageCredentials: Creating new file with entry:`n$NewSection"
            $NewSection | Set-Content -Path $NSRCFile
        }
    }
}
