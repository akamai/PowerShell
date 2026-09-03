function Get-CloudAccessKey {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $AccessKeyUID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $VersionGUID,

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
        if ($AccessKeyUID) {
            $Path = "/cam/v1/access-keys/$AccessKeyUID"
        }
        else {
            $Path = "/cam/v1/access-keys"
        }
        $QueryParameters = @{
            'versionGuid' = $VersionGUID
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
        if ($PSCmdlet.ParameterSetName -eq 'Get all') {
            return $Response.Body.accessKeys
        }
        else {
            return $Response.Body
        }
    }
}
