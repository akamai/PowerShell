function Get-MSLOrigin {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $OriginID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $EncoderLocation,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $CPCode,

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
        if ($OriginID) {
            $Path = "/config-media-live/v2/msl-origin/origins/$OriginID"
        }
        else {
            $Path = "/config-media-live/v2/msl-origin/origins"
        }
        $QueryParameters = @{
            'encoderLocation' = $EncoderLocation
            'cpcode'          = $CPCode
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
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
