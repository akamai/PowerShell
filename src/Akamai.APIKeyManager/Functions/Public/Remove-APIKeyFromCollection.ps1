function Remove-APIKeyFromCollection {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $CollectionIDs,
        
        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int64[]]
        $KeyIDs,

        [Parameter(ParameterSetName = 'Body', ValueFromPipeline, Mandatory)]
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
        $Path = "/apikey-manager-api/v2/keys/unassign"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'collectionIds' = $CollectionIDs
                'keyIds'        = $KeyIDs
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.keys
    }
}

