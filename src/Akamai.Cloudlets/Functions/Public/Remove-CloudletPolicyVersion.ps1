function Remove-CloudletPolicyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [nullable[int]]
        $PolicyID,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        $Version,
        
        [Parameter()]
        [switch]
        $Legacy,

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
        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version"
        }
        else {
            $Path = "/cloudlets/v3/policies/$PolicyID/versions/$Version"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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

