function New-AppSecOnboarding {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string[]]
        $Hostnames,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [int]
        $GroupID,

        [Parameter()]
        [switch]
        $CreateNewResourcesOnly,

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
        $Path = "/appsec/v1/onboardings"
        $QueryParameters = @{
            'createNewResourcesOnly' = $PSBoundParameters.CreateNewResourcesOnly.IsPresent
        }
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'hostnames'  = $Hostnames
                'contractId' = $ContractID
                'groupId'    = $GroupID
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters
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
