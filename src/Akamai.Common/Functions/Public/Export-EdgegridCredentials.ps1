function Export-EdgegridCredentials {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $EdgeRCFile = '~/.edgerc',

        [Parameter()]
        [string]
        $Section = 'default',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('account_key')]
        [Alias('AccountKey')]
        [string]
        $AccountSwitchKey,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('client_token')]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('access_token')]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('client_secret')]
        [string]
        $ClientSecret,

        [Parameter()]
        [switch]
        $Force
    )

    process {
        # Define new credentials
        $NewSection = @(
            "[$Section]"
            "access_token = $AccessToken"
            "client_secret = $ClientSecret"
            "client_token = $ClientToken"
            "host = $HostName"
        ) -join "`n"
        if ($AccountSwitchKey) {
            $NewSection += "`naccount_key = $AccountSwitchKey"
        }

        # Check for existing file
        if (Test-Path -Path $EdgeRCFile) {
            # Get file contents
            $EdgeRCContents = Get-Content -Path $EdgeRCFile -Raw

            $AppendNewEntry = $false

            # Retrieve existing credentials for section, if any
            try {
                $ExistingCredentials = Get-EdgegridCredentials -Section $Section -EdgeRCFile $EdgeRCFile
            }
            catch {
                Write-Debug "Export-EdgegridCredentials: No existing credentials found in $EdgeRCFile for section $Section"
                $AppendNewEntry = $true
            }

            if ($ExistingCredentials) {
                if (-not $Force) {
                    throw "Credentials for section '$Section' already exist in '$EdgeRCFile'. Use -Force to overwrite."
                }

                # Extract entire entry
                $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
                $SectionMatch = $EdgeRCContents | Select-String -Pattern $SectionPattern

                if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
                    $ExistingSection = $SectionMatch.Matches[0].Groups[1].Value.Trim()

                    # Sanitize existing client secret for regex replacement
                    $EscapedExistingClientSecret = [Regex]::Escape($ExistingCredentials.ClientSecret)

                    $UpdatedSection = $ExistingSection -replace "(\r?\n)client_token[ ]*=[ ]*$($ExistingCredentials.ClientToken)", "`$1client_token = $ClientToken"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)access_token[ ]*=[ ]*$($ExistingCredentials.AccessToken)", "`$1access_token = $AccessToken"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)client_secret[ ]*=[ ]*$EscapedExistingClientSecret", "`$1client_secret = $ClientSecret"
                    $UpdatedSection = $UpdatedSection -replace "(\r?\n)host[ ]*=[ ]*$($ExistingCredentials.Host)", "`$1host = $HostName"
                    if ($ExistingCredentials.AccountKey) {
                        if ($AccountSwitchKey) {
                            Write-Debug 'Export-EdgegridCredentials: Replacing account_key in existing section'
                            $UpdatedSection = $UpdatedSection -replace "(\r?\n)account_key[ ]*=[ ]*$($ExistingCredentials.AccountKey)", "`$1account_key = $AccountSwitchKey"
                        }
                        else {
                            Write-Debug 'Export-EdgegridCredentials: Removing account_key from existing section'
                            $UpdatedSection = $UpdatedSection -replace "(\r?\n)account_key[ ]*=[ ]*$($ExistingCredentials.AccountKey)[^\r\n]*", ''
                        }
                    }
                    else {
                        if ($AccountSwitchKey) {
                            Write-Debug 'Export-EdgegridCredentials: Adding account_key to existing section'
                            $UpdatedSection += "`naccount_key = $AccountSwitchKey"
                        }
                    }

                    # Update file
                    Write-Debug "Export-EdgegridCredentials: Replacing existing entry:`n$ExistingSection`nwith updated entry:`n$UpdatedSection"
                    $UpdatedFileContents = $EdgeRCContents.Replace($ExistingSection, $UpdatedSection)
                    Write-Host "Updating section '" -NoNewline
                    Write-Host -ForegroundColor Cyan $Section -NoNewline
                    Write-Host "' in '" -NoNewline
                    Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
                    Write-Host "' with new credentials."
                    $UpdatedFileContents | Set-Content -Path $EdgeRCFile -NoNewline
                }
            }
            else {
                $AppendNewEntry = $true
            }

            if ($AppendNewEntry) {
                # Append new entry
                Write-Debug "Export-EdgegridCredentials: Appending new entry:`n$NewSection"
                $LineBreak = "`n"
                if ($EdgeRCContents.Contains("`r`n")) {
                    Write-Debug 'Export-EdgegridCredentials: Detected Windows line endings in existing file'
                    $LineBreak = "`r`n"
                }

                if (!$EdgeRCContents.EndsWith($LineBreak)) {
                    Write-Debug 'Export-EdgegridCredentials: Adding line break before new entry'
                    Add-Content -Path $EdgeRCFile -Value $LineBreak -NoNewline
                }

                Write-Host "Added new section '" -NoNewline
                Write-Host -ForegroundColor Cyan $Section -NoNewline
                Write-Host "' to '" -NoNewline
                Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
                Write-Host "' with new credentials."
                Add-Content -Path $EdgeRCFile -Value "$LineBreak$NewSection"
                return
            }
        }
        else {
            # Create new file with entry
            Write-Host "Creating new .edgerc file at '" -NoNewline
            Write-Host -ForegroundColor Cyan $EdgeRCFile -NoNewline
            Write-Host "' with section '" -NoNewline
            Write-Host -ForegroundColor Cyan $Section -NoNewline
            Write-Host "'."
            Write-Debug "Export-EdgegridCredentials: Creating new file with entry:`n$NewSection"
            $NewSection | Set-Content -Path $EdgeRCFile
        }
    }

}