function New-Property {
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

        [Parameter(ParameterSetName = 'Name & attributes')]
        [string]
        $ClonePropertyName,

        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyID,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyVersion,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [string]
        $ClonePropertyVersionEtag,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $CopyHostnames,

        [Parameter(ParameterSetName = 'Name & attributes')]
        [Parameter(ParameterSetName = 'ID & attributes')]
        [switch]
        $UseHostnameBucket,

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
        $ClonePropertyID, $ClonePropertyVersion, $null, $null = Expand-PropertyDetails @PSBoundParameters

        $Path = "/papi/v1/properties"
        $QueryParameters = @{
            'contractId' = $ContractId
            'groupId'    = $GroupID
        }

        if ($PSCmdlet.ParameterSetName.Contains('attributes')) {
            $Body = @{
                'propertyName' = $Name
                'productId'    = $ProductID
            }
            $CloneFrom = @{}
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($CopyHostnames) { $CloneFrom['copyHostnames'] = $CopyHostnames.ToBool() }
            if ($ClonePropertyID) { $CloneFrom['propertyId'] = $ClonePropertyID }
            if ($ClonePropertyVersion) { $CloneFrom['version'] = $ClonePropertyVersion }
            if ($ClonePropertyVersionEtag) { $CloneFrom['cloneFromVersionEtag'] = $ClonePropertyVersionEtag }
            if ($CloneFromVersionEtag -or $CopyHostnames -or $ClonePropertyID -or $ClonePropertyVersion) { $Body['cloneFrom'] = $CloneFrom }
            if ($UseHostnameBucket) { $Body['useHostnameBucket'] = $true }
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
    
            if ($Response.Body.propertyLink -Match '\/properties\/([^\?]+)') {
                $PropertyID = $matches[1]
                $Response.Body | Add-Member -NotePropertyName 'propertyId' -NotePropertyValue $PropertyID
    
                # Add to data cache
                if ($AkamaiOptions.EnableDataCache) {
                    Set-AkamaiDataCache -PropertyName $Name -PropertyID $PropertyID
                }
            }
    
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
