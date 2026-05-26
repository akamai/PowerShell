function Get-AppSecSubscribers {
    [CmdletBinding(DefaultParameterSetName = 'Config name')]
    Param(
        [Parameter(ParameterSetName = 'Config name', Mandatory)]
        [string]
        $ConfigName,

        [Parameter(ParameterSetName = 'Config ID', Mandatory)]
        [int]
        $ConfigID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Feature,

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
        [string] $ConfigID, $null, $null = Expand-AppSecConfigDetails @PSBoundParameters
        $Path = "/appsec/v1/configs/$ConfigID/notification/subscription/$Feature"
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
        return $Response.Body.emails
    }
}
