
function Convert-EDNSZoneToAlias {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Zone,
        
        [Parameter(Mandatory)]
        [string]
        $TargetZoneName,
        
        [Parameter()]
        [string]
        $Comment,

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
        $Path = "/config-dns/v2/zones/convert-requests/alias"
        $Body = @{
            'targetZoneName' = $TargetZoneName
            'zoneList'       = $CollatedZones
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
            return $Response.Body
        }
        catch {
            throw $_
        }
    }

}
