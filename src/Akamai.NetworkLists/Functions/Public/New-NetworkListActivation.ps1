function New-NetworkListActivation {
    [CmdletBinding()]
    [Alias('Deploy-NetworkList')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('uniqueId')]
        [string]
        $NetworkListID,

        [Parameter(Mandatory)]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $Environment,

        [Parameter()]
        [string]
        $Comments,

        [Parameter()]
        [string[]]
        $NotificationRecipients,

        [Parameter()]
        [string]
        $SiebelTicketID,

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
        $Path = "/network-list/v2/network-lists/$NetworkListId/environments/$Environment/activate"
        $Body = @{}
        if ($Comments) {
            $Body['comments'] = $Comments
        }
        if ($NotificationRecipients) {
            if ($NotificationRecipients.Count -eq 1 -and $NotificationRecipients[0].Contains(',')) {
                $NotificationRecipients = $NotificationRecipients[0] -split ',[ ]*'
            }
            $Body['notificationRecipients'] = $NotificationRecipients
        }
        if ($SiebelTicketID) {
            $Body['siebelTicketId'] = $SiebelTicketID
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
