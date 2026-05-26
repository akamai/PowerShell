function Set-MSLOrigin {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('ID')]
        [int]
        $OriginID,

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

    process {
        $Path = "/config-media-live/v2/msl-origin/origins/$OriginID"
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
        return $Response.Body
    }  
}