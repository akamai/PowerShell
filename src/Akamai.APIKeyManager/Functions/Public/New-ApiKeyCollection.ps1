function New-APIKeyCollection {
    [CmdletBinding(DefaultParameterSetName = 'Body')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $CollectionName,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $CollectionDescription,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Body')]
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

    begin {}

    process {
        $Path = "/apikey-manager-api/v2/collections"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'collectionName'        = $CollectionName
                'collectionDescription' = $CollectionDescription
                'contractId'            = $ContractID
                'groupId'               = $GroupID
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

    end {}
}

