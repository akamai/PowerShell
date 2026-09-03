function New-ClientListDeactivation {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    [Alias('Disable-ClientList')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'Name & body', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory)]
        [string]
        $ListID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $Comments,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string[]]
        $NotificationRecipients,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $SiebelTicketID,

        [Parameter(ParameterSetName = 'Name & body', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ID & body', Mandatory, ValueFromPipeline)]
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

    process {
        $ListID, $null = Expand-ClientListDetails @PSBoundParameters
        $Path = "/client-list/v2/lists/$ListID/activations"
        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'action' = 'DEACTIVATE'
            }
            if ($Comments) { $Body['comments'] = $Comments }
            if ($NotificationRecipients) { $Body['notificationRecipients'] = $NotificationRecipients }
            if ($SiebelTicketID) { $Body['siebelTicketId'] = $SiebelTicketID }
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
