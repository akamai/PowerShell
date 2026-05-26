function Remove-EdgeWorkerVersion {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipelineByPropertyName)]
        [int]
        $EdgeWorkerID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Version,

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
        $EdgeWorkerID, $Version, $null = Expand-EdgeWorkerDetails @PSBoundParameters
        $Path = "/edgeworkers/v1/ids/$EdgeWorkerID/versions/$Version"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
            'InputFile'        = $CodeBundle
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
