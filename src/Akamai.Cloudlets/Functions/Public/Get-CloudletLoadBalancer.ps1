function Get-CloudletLoadBalancer {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0)]
        [string]
        $OriginID,

        [Parameter(ParameterSetName = 'Get all')]
        [ValidateSet('APPLICATION_LOAD_BALANCER', 'CUSTOMER', 'NETSTORAGE')]
        [string]
        $Type,

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
        if ($OriginID) {
            $Path = "/cloudlets/api/v2/origins/$OriginID"
        }
        else {
            $Path = "/cloudlets/api/v2/origins"
        }
        $QueryParameters = @{
            'type' = $Type
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

