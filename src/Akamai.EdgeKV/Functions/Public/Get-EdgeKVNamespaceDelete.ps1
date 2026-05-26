function Get-EdgeKVNamespaceDelete {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

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
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
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
