function Remove-AppSecCVESubscription {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'Get all')]
        [switch]
        $All,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'CVE IDs')]
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
        $Path = "/appsec/v1/cves/unsubscribe"
        $QueryParameters = @{
            'Get all' = $PSBoundParameters.All.IsPresent
        }

        $Body = @{}
        if ($PSCmdlet.ParameterSetName -eq 'CVE IDs') {
            if ($CollatedCVEIDs) {
                $Body['cveIds'] = $CollatedCVEIDs
            }
            else {
                Write-Debug "No CVE IDs were provided for unsubscription. Nothing to do."
                return
            }
        }
        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters
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
