function New-CloudletLoadBalancerActivation {
    [CmdletBinding()]
    [Alias('Deploy-CloudletLoadBalancer')]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $OriginID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter()]
        [switch]
        $Async,
        
        [Parameter()]
        [switch]
        $DryRun,

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
        $Path = "/cloudlets/api/v2/origins/$OriginID/activations"
        $Version = Expand-CloudletLoadBalancerDetails -OriginID $OriginID -Version $Version -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        $QueryParameters = @{
            'async' = $Async.IsPresent
        }
        $Body = @{
            'network' = $Network.ToUpper()
            'version' = [int] $Version
            'dryrun'  = $DryRun.IsPresent
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
