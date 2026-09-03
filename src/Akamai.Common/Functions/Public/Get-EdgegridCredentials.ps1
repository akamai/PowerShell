function Get-EdgegridCredentials {
    [CmdletBinding()]
    Param(
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

    ## Assign defaults if values not provided
    if ($EdgeRCFile -eq '') {
        $EdgeRCFile = '~/.edgerc'
    }
    else {
        ## If EdgeRCFile is provided we use that, regardless of other auth types being available
        $Mode = 'edgerc'
    }
    if ($Section -eq '') {
        $Section = 'default'
    }


    #----------------------------------------------------------------------------------------------
    #                             1. Set up auth object
    #----------------------------------------------------------------------------------------------

    ## Instantiate auth object
    $Credentials = [PSCustomObject] @{
        Host         = $null
        ClientToken  = $null
        AccessToken  = $null
        ClientSecret = $null
        AccountKey   = $null
    }

    #----------------------------------------------------------------------------------------------
    #                              2. Check for environment variables
    #----------------------------------------------------------------------------------------------

    ## 'default' section is implicit. Otherwise env variable starts with section prefix
    if ($Mode -ne 'edgerc') {
        if ($Section.ToLower() -eq 'default') {
            $EnvPrefix = 'AKAMAI'
        }
        else {
            $EnvPrefix = "AKAMAI_$Section".ToUpper()
        }

        if (Test-Path "env:\$EnvPrefix`_HOST") {
            $Credentials.Host = (Get-Item -Path "env:\$EnvPrefix`_HOST").Value
        }
        if (Test-Path "env:\$EnvPrefix`_CLIENT_TOKEN") {
            $Credentials.ClientToken = (Get-Item -Path "env:\$EnvPrefix`_CLIENT_TOKEN").Value
        }
        if (Test-Path "env:\$EnvPrefix`_ACCESS_TOKEN") {
            $Credentials.AccessToken = (Get-Item -Path "env:\$EnvPrefix`_ACCESS_TOKEN").Value
        }
        if (Test-Path "env:\$EnvPrefix`_CLIENT_SECRET") {
            $Credentials.ClientSecret = (Get-Item -Path "env:\$EnvPrefix`_CLIENT_SECRET").Value
        }
        if (Test-Path "env:\$EnvPrefix`_ACCOUNT_KEY") {
            $Credentials.AccountKey = (Get-Item -Path "env:\$EnvPrefix`_ACCOUNT_KEY").Value
        }

        ## Explicit ASK wins over env variable
        if ($AccountSwitchKey) {
            $Credentials.AccountKey = $AccountSwitchKey
        }

        ## Remove ASK if value is "none"
        if ($AccountSwitchKey -eq "none") {
            $Credentials.AccountKey = $null
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.Host -and $null -ne $Credentials.ClientToken -and $null -ne $Credentials.AccessToken -and $null -ne $Credentials.ClientSecret) {
            ## Env creds valid
            Write-Debug "Obtained credentials from environment variables in section '$Section'"
            return $Credentials
        }
    }

    #----------------------------------------------------------------------------------------------
    #                              3. Read from .edgerc file
    #----------------------------------------------------------------------------------------------

    # Get credentials from EdgeRC
    if (Test-Path $EdgeRCFile) {
        $EdgeRCContent = Get-Content $EdgeRCFile -Raw
        $SectionPattern = "(?s)(\[$Section\].*?)(\[|$)"
        $SectionMatch = $EdgeRCContent | Select-String -Pattern $SectionPattern

        if ($SectionMatch -and $SectionMatch.Matches[0].Groups[1].Value) {
            $SectionContent = $SectionMatch.Matches[0].Groups[1].Value

            $HostMatch = $SectionContent | Select-String -Pattern "\r?\nhost[ ]*=[ ]*([^\s#]+)"
            if ($HostMatch) {
                $Credentials.host = $HostMatch.Matches[0].Groups[1].Value
            }
            $ClientTokenMatch = $SectionContent | Select-String -Pattern "\r?\nclient_token[ ]*=[ ]*([^\s#]+)"
            if ($ClientTokenMatch) {
                $Credentials.ClientToken = $ClientTokenMatch.Matches[0].Groups[1].Value
            }
            $AccessTokenMatch = $SectionContent | Select-String -Pattern "\r?\naccess_token[ ]*=[ ]*([^\s#]+)"
            if ($AccessTokenMatch) {
                $Credentials.AccessToken = $AccessTokenMatch.Matches[0].Groups[1].Value
            }
            $ClientSecretMatch = $SectionContent | Select-String -Pattern "\r?\nclient_secret[ ]*=[ ]*([^\s#]+)"
            if ($ClientSecretMatch) {
                $Credentials.ClientSecret = $ClientSecretMatch.Matches[0].Groups[1].Value
            }
            $AccountKeyMatch = $SectionContent | Select-String -Pattern "\r?\naccount_key[ ]*=[ ]*([^\s#]+)"
            if ($AccountKeyMatch) {
                $Credentials.AccountKey = $AccountKeyMatch.Matches[0].Groups[1].Value
            }
        }
        else {
            throw "Error: Section '$Section' not found in edgerc file '$EdgeRCFile'"
        }

        ## Explicit ASK wins over edgerc file entry
        if ($AccountSwitchKey) {
            $Credentials.AccountKey = $AccountSwitchKey
        }

        ## Remove ASK if value is "none"
        if ($AccountSwitchKey -eq "none") {
            $Credentials.AccountKey = $null
        }

        ## Check essential elements and return
        if ($null -ne $Credentials.host -and $null -ne $Credentials.ClientToken -and $null -ne $Credentials.AccessToken -and $null -ne $Credentials.ClientSecret) {
            Write-Debug "Obtained credentials from edgerc file '$EdgeRCFile' in section '$Section'"
            return $Credentials
        }
    }

    #----------------------------------------------------------------------------------------------
    #                                     4. Panic!
    #----------------------------------------------------------------------------------------------

    ## Under normal circumstances you should not get this far...
    throw "Error: Credentials could not be loaded from either; session, environment variables or edgerc file '$EdgeRCFile'"

}