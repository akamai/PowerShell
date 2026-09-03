function Set-FirewallRulesSubscription {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,
        
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

    Begin {
        $CollatedSubscriptions = New-Object -TypeName System.Collections.Generic.List[object]
    }
    Process {
        if ($Body -is 'PSCustomObject' -or $Body -is 'HashTable') {
            $CollatedSubscriptions.Add($Body)
        }
    }
    End {
        if ($AccountSwitchKey) {
            throw "This endpoint can only be run for your own user. As such Account Switching does not apply"
        }
        
        $Path = "/firewall-rules-manager/v1/subscriptions"

        # Construct body 
        if ($CollatedSubscriptions.Count -gt 0) {
            $Body = @{
                'subscriptions' = $CollatedSubscriptions
            }
        }

        # Handle body format
        $Body = Get-BodyObject -Source $Body
        if ($Body -is 'Array' -or -not $Body.subscriptions) {
            $Body = [PSCustomObject] @{
                'subscriptions' = $Body
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
        return $Response.Body.subscriptions
    }

}

