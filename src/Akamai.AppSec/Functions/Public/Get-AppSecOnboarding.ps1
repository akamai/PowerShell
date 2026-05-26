function Get-AppSecOnboarding {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $OnboardingID,

        [Parameter(ParameterSetName = 'Get all')]
        [string[]]
        $OnboardingStatuses,

        [Parameter(ParameterSetName = 'Get all')]
        [string[]]
        $Hostnames,

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
        if ($OnboardingID) {
            $Path = "/appsec/v1/onboardings/$OnboardingID"
        }
        else {
            $Path = "/appsec/v1/onboardings"
        }
        $QueryParameters = @{
            'onboardingStatuses' = $OnboardingStatuses
            'hostnames'          = $Hostnames
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($OnboardingID) {
                return $Response.Body
            }
            else {
                return $Response.Body.onboardings
            }
        }
        catch {
            throw $_
        }
    }
}
