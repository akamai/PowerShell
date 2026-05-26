function Copy-METSCASet {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'ID', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]
        $CASetID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('version')]
        [int]
        $CloneFromVersion,

        [Parameter(Mandatory)]
        [string]
        $NewCASetName,

        [Parameter()]
        [string]
        $Description,

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
        $CASetID = Expand-METSCASetDetails @PSBoundParameters
        $Path = "/mtls-edge-truststore/v2/ca-sets/$CASetID/clone"
        $Body = @{
            'caSetName' = $NewCASetName
        }
        if ($Description) { $Body['description'] = $Description }
        $QueryParameters = @{
            'cloneFromVersion' = $PSBoundParameters.CloneFromVersion
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }

        try {
            # Make request
            $Response = Invoke-AkamaiRequest @RequestParams

            # Add to data cache
            if ($AkamaiOptions.EnableDataCache) {
                Set-AkamaiDataCache -METSCaSetName $Response.body.caSetName -METSCaSetID $Response.body.caSetId
            }

            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}