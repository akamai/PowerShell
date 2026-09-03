function Import-NetstorageCredentials {
    [CmdletBinding(DefaultParameterSetName = 'Auth file')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $Key,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $ID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $Group,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [Alias('host')]
        [string]
        $Hostname,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Credentials')]
        [string]
        $CPCode,

        [Parameter(ParameterSetName = 'Auth file')]
        [string]
        $NSRCFile,

        [Parameter(ParameterSetName = 'Auth file')]
        [string]
        $Section,

        [Parameter()]
        [string]
        $EnvironmentPrefix
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Credentials') {
            # Set environment variables directly from parameters
            $Credentials = [PSCustomObject] @{
                key    = $Key
                id     = $ID
                group  = $Group
                host   = $Hostname
                cpcode = $CPCode
            }
        }
        else {
            $CommonParams = @{
                'NSRCFile' = $NSRCFile
                'Section'  = $Section
            }
            $Credentials = Get-NetstorageCredentials @CommonParams
        }

        $EnvPrefix = ''
        if ($EnvironmentPrefix) {
            $EnvPrefix = '_' + $EnvironmentPrefix.ToUpper()
        }

        # Set environment variables
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_KEY" -Value $Credentials.key
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_ID" -Value $Credentials.id
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_GROUP" -Value $Credentials.group
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_HOST" -Value $Credentials.host
        Set-Item -Path Env:\"NETSTORAGE$EnvPrefix`_CPCODE" -Value $Credentials.cpcode
    }
}