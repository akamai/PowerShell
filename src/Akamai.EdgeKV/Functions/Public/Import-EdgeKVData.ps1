
function Import-EdgeKVData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $NamespaceID,

        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $InputFile,

        [Parameter()]
        [switch]
        $DryRun,

        [Parameter()]
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
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/upload"
        $QueryParameters = @{
            'dryRun'   = $PSBoundParameters.DryRun.IsPresent
            'maxItems' = $PSBoundParameters.MaxItems
        }
        $Body = Get-Content -Raw -Path $InputFile
        $AdditionalHeaders = @{
            'content-type' = 'text/csv'
        }

        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'Body'              = $Body
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}