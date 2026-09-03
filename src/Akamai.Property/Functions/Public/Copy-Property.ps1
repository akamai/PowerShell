function Copy-Property {
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
        [string]
        $ClonePropertyName,

        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyID')]
        [string]
        $ClonePropertyID,

        [Parameter(ParameterSetName = 'Name & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ID & attributes', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PropertyVersion')]
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
                'cloneFrom'    = @{
                    'propertyId' = $ClonePropertyID
                    'version'    = $ClonePropertyVersion
                }
            }
            if ($RuleFormat) { $Body['ruleFormat'] = $RuleFormat }
            if ($UseHostnameBucket) { $Body['useHostnameBucket'] = $true }
            if ($CopyHostnames) { $Body.CloneFrom['copyHostnames'] = $CopyHostnames.ToBool() }
            if ($ClonePropertyVersionEtag) { $Body.CloneFrom['cloneFromVersionEtag'] = $ClonePropertyVersionEtag }
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
