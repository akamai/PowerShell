function New-NetworkListSubscription {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string[]]
        $Recipients,

        [Parameter(Mandatory)]
        [Alias('UniquedIDs')]
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

    begin {}

    process {
        $Path = "/network-list/v2/notifications/subscribe"
        # Backward compat option for Recipients and UniquedIDs as string
        if ($Recipients.Count -eq 1 -and $Recipients[0].Contains(',')) {
            $Recipients = $Recipients[0] -split ',[ ]*'
        }
        if ($UniqueIDs.Count -eq 1 -and $UniqueIDs[0].Contains(',')) {
            $UniqueIDs = $UniqueIDs[0] -split ',[ ]*'
        }
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

    end {}
    
}

