function Copy-PropertyInclude {
    [CmdletBinding(DefaultParameterSetName = 'Name & attributes')]
    Param(
        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [string]
        $ProductID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $RuleFormat,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory)]
        [ValidateSet('MICROSERVICES', 'COMMON_SETTINGS')]
        [string]
        $IncludeType,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory)]
        [string]
        $CloneIncludeName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('IncludeID')]
        [string]
        $CloneIncludeID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('IncludeVersion')]
        [string]
        $CloneIncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersionEtag,

        [Parameter(ParameterSetName = 'Body', Mandatory)]
        $Body,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

    process {
        $CloneIncludeID, $CloneIncludeVersion, $null, $null = Expand-PropertyIncludeDetails @PSBoundParameters

        $Path = "/papi/v1/includes"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'productId'   = $ProductID
                'includeName' = $Name
                'includeType' = $IncludeType
                'cloneFrom'   = @{
                    'includeId' = $CloneIncludeID
                    'version'   = $CloneIncludeVersion
                }
            }
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CloneIncludeVersionEtag) { $Body.cloneFrom['cloneFromVersionEtag'] = $CloneIncludeVersionEtag }
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

        try {
            # Make Request
            $Response = Invoke-AkamaiRequest @RequestParams
            if ($Response.Body.includeLink -Match '\/includes\/([^\?]+)') {
                $IncludeID = $Matches[1]
                $Response.Body | Add-Member -NotePropertyName 'includeId' -NotePropertyValue $IncludeID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -IncludeName $Name -IncludeID $IncludeID
                }
            }
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
