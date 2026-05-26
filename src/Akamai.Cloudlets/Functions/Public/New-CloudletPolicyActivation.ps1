function New-CloudletPolicyActivation {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    [Alias('Deploy-CloudletPolicy')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [string[]]
        $AdditionalPropertyNames,

        [Parameter(Mandatory)]
        [string]
        [ValidateSet('STAGING', 'PRODUCTION', IgnoreCase = $false)]
        $Network,

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

    Process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy:$Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Body = @{
            'network' = $Network
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/activations"
            if ($AdditionalPropertyNames) {
                $Body.additionalPropertyNames = $AdditionalPropertyNames
            }
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/activations"
            $Body.operation = 'ACTIVATION'
            $Body.policyVersion = $Version
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
