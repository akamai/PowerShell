
function Find-EDNSChangeList {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string[]]
        $Zone,

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
        $CollatedZones = New-Object -TypeName System.Collections.Generic.List[string]
    }

    process {
        if ($Zone.count -gt 1) {
            $CollatedZones.AddRange($Zone)
        }
        else {
            $CollatedZones.Add($Zone)
        }
    }

    end {
        $Path = "/config-dns/v2/changelists/search"
        $Body = @{
            'zones' = $CollatedZones
        }
        if ($Comment) {
            $Body.comment = $Comment
        }
        $RequestParameters = @{
            Path             = $Path
            Method           = 'POST'
            Body             = $Body
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
            Debug            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.changeLists
        }
        catch {
            throw $_
        }
    }

}
