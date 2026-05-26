function New-ClientListSubscription {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [string[]]
        $Recipients,
        
        [Parameter(Position = 1, Mandatory)]
        [string[]]
        $UniqueIDs,
        
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

    process {
        $Path = "/client-list/v1/notifications/subscribe"
        $Body = @{
            'recipients' = $Recipients
            'uniqueIds'  = $UniqueIDs
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
