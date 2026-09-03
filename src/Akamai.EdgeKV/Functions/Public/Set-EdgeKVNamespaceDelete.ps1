function Set-EdgeKVNamespaceDelete {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [DateTime]
        $ScheduledDeleteTime,

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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/status/scheduled-delete"
        $FormattedDate = $ScheduledDeleteTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $Body = @{
            'scheduledDeleteTime' = $FormattedDate
        }
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
        # Handle type variations in 5.1/7+
        if ($Response.Body.scheduledDeleteTime -is [string]) {
            $Response.body.scheduledDeleteTime = Get-Date $Response.Body.scheduledDeleteTime
        }
        return $Response.Body
    }
}
