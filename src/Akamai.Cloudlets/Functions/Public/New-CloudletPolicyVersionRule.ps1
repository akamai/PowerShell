function New-CloudletPolicyVersionRule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $PolicyID,

        [Parameter(Mandatory)]
        [string]
        $Version,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $Index,

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
    begin {}
    process {
        $Version = Expand-CloudletPolicyDetails -PolicyID $PolicyID -Version $Version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $Path = "/cloudlets/api/v2/policies/$PolicyID/versions/$Version/rules"
        $QueryParameters = @{
            'index' = $Index
        }

        # Parse body to remove invalid matchUrl
        $Body = Get-BodyObject -Source $Body
        if ($Body.matches.count -gt 0 -and 'matchUrl' -in $Body.PSObject.Properties.Name) {
            $Body.PSObject.Members.Remove('matchUrl')
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
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

