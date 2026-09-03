
function Remove-EDNSProxyZoneManualFilterName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(ValueFromPipeline)]
        [string[]]
        $FilterNames,

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

    begin {
        $CollatedNames = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        $FilterNames | ForEach-Object {
            $CollatedNames.Add($_)
        }
    }
    
    end {
        $Path = "/config-dns/v2/proxies/$ProxyID/zones/$Name/manual-filter-names/manage"
        $Body = @{
            'delete' = $CollatedNames
        }
    
        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            QueryParameters  = $QueryParameters 
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
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
