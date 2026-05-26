function Get-MSLCPCode {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet('INGEST', 'DELIVERY', 'STORAGE')]
        [string]
        $Type,

        [Parameter()]
        [switch]
        $Unused,

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
        $Path = "/config-media-live/v2/msl-origin/cpcodes"
        $QueryParameters = @{
            'type'   = $Type
            'unused' = $PSBoundParameters.Unused
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
