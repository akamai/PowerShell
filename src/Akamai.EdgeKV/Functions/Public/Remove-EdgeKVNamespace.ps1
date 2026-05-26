function Remove-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'DELETE'
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
