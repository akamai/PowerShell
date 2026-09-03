function Set-CloudletPolicyVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [int]
        $PolicyID,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,
        
        [Parameter()]
        [switch]
        $Legacy,

        [Parameter()]
        [switch]
        $OmitRules,

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
        
        ### Sanitize
        $Body = Get-BodyObject -Source $Body
        $Body = @{
            'description' = $Body.description
            'matchRules'  = $Body.matchRules
        }
        foreach ($Rule in $Body.matchRules) {
            $Rule.PSObject.Members.Remove('location')

            ### RC-specific
            if ($Rule.type -eq 'igMatchRule') {
                $Rule.PSObject.Members.Remove('matchURL')
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
