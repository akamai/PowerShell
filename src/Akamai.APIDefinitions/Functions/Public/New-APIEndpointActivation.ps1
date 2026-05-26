function New-APIEndpointActivation {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    [Alias('Deploy-APIEndpoint')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'Name & body')]
        [string]
        $APIEndpointName,

        [Parameter(Mandatory, ParameterSetName = 'ID & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & body')]
        [int]
        $APIEndpointID,

        [Parameter(Mandatory)]
        [string]
        $VersionNumber,

        [Parameter(Mandatory, ParameterSetName = 'Name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & attributes')]
        [string]
        $Notes,

        [Parameter(Mandatory, ParameterSetName = 'Name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & attributes')]
        [ValidateSet('Production', 'Staging', 'Both')]
        [string]
        $Networks,

        [Parameter(Mandatory, ParameterSetName = 'Name & attributes')]
        [Parameter(Mandatory, ParameterSetName = 'ID & attributes')]
        [string]
        $NotificationRecipients,

        [Parameter(Mandatory, ParameterSetName = 'Name & body', ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName = 'ID & body', ValueFromPipeline)]
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
        $APIEndpointID, $VersionNumber = Expand-APIEndpointDetails @PSBoundParameters
        $Path = "/api-definitions/v2/endpoints/$APIEndpointID/versions/$VersionNumber/activate"

        if ($PSCmdlet.ParameterSetName -eq "attributes") {
            if ($Networks -eq 'Production' -or $Networks -eq 'Staging') {
                $NetworksArray = @($Networks)
            }
            else {
                $NetworksArray = @('Staging', 'Production')
            }
            $NotificationArray = $NotificationRecipients -split ","

            $Body = @{
                'notes'                  = $Notes
                'notificationRecipients' = $NotificationArray
                'networks'               = $NetworksArray
            }
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
