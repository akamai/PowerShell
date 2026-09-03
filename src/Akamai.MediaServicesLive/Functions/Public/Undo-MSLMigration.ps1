function Undo-MSLMigration {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int[]]
        $StreamIDs,

        [Parameter(Mandatory)]
        [string]
        $MSL5APIKey,

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
        $Path = "/config-media-live/v2/msl-origin/streams/migrate/revert"
        $AdditionalHeaders = @{
            'X-MSL5-API-Key' = $MSL5APIKey
        }
        $Body = @{
            'streamIds' = $StreamIDs
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }   
}