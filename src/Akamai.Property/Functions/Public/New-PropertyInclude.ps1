function New-PropertyInclude {
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

        [Parameter(ParameterSetName = 'Name & attributes')]
        [string]
        $CloneIncludeName,

        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $CloneIncludeVersionEtag,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
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
            }
            $CloneFrom = @{}
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CloneIncludeID) { $CloneFrom['includeId'] = $CloneIncludeID }
            if ($CloneIncludeVersion) { $CloneFrom['version'] = $CloneIncludeVersion }
            if ($CloneIncludeVersionEtag) { $CloneFrom['cloneFromVersionEtag'] = $CloneIncludeVersionEtag }
            if ($CloneFromVersionEtag -or $CopyHostnames -or $CloneIncludeID -or $CloneIncludeVersion) { $Body['cloneFrom'] = $CloneFrom }
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
