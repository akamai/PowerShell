function New-IVMPolicySet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('US', 'EMEA', 'ASIA', 'AUSTRALIA', 'JAPAN', 'CHINA')]
        [string]
        $Region,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [ValidateSet('IMAGE', 'VIDEO')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes')]
        [Object]
        $DefaultPolicy,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
        $Body,

        [Parameter()]
        [string]
        $ContractID,

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
        $AdditionalHeaders = @{}
        $Path = "/imaging/v2/policysets"

        if ($ContractID -ne '') {
            $AdditionalHeaders['Contract'] = $ContractID
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'   = $Name
                'region' = $Region
                'type'   = $Type
            }
            if ($DefaultPolicy) {
                $Body.defaultPolicy = $DefaultPolicy
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
