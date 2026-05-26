function Get-NetstorageCredentials {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    ## Assign defaults if values not provided
    if ($NSRCFile -eq '') {
        $NSRCFile = '~/.nsrc'
    }
    if ($Section -eq '') {
        $Section = 'default'
    }


    #----------------------------------------------------------------------------------------------
    #                             1. Set up auth object
    #----------------------------------------------------------------------------------------------

    ## Instantiate auth object
    $CredentialElements = @(
        'Key',
        'ID',
        'Group',
        'Host',
        'CPCode'
    )

    $Credentials = New-Object -TypeName PSCustomObject
    $CredentialElements | ForEach-Object {
        $Credentials | Add-Member -MemberType NoteProperty -Name $_ -Value $null
    }

    #----------------------------------------------------------------------------------------------
    #                              2. Check for environment variables
    #----------------------------------------------------------------------------------------------
    
    ## 'default' section is implicit. Otherwise env variable starts with section prefix
    if ($Section.ToLower() -eq 'default') {
        $EnvPrefix = 'NETSTORAGE_'
    }
    else {
        $EnvPrefix = "NETSTORAGE_$Section`_".ToUpper()
    }

    $CredentialElements | ForEach-Object {
        $UpperEnv = "$EnvPrefix$_".ToUpper()
        if (Test-Path Env:\$UpperEnv) {
            $Credentials.$_ = (Get-Item -Path Env:\$UpperEnv).Value
        }
    }

    ## Check essential elements and return
    if ($null -ne $Credentials.Key -and $null -ne $Credentials.ID -and $null -ne $Credentials.Group -and $null -ne $Credentials.Host -and $null -ne $Credentials.CPCode) {
        ## Env creds valid
        Write-Debug "Obtained credentials from environment variables in section '$Section'"
        return $Credentials
    }

    #----------------------------------------------------------------------------------------------
    #                              3. Read from .nsrc file
    #----------------------------------------------------------------------------------------------

    # Get credentials from Auth file
    if (Test-Path $NSRCFile) {
        $AuthFileContent = Get-Content $NSRCFile
        for ($i = 0; $i -lt $AuthFileContent.length; $i++) {
            $line = $AuthFileContent[$i]
            $SanitizedLine = $line.Replace(" ", "")

            if ($line.contains("[") -and $line.contains("]")) {
                $SectionHeader = $SanitizedLine.Substring($Line.indexOf('[') + 1)
                $SectionHeader = $SectionHeader.SubString(0, $SectionHeader.IndexOf(']'))
            }

            ## Skip sections other than desired one
            if ($SectionHeader -ne $Section) { continue }

            if ($SanitizedLine.ToLower().StartsWith('key')) { $Credentials.Key = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('id')) { $Credentials.ID = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('group')) { $Credentials.Group = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('host')) { $Credentials.Host = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
            if ($SanitizedLine.ToLower().StartsWith('cpcode')) { $Credentials.CPCode = $SanitizedLine.SubString($SanitizedLine.IndexOf("=") + 1) }
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.Key -and $null -ne $Credentials.ID -and $null -ne $Credentials.Group -and $null -ne $Credentials.Host -and $null -ne $Credentials.CPCode) {
            Write-Debug "Obtained credentials from auth file '$NSRCFile' in section '$Section'"
            return $Credentials
        }
    }
    
    #----------------------------------------------------------------------------------------------
    #                                     4. Panic!
    #----------------------------------------------------------------------------------------------

    ## Under normal circumstances you should not get this far...    
    throw "Error: Credentials could not be loaded from either; session, environment variables or auth file '$NSRCFile'"
}