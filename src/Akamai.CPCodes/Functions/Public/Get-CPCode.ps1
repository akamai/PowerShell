function Get-CPCode {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, ValueFromPipeline)]
        [int]
        $CPCodeID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ContractID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $GroupID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Get all')]
        [string]
        $Name,

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

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/cprg/v1/cpcodes/$CPCodeID"
        }
        else {
            $Path = "/cprg/v1/cpcodes"
            $QueryParameters = @{
                'contractId' = $ContractID
                'groupId'    = $GroupID
                'productId'  = $ProductID
                'cpcodeName' = $Name
            }
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
        if ($CPCodeID) {
            return $Response.Body
        }
        else {
            return $Response.Body.cpcodes
        }
    }
}

