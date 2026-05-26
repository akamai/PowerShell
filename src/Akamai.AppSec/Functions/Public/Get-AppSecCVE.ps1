function Get-AppSecCVE {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $CVEID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ModifiedAfter,

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
        if ($CVEID) {
            $Path = "/appsec/v1/cves/$CVEID"
        }
        else {
            $Path = "/appsec/v1/cves"
            $QueryParameters = @{
                'modifiedAfter' = $ModifiedAfter
            }
        }

        $RequestParameters = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        try {
            $Response = Invoke-AkamaiRequest @RequestParameters
            if ($CVEID) {
                return $Response.Body
            }
            else {
                return $Response.Body.cves
            }
        }
        catch {
            throw $_
        }
    }
}
