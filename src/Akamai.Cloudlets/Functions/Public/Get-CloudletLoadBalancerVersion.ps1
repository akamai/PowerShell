function Get-CloudletLoadBalancerVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [string]
        $OriginID,

        [Parameter(Position = 1)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Validate,

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
        if ($Version) {
            $Version = Expand-CloudletLoadBalancerDetails -OriginID $OriginID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
            $Path = "/cloudlets/api/v2/origins/$OriginID/versions/$Version"
        }
        else {
            $Path = "/cloudlets/api/v2/origins/$OriginID/versions"
        }
        $QueryParameters = @{
            'validate' = $PSBoundParameters.Validate
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
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

