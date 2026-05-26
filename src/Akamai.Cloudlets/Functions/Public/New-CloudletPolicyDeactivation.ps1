function New-CloudletPolicyDeactivation {
    [CmdletBinding()]
    [Alias('Disable-CloudletPolicy')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

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
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/v3/policies/$PolicyID/activations"
        $Body = @{
            'network'       = $Network
            'operation'     = 'DEACTIVATION'
            'policyVersion' = $Version
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
