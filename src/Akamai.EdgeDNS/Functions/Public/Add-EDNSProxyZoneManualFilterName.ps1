
function Add-EDNSProxyZoneManualFilterName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]
        $ProxyID,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [switch]
        $AddSkipExisting,

        [Parameter()]
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
        $QueryParameters = @{ 
            'addSkipExisting' = $PSBoundParameters.AddSkipExisting.IsPresent
        }
        $Body = @{
            'add' = $CollatedNames
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
