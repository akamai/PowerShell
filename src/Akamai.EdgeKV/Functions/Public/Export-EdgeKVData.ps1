
function Export-EdgeKVData {
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
        $OutputFile,

        [Parameter()]
        [string]
        $GroupID,

        [Parameter()]
        [int]
        $MaxItems,

        [Parameter()]
        [switch]
        $ShowExpires,

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
        if ($GroupID) {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/groups/$GroupID/download"
        }
        else {
            $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID/download"
        }
        $QueryParameters = @{
            'maxItems'    = $PSBoundParameters.MaxItems
            'showExpires' = $PSBoundParameters.ShowExpires.IsPresent
        }
        $AdditionalHeaders = @{
            'accept' = 'text/csv'
        }

        $RequestParameters = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'QueryParameters'   = $QueryParameters
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
        }
        catch {
            throw $_
        }
        $Response.Body | Out-File $OutputFile -Encoding utf8
        Write-Host "Writing CSV content to " -NoNewline
        Write-Host -ForegroundColor Cyan $OutputFile
    }
}