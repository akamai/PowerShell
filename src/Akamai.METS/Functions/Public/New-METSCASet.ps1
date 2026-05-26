function New-METSCASet {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $CASetName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Description,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

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
        $Path = "/mtls-edge-truststore/v2/ca-sets"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'caSetName' = $CASetName
            }
            if ($Description) { $Body['description'] = $Description }
        }

        $RequestParams = @{
            'Method'           = 'POST'
            'Path'             = $Path
            'Body'             = $Body
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
