function Get-EdgeKVItem {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get one')]
        [string]
        $ItemID,

        [Parameter()]
        [string]
        $SandboxID,

        [Parameter(ParameterSetName = 'Get all')]
        [int]
        $MaxItems,

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
        if ($ItemID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/items/$ItemID"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID"
        }
        $QueryParameters = @{
            'sandboxId' = $SandboxID
            'maxItems'  = $PSBoundParameters.MaxItems
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

