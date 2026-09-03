function New-AppSecCVESubscription {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $CVEID,

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
        $CollatedCVEIDs = New-Object System.Collections.Generic.List[string]
    }

    process {
        $CVEID | ForEach-Object {
            $CollatedCVEIDs.Add($_)
        }
    }

    end {
        $Path = "/appsec/v1/cves/subscribe"
        $Body = @{
            'cveIds' = $CollatedCVEIDs
        }
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            return $Response.Body.cveIds
        }
        catch {
            throw $_
        }
    }
}
