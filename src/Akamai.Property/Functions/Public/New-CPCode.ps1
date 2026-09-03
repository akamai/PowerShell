function New-CPCode {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(ParameterSetName = 'Attributes', Mandatory) ]
        [string]
        $CPCodeName,

        [Parameter(ParameterSetName = 'Attributes', Mandatory) ]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $ContractId,

        [Parameter(Mandatory)]
        [string]
        $GroupId,

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
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'productId'  = $ProductID
                'cpcodeName' = $CPCodeName
            }
        }

        $Path = "/papi/v1/cpcodes"
        $QueryParameters = @{
            contractId = $ContractID
            groupId    = $GroupID
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($Response.Body.cpcodeLink -Match '\/cpcodes\/([^\?]+)') {
            $Response.Body | Add-Member -NotePropertyName 'cpcodeId' -NotePropertyValue $matches[1]
        }
        return $Response.Body
    }
}
