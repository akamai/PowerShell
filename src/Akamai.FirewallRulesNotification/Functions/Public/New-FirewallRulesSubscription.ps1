function New-FirewallRulesSubscription {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int]
        $ServiceID,
        
        [Parameter(Mandatory)]
        [string]
        $Email,
        
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
        if ($AccountSwitchKey) {
            throw "This endpoint can only be run for your own user. As such Account Switching does not apply"
        }
        
        $Path = "/firewall-rules-manager/v1/subscriptions"
        $Body = @(
            @{
                'op'        = 'add'
                'path'      = '/'
                'serviceId' = $ServiceID
                'email'     = $Email
            }
        )
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PATCH'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.subscriptions
    }
}

