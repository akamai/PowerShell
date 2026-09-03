function New-AppSecActivation {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    [Alias('Deploy-AppSecConfiguration')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Position = 0, Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $ConfigID,

        [Parameter(ParameterSetName = 'Config name', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Config ID', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [Alias('version')]
        [string]
        $VersionNumber,

        [Parameter(ParameterSetName = 'Config name', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID', Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ParameterSetName = 'Config name', Mandatory)]
        [Parameter(ParameterSetName = 'Config ID', Mandatory)]
        [string[]]
        $NotificationEmails,

        [Parameter(ParameterSetName = 'Config name')]
        [Parameter(ParameterSetName = 'Config ID')]
        [string]
        $Note,

        [Parameter(ParameterSetName = 'Config name')]
        [Parameter(ParameterSetName = 'Config ID')]
        [string[]]
        $AcknowledgedInvalidHosts,

        [Parameter(Mandatory, ParameterSetName = 'Body')]
        $Body,

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

    process {
        $Path = "/appsec/v1/activations"
        if ($PSCmdlet.ParameterSetName -ne 'Body') {
            [string] $ConfigID, $VersionNumber, $null = Expand-AppSecConfigDetails @PSBoundParameters
            $Version = [int] $VersionNumber
            $Body = @{
                'action'             = 'ACTIVATE'
                'network'            = $Network
                'activationConfigs'  = @(
                    @{
                        'configId'      = $ConfigID
                        'configVersion' = $Version
                    }
                )
                'note'               = $Note
                'notificationEmails' = $NotificationEmails
            }
            if ($AcknowledgedInvalidHosts) {
                $Body['acknowledgedInvalidHostsByConfig'] = @(
                    @{
                        'configId'     = $ConfigID
                        'invalidHosts' = $AcknowledgedInvalidHosts
                    }
                )
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
