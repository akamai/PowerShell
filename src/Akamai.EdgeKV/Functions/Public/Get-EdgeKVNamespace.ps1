function Get-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(ValueFromPipeline)]
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
        if ($NamespaceID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces"
        }
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
        if ($NamespaceID) {
            return $Response.Body
        }
        else {
            return $Response.Body.namespaces
        }
    }
}

