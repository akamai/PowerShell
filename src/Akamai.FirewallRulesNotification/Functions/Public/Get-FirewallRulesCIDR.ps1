function Get-FirewallRulesCIDR {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]
        $EffectiveDateGt,

        [Parameter()]
        [ValidateSet('add', 'update', 'delete')]
        [string]
        $LastAction,

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
        $Path = "/firewall-rules-manager/v1/cidr-blocks"
        $QueryParameters = @{
            'effectiveDateGt' = $EffectiveDateGt
            'lastAction'      = $LastAction
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

