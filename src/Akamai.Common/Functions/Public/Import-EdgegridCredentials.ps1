function Import-EdgegridCredentials {
    [CmdletBinding(DefaultParameterSetName = 'EdgeRC file')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('client_token')]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('access_token')]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('client_secret')]
        [string]
        $ClientSecret,

        [Parameter(ParameterSetName = 'EdgeRC file')]
        [string]
        $EdgeRCFile,

        [Parameter(ParameterSetName = 'EdgeRC file')]
        [string]
        $Section,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('account_key')]
        [Alias('AccountKey')]
        [string]
        $AccountSwitchKey,

        [Parameter()]
        [string]
        $EnvironmentPrefix
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Credentials') {
            $Credentials = [PSCustomObject]@{
                'Host'         = $HostName
                'ClientToken'  = $ClientToken
                'AccessToken'  = $AccessToken
                'ClientSecret' = $ClientSecret
            }
            if ($AccountSwitchKey) {
                $Credentials | Add-Member -MemberType NoteProperty -Name 'AccountKey' -Value $AccountSwitchKey
            }
        }
        else {
            # Retrieve credentials from edgerc file
            $CommonParams = @{
                'EdgeRCFile'       = $EdgeRCFile
                'Section'          = $Section
                'AccountSwitchKey' = $AccountSwitchKey
            }
            $Credentials = Get-EdgegridCredentials @CommonParams
        }

        $EnvPrefix = if ($EnvironmentPrefix) { "_$($EnvironmentPrefix.ToUpper())" } else { "" }

        # Set environment variables
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_CLIENT_TOKEN" -Value $Credentials.ClientToken
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_CLIENT_SECRET" -Value $Credentials.ClientSecret
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_ACCESS_TOKEN" -Value $Credentials.AccessToken
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_HOST" -Value $Credentials.Host
        Set-Item -Path Env:\"AKAMAI$EnvPrefix`_ACCOUNT_KEY" -Value $Credentials.AccountKey
    }

}