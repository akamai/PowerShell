function Remove-MSLStream {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ID')]
        [int]
        $StreamID,

        [Parameter()]
        [switch]
        $PurgeContent,

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

        $Path = "/config-media-live/v2/msl-origin/streams/$StreamID"
        $QueryParameters = @{
            'purgeContent' = $PSBoundParameters.PurgeContent
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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