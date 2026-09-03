function New-AppSecOnboardingActivation {
    [Alias('Deploy-AppSecOnboarding')]
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory)]
        [int]
        $OnboardingID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $NotificationEmails,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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
        $Path = "/appsec/v1/onboardings/$OnboardingID/activations"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'network'            = $Network
                'notificationEmails' = $NotificationEmails
            }
        }
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
