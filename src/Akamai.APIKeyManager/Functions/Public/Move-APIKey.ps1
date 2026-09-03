function Move-APIKey {
    [CmdletBinding(DefaultParameterSetName = 'Existing')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64[]]
        $KeyIds,

        [Parameter(Mandatory, ParameterSetName = 'Existing')]
        [int]
        $DestinationCollectionID,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $NewCollectionName,

        [Parameter(ParameterSetName = 'New')]
        [string]
        $NewCollectionDescription,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [string]
        $ContractID,

        [Parameter(Mandatory, ParameterSetName = 'New')]
        [int]
        $GroupID,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIds) {
            $CollatedKeys.Add($KeyId)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/move"
        $Body = @{
            'keyIds' = $KeyIDs
        }
        if ($PSCmdlet.ParameterSetName -eq 'Existing') {
            $Body['destinationCollectionId'] = $DestinationCollectionID
        }
        else {
            $Body['newCollectionName'] = $NewCollectionName
            $Body['newCollectionContractId'] = $ContractID
            $Body['newCollectionGroupId'] = $GroupID
            if ($NewCollectionDescription) {
                $Body['newCollectionDescription'] = $NewCollectionDescription
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
        return $Response.Body

    }

}

