function Get-NetworkListActivationStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('uniqueId')]
        [string]
        $NetworkListID,

        [Parameter(Mandatory)]
        [ValidateSet('PRODUCTION', 'STAGING')]
        [string]
        $Environment,

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
        $Path = "/network-list/v2/network-lists/$NetworkListId/environments/$Environment/status"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
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

