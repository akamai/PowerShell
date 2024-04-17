Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Property/Akamai.Property.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:SafeCommonParams = @{
    EdgeRCFile = $EdgeRCFile
    Section    = $Section
}
$Script:UnsafeCommonParams = @{
    EdgeRCFile = $SafeEdgeRcFile
    Section    = $Section
}
$Script:TestContract = $env:PesterContractID
$Script:TestGroupName = $env:PesterGroupName
$Script:TestGroupID = $env:PesterGroupID
$Script:TestPropertyName = 'akamaipowershell-testing'
$Script:TestIncludeName = 'akamaipowershell-include'
$Script:AdditionalHostname = 'new.host'
$Script:TestBucketPropertyName = 'akamaipowershell-bucket'
$Script:TestProductName = 'Fresca'
$Script:TestRuleFormat = 'v2022-06-28'
$Script:BulkActivateJSON = @"
{"defaultActivationSettings":{"acknowledgeAllWarnings":true,"useFastFallback":false,"fastPush":true,"notifyEmails":["you@example.com","them@example.com"]},"activatePropertyVersions":[{"propertyId":"prp_1","propertyVersion":2,"network":"STAGING","note":"Some activation note"},{"propertyId":"prp_15","propertyVersion":3,"network":"STAGING","note":"Sample activation","notifyEmails":["someoneElse@somewhere.com"]},{"propertyId":"prp_3","propertyVersion":11,"network":"PRODUCTION","acknowledgeAllWarnings":false,"note":"created by xyz","acknowledgeWarnings":["msg_123","msg_234"]}]}
"@
$Script:BulkPatchJSON = @"
{"patchPropertyVersions":[{"propertyId":"785068","propertyVersion":1,"patches":[{"op":"replace","path":"/rules/behaviors/0/options/hostname","value":"origin.example.com"}]},{"propertyId":"785069","propertyVersion":1,"patches":[{"op":"remove","path":"/rules/children/0"}]},{"propertyId":"785070","propertyVersion":1,"patches":[{"op":"add","path":"/rules/behaviors/1","value":{"name":"autoDomainValidation","options":{"autodv":""}}}]}]}
"@
$Script:BulkVersionJSON = @"
{"createPropertyVersions":[{"createFromVersion":1,"propertyId":"0001"},{"createFromVersion":9,"propertyId":"0002"}]}
"@

Describe 'Safe PAPI Tests' {
    ### Get-AccountID
    $Script:AccountID = Get-AccountID @SafeCommonParams
    it 'Get-AccountID gets an account ID' {
        $AccountID | Should -Not -BeNullOrEmpty
    }

    ### Get-Contract
    $Script:Contracts = Get-PropertyContract @SafeCommonParams
    it 'Get-Contract lists contracts' {
        $Contracts[0].contractId | Should -Not -BeNullOrEmpty
    }

    ### Get-Product
    $Script:Products = Get-Product -ContractId $TestContract @SafeCommonParams
    it 'Get-Product lists products' {
        $Products[0].productId | Should -Not -BeNullOrEmpty
    }

    ### Get-Group
    $Script:Groups = Get-Group @SafeCommonParams
    it 'Get-Group lists groups' {
        $Groups.count | Should -BeGreaterThan 0
    }

    ### Get-Group by ID
    $Script:GroupByID = Get-Group -GroupID $TestGroupID @SafeCommonParams
    it 'Get-Group by ID gets a group' {
        $GroupByID | Should -Not -BeNullOrEmpty
    }

    ### Get-Group by name
    $Script:GroupByName = Get-Group -GroupName $TestGroup.groupName @SafeCommonParams
    it 'Get-Group by name gets a group' {
        $GroupByName | Should -Not -BeNullOrEmpty
    }
    
    ### Get-TopLevelGroup
    $Script:TopLevelGroups = Get-TopLevelGroup @SafeCommonParams
    it 'Get-TopLevelGroup lists groups' {
        $TopLevelGroups[0].groupId | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyCPCode
    $Script:CPCodes = Get-PropertyCPCode -GroupId $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-PropertyCPCode should not be null' {
        $CPCodes | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyCPCode by CpCode
    $Script:CPCode = Get-PropertyCPCode -CPCode $CPCodes[0].cpcodeId -GroupId $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-PropertyCPCode should not be null' {
        $CPCode | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyEdgeHostname
    $Script:EdgeHostnames = Get-PropertyEdgeHostname -GroupId $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-PropertyEdgeHostname should not be null' {
        $EdgeHostnames | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyEdgeHostname
    $Script:EdgeHostname = Get-PropertyEdgeHostname -EdgeHostnameID $EdgeHostnames[0].EdgeHostnameId -GroupId $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-PropertyEdgeHostname should not be null' {
        $EdgeHostname | Should -Not -BeNullOrEmpty
    }

    ### Get-CustomBehavior
    $Script:CustomBehaviors = Get-CustomBehavior @SafeCommonParams
    it 'Get-CustomBehavior should not be null' {
        $CustomBehaviors | Should -Not -BeNullOrEmpty
    }

    ### Get-CustomBehavior by ID
    $Script:CustomBehavior = Get-CustomBehavior -BehaviorId $CustomBehaviors[0].behaviorId @SafeCommonParams
    it 'Get-CustomBehavior should not be null' {
        $CustomBehavior | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyClientSettings
    $Script:ClientSettings = Get-PropertyClientSettings @SafeCommonParams
    it 'Get-PropertyClientSettings should not be null' {
        $ClientSettings | Should -Not -BeNullOrEmpty
    }

    ### Set-PropertyClientSettings
    $Script:ClientSettings = Set-PropertyClientSettings -RuleFormat $ClientSettings.ruleFormat -UsePrefixes $ClientSettings.usePrefixes @SafeCommonParams
    it 'Set-PropertyClientSettings should not be null' {
        $ClientSettings | Should -Not -BeNullOrEmpty
    }
    
    ### Get-Property
    $Script:Properties = Get-Property -GroupID $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-Property lists properties' {
        $Properties.count | Should -BeGreaterThan 0
    }

    ### Find-Property
    $Script:FoundProperty = Find-Property -PropertyName $TestPropertyName -Latest @SafeCommonParams
    it 'Find-Property finds properties' {
        $FoundProperty | Should -Not -BeNullOrEmpty
    }

    ### Expand-PropertyDetails
    $Script:ExpandedPropertyID, $Script:ExpandedPropertyVersion, $null, $null = Expand-PropertyDetails -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Expand-PropertyDetails returns the correct data' {
        $ExpandedPropertyID | Should -Be $FoundProperty.propertyId
        $ExpandedPropertyVersion | Should -Be $FoundProperty.propertyVersion
    }

    ### Get-Property by name
    $Script:PropertyByName = Get-Property -PropertyName $TestPropertyName @SafeCommonParams
    it 'Get-Property finds properties by name' {
        $PropertyByName | Should -Not -BeNullOrEmpty
    }

    ### Get-Property by ID
    $Script:PropertyByID = Get-Property -PropertyID $FoundProperty.propertyId @SafeCommonParams
    it 'Get-Property finds properties by name' {
        $PropertyByID | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyVersion using specific
    $Script:PropertyVersion = Get-PropertyVersion -PropertyID $FoundProperty.propertyId -PropertyVersion $FoundProperty.propertyVersion @SafeCommonParams
    it 'Get-PropertyVersion finds specified version' {
        $PropertyVersion | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyVersion using "latest"
    $Script:PropertyVersion = Get-PropertyVersion -PropertyID $FoundProperty.propertyId -PropertyVersion 'latest' @SafeCommonParams
    it 'Get-PropertyVersion finds "latest" version' {
        $PropertyVersion | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyRules to variable
    $Script:Rules = Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Get-PropertyRules returns rules object' {
        $Rules | Should -BeOfType [PSCustomObject]
        $Rules.rules | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyRules to file
    Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputToFile -OutputFileName rules.json @SafeCommonParams
    it 'Get-PropertyRules creates json file' {
        'rules.json' | Should -Exist
    }

    <#
    ### Get-PropertyRules to existing file fails
    it 'Get-PropertyRules fails without -Force if file exists' {
        { Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputToFile -OutputFileName temp.json @SafeCommonParams } | Should -Throw
    }
    #>

    ### Get-PropertyRules to snippets
    Get-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest -OutputSnippets -OutputDirectory snippets @SafeCommonParams
    it 'Get-PropertyRules creates expected files' {
        'snippets\main.json' | Should -Exist
    }

    ### Merge-PropertyRules creates output file
    Merge-PropertyRules -SourceDirectory snippets -OutputToFile -OutputFileName snippets.json
    it 'Merge-PropertyRules creates expected json file' {
        'snippets.json' | Should -Exist
    }

    ### Merge-PropertyRules creates custom object
    $Script:MergedRules = Merge-PropertyRules -SourceDirectory snippets
    it 'Merge-PropertyRules returns rules object' {
        $MergedRules | Should -BeOfType [PSCustomObject]
        $MergedRules.rules | Should -Not -BeNullOrEmpty
    }

    ### New-PropertyVersion
    $Script:NewPropertyVersion = New-PropertyVersion -PropertyID $FoundProperty.propertyId -CreateFromVersion $PropertyVersion.propertyVersion @SafeCommonParams
    it 'New-PropertyVersion does not error' {
        $NewPropertyVersion | Should -Not -BeNullOrEmpty
    }

    ### Set-PropertyRules via pipeline
    $Script:Rules = $Rules | Set-PropertyRules -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Set-PropertyRules returns rules object' {
        $Rules | Should -BeOfType PSCustomObject
        $Rules.rules | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyHostnames
    $Script:PropertyHostnames = Get-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Get-PropertyHostname should not be null' {
        $PropertyHostnames | Should -Not -BeNullOrEmpty
    }

    ### Set-PropertyHostname by pipeline
    $Script:SetPropertyHostnamesByPipeline = $PropertyHostnames | Set-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Set-PropertyHostname works via pipeline' {
        $SetPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
    }

    ### Set-PropertyHostname by param
    $Script:PropertyHostnamesByParam = Set-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest -Body $PropertyHostnames @SafeCommonParams
    it 'Set-PropertyHostname works via param' {
        $PropertyHostnamesByParam | Should -Not -BeNullOrEmpty
    }

    ### Add-PropertyHostname via param
    $HostnameToAdd = @{ 
        cnameType = "EDGE_HOSTNAME"
        cnameFrom = $AdditionalHostname
        cnameTo   = $PropertyHostnames[0].cnameTo
    }
    $Script:AddPropertyHostnamesByParam = Add-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest -NewHostnames $HostnameToAdd @SafeCommonParams
    it 'Add-PropertyHostname works via param' {
        $AddPropertyHostnamesByParam | Should -Not -BeNullOrEmpty
    }

    ### Remove-PropertyHostnames
    $Script:PropertyHostnames = Remove-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest -HostnamesToRemove $AdditionalHostname @SafeCommonParams
    it 'Remove-PropertyHostname does not error' {
        $PropertyHostnames | Should -Not -BeNullOrEmpty
    }

    ### Add-PropertyHostname via pipeline
    $Script:AddPropertyHostnamesByPipeline = @($HostnameToAdd) | Add-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest @SafeCommonParams
    it 'Add-PropertyHostname works via pipeline' {
        $AddPropertyHostnamesByPipeline | Should -Not -BeNullOrEmpty
    }
    # Repeat removal to return hostnames to previous
    $Script:PropertyHostnames = Remove-PropertyHostname -PropertyName $TestPropertyName -PropertyVersion latest -HostnamesToRemove $AdditionalHostname  @SafeCommonParams

    ### Get-RuleFormat
    $Script:RuleFormats = Get-RuleFormat @SafeCommonParams
    it 'Get-RuleFormat returns results' {
        $RuleFormats | Should -Not -BeNullOrEmpty
    }
    
    ### Get-RuleFormatSchema
    $Script:RuleFormat = Get-RuleFormatSchema -ProductID Fresca -RuleFormat latest @SafeCommonParams
    it 'Get-RuleFormatSchema returns the correct data' {
        $RuleFormat.properties | Should -Not -BeNullOrEmpty
    }

    ### New-PropertyActivation
    $Script:Activation = New-PropertyActivation -PropertyName $TestPropertyName -PropertyVersion latest -Network Staging -NotifyEmails "mail@example.com" @SafeCommonParams
    it 'New-PropertyActivation returns activationlink' {
        $Activation.activationLink | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyActivation by ID
    # Sanitize activation ID from previous response
    $Script:ActivationID = ($Activation.activationLink -split "/")[-1]
    if ($Script:ActivationID.contains("?")) {
        $Script:ActivationID = $Script:ActivationID.Substring(0, $ActivationID.IndexOf("?"))
    }
    $Script:ActivationResult = Get-PropertyActivation -PropertyName $TestPropertyName -ActivationID $ActivationID @SafeCommonParams
    it 'Get-PropertyActivation finds the correct activation' {
        $ActivationResult[0].activationId | Should -Be $ActivationID
    }

    ### Get-PropertyActivation
    $Script:Activations = Get-PropertyActivation -PropertyName $TestPropertyName @SafeCommonParams
    it 'Get-PropertyActivation returns a list' {
        $Activations[0].activationId | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    ### New-PropertyInclude
    $Script:NewInclude = New-PropertyInclude -Name $TestIncludeName -ProductID $TestProductName -GroupID $TestGroupID -RuleFormat $TestRuleFormat -IncludeType MICROSERVICES -ContractId $TestContract @SafeCommonParams
    it 'New-PropertyInclude creates an include' {
        $NewInclude.includeLink | Should -Not -BeNullOrEmpty
    }
    $Script:NewIncludeID = $NewInclude.includeLink.Replace('/papi/v1/includes/', '').Replace('inc_', '')
    $Script:NewIncludeID = [int] ($NewIncludeID.SubString(0, $NewIncludeID.IndexOf('?')))

    ### Expand-PropertyIncludeDetails
    $Script:ExpandedIncludeID, $Script:ExpandedIncludeVersion, $null, $null = Expand-PropertyIncludeDetails -IncludeName $TestIncludeName -IncludeVersion latest @SafeCommonParams
    it 'Expand-PropertyIncludeDetails returns the correct data' {
        $ExpandedIncludeID | Should -Be $NewIncludeID
        $ExpandedIncludeVersion | Should -Be 1
    }

    ### Get-PropertyInclude
    $Script:Includes = Get-PropertyInclude -GroupID $TestGroupID -ContractId $TestContract @SafeCommonParams
    it 'Get-PropertyInclude returns a list' {
        $Includes[0].includeId | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyInclude by ID
    $Script:IncludeByID = Get-PropertyInclude -IncludeID $NewIncludeID @SafeCommonParams
    it 'Get-PropertyInclude returns the correct data' {
        $IncludeByID.includeName | Should -Be $TestIncludeName
    }

    ### Get-PropertyInclude by name
    $Script:Include = Get-PropertyInclude -IncludeName $TestIncludeName @SafeCommonParams
    it 'Get-PropertyInclude returns the correct data' {
        $Include.includeName | Should -Be $TestIncludeName
    }

    ### Get-PropertyIncludeRules
    $Script:IncludeRules = Get-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 @SafeCommonParams
    it 'Get-PropertyIncludeRules returns the correct data' {
        $IncludeRules.includeName | Should -Be $TestIncludeName
    }

    ### Set-PropertyIncludeRules by pipeline
    $Script:SetIncludeRulesByPipeline = ( $IncludeRules | Set-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 @SafeCommonParams)
    it 'Set-PropertyIncludeRules by pipeline updates correctly' {
        $SetIncludeRulesByPipeline.includeName | Should -Be $TestIncludeName
    }

    ### Set-PropertyIncludeRules by body
    $Script:SetIncludeRulesByBody = Set-PropertyIncludeRules -IncludeID $NewIncludeID -IncludeVersion 1 -Body $IncludeRules @SafeCommonParams
    it 'Set-PropertyIncludeRules by body updates correctly' {
        $SetIncludeRulesByBody.includeName | Should -Be $TestIncludeName
    }

    ### Get-PropertyIncludeRules
    Get-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion latest -OutputSnippets -OutputDir includesnippets @SafeCommonParams
    it 'Get-PropertyIncludeRules creates expected files' {
        'includesnippets\main.json' | Should -Exist
    }

    ### Set-PropertyIncludeRules
    $Script:SetIncludeRulesSnippets = Set-PropertyIncludeRules -IncludeName $TestIncludeName -IncludeVersion 1 -InputDirectory includesnippets @SafeCommonParams
    it 'Set-PropertyIncludeRules updates successfully' {
        $SetIncludeRulesSnippets.includeName | Should -Be $TestIncludeName
    }

    ### Get-PropertyIncludeVerions
    $Script:IncludeVersions = Get-PropertyIncludeVersion -IncludeID $NewIncludeID @SafeCommonParams
    it 'Get-PropertyIncludeVerion returns the correct data' {
        $IncludeVersions[0].includeVersion | Should -Not -BeNullOrEmpty
    }

    ### New-PropertyIncludeVersion
    $Script:NewIncludeVersion = New-PropertyIncludeVersion -IncludeID $NewIncludeID -CreateFromVersion 1 @SafeCommonParams
    it 'New-PropertyIncludeVersion creates a new version' {
        $NewIncludeVersion.versionLink | Should -Match $NewIncludeID
    }

    ### Remove-PropertyInclude
    $Script:RemoveInclude = Remove-PropertyInclude -IncludeID $NewIncludeID @SafeCommonParams
    it 'Remove-PropertyInclude completes successfully' {
        $RemoveInclude.message | Should -Be "Deletion Successful."
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    ### Get-BucketActivation
    $Script:BucketActivations = Get-BucketActivation -PropertyName $TestBucketPropertyName @SafeCommonParams
    it 'Get-BucketActivation returns a list' {
        $BucketActivations[0].hostnameActivationId | Should -Not -BeNullOrEmpty
    }

    ### Get-BucketActivation
    $Script:BucketActivation = Get-BucketActivation -PropertyName $TestBucketPropertyName -HostnameActivationID $BucketActivations[0].hostnameActivationId @SafeCommonParams
    it 'Get-BucketActivation returns the correct data' {
        $BucketActivation.hostnameActivationId | Should -Be $BucketActivations[0].hostnameActivationId
    }

    AfterAll {
        ### Cleanup files
        Remove-Item rules.json -Force
        Remove-Item snippets.json -Force
        Remove-Item snippets -Recurse -Force
        Remove-Item includesnippets -Recurse -Force
    }
    
}

Describe 'Unsafe PAPI Tests' {
    ### New-Property
    $Script:NewProperty = New-Property -Name $TestPropertyName -ProductID $TestProductName -RuleFormat $TestRuleFormat -GroupID $TestGroupID -ContractId $TestContract @UnsafeCommonParams
    it 'New-Property creates a property' {
        $NewProperty.propertyLink | Should -Not -BeNullOrEmpty
    }

    ### Remove-Property
    $Script:RemoveProperty = Remove-Property -PropertyID 000000 @UnsafeCommonParams
    it 'Remove-Property removes a property' {
        $RemoveProperty.message | Should -Be "Deletion Successful."
    }

    ### New-EdgeHostname
    $Script:NewEdgeHostname = New-EdgeHostname -DomainPrefix test -DomainSuffix edgesuite.net -IPVersionBehavior IPV4 -ProductId $TestProductName -SecureNetwork STANDARD_TLS -GroupID $TestGroupID -ContractId $TestContract @UnsafeCommonParams
    it 'New-EdgeHostname creates an edge hostname' {
        $NewEdgeHostname.edgeHostnameLink | Should -Not -BeNullOrEmpty
    }

    ### New-CPCode
    $Script:NewCPCode = New-CPCode -CPCodeName testCP -ProductId Fresca -GroupID $TestGroupID -ContractId $TestContract @UnsafeCommonParams
    it 'New-Property creates a property' {
        $NewCPCode.cpcodeLink | Should -Not -BeNullOrEmpty
    }

    ### New-PropertyDeactivation
    $Script:Deactivation = New-PropertyDeactivation -PropertyID 123456 -PropertyVersion 1 -Network Staging -NotifyEmails "mail@example.com" @UnsafeCommonParams
    it 'New-PropertyDeactivation returns activationlink' {
        $Deactivation.activationLink | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                    Includes
    #-------------------------------------------------

    ### New-PropertyIncludeActivation
    $Script:ActivateInclude = New-PropertyIncludeActivation -IncludeID 123456 -IncludeVersion 1 -Network Staging -NotifyEmails 'mail@example.com' @UnsafeCommonParams
    it 'New-PropertyIncludeActivation activates successfully' {
        $ActivateInclude.activationLink | Should -Not -BeNullOrEmpty
    }

    ### New-PropertyIncludeDeactivation
    $Script:DeactivateInclude = New-PropertyIncludeDeactivation -IncludeID 123456 -IncludeVersion 1 -Network Staging -NotifyEmails 'mail@example.com' @UnsafeCommonParams
    it 'New-PropertyIncludeDeactivation activates successfully' {
        $DeactivateInclude.activationLink | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyIncludeActivation by ID
    $Script:IncludeActivation = Get-PropertyIncludeActivation -IncludeID 123456 -IncludeActivationID 123456789 @UnsafeCommonParams
    it 'Get-PropertyIncludeActivation returns the right data' {
        $IncludeActivation.includeId | Should -Not -BeNullOrEmpty
    }

    ### Get-PropertyIncludeActivation
    $Script:IncludeActivations = Get-PropertyIncludeActivation -IncludeID 123456 @UnsafeCommonParams
    it 'Get-PropertyIncludeActivation returns a list' {
        $IncludeActivations[0].includeId | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                Hostname Buckets
    #-------------------------------------------------

    ### Add-BucketHostnames
    $BucketHostnameToAdd = @{ 
        cnameType            = "EDGE_HOSTNAME"
        cnameFrom            = $AdditionalHostname
        cnameTo              = $PropertyHostnames[0].cnameTo
        edgeHostnameId       = $PropertyHostnames[0].edgeHostnameId
        certProvisioningType = 'CPS_MANAGED'
    }
    $Script:AddBucketHostnames = Add-BucketHostname -PropertyID 123456 -Network STAGING -NewHostnames $BucketHostnameToAdd @UnsafeCommonParams
    it 'Add-BucketHostname returns the correct data' {
        $AddBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
    }

    ### Get-BucketHostnames
    $Script:BucketHostnames = Get-BucketHostname -PropertyID 123456 -Network STAGING @UnsafeCommonParams
    it 'Get-BucketHostname returns a list' {
        $BucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
    }

    ### Compare-BucketHostnames
    $Script:BucketComparison = Compare-BucketHostname -PropertyID 123456 @UnsafeCommonParams
    it 'Compare-BucketHostname returns the correct data' {
        $BucketComparison[0].cnameFrom | Should -Not -BeNullOrEmpty
    }

    ### Remove-BucketHostnames
    $Script:RemoveBucketHostnames = Remove-BucketHostname -PropertyID 123456 -Network STAGING -HostnamesToRemove $AdditionalHostname @UnsafeCommonParams
    it 'Remove-BucketHostname returns the correct data' {
        $RemoveBucketHostnames[0].cnameFrom | Should -Not -BeNullOrEmpty
    }

    ### Remove-BucketActivation
    $Script:BucketActivationCancellation = Remove-BucketActivation -PropertyID 123456 -HostnameActivationID 987654 @UnsafeCommonParams
    it 'Remove-BucketActivation returns the correct data' {
        $BucketActivationCancellation.hostnameActivationId | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                Bulk Operations
    #-------------------------------------------------

    ### New-BulkSearch, async
    $Script:NewBulkSearch = New-BulkSearch -Match '$.name' @UnsafeCommonParams
    it 'New-BulkSearch returns the correct data' {
        $NewBulkSearch.bulkSearchLink | Should -Not -BeNullOrEmpty
    }
    
    ### New-BulkSearch, sync
    $Script:NewBulkSearchSync = New-BulkSearch -Match '$.name' -Synchronous @UnsafeCommonParams
    it 'New-BulkSearch returns the correct data' {
        $NewBulkSearchSync.results | Should -Not -BeNullOrEmpty
    }
    
    ### Get-BulkSearchResult
    $Script:GetBulkSearch = Get-BulkSearchResult -BulkSearchID 5  @UnsafeCommonParams
    it 'Get-BulkSearchResult returns the correct data' {
        $GetBulkSearch.results | Should -Not -BeNullOrEmpty
    }

    ### New-BulkVersion
    $Script:NewBulkVersion = New-BulkVersion -Body $BulkVersionJSON @UnsafeCommonParams
    it 'New-BulkVersion returns the correct data' {
        $NewBulkVersion.bulkCreateVersionLink | Should -Not -BeNullOrEmpty
    }

    ### Get-BulkVersionedProperty
    $Script:BulkVersionedProperties = Get-BulkVersionedProperty -BulkCreateID 9  @UnsafeCommonParams
    it 'Get-BulkVersionedProperty returns the correct data' {
        $BulkVersionedProperties.bulkCreateVersionsStatus | Should -Not -BeNullOrEmpty
    }

    ### New-BulkPatch
    $Script:NewBulkPatch = New-BulkPatch -Body $BulkPatchJSON @UnsafeCommonParams
    it 'New-BulkPatch returns the correct data' {
        $NewBulkPatch.bulkPatchLink | Should -Not -BeNullOrEmpty
    }
    
    ### Get-BulkPatchedProperty
    $Script:BulkPatchedProperties = Get-BulkPatchedProperty -BulkPatchID 7 @UnsafeCommonParams
    it 'Get-BulkPatchedProperty returns the correct data' {
        $BulkPatchedProperties.bulkPatchStatus | Should -Not -BeNullOrEmpty
    }

    ### New-BulkActivation
    $Script:NewBulkActivation = New-BulkActivation -Body $BulkActivateJSON @UnsafeCommonParams
    it 'New-BulkActivation returns the correct data' {
        $NewBulkActivation.bulkActivationLink | Should -Not -BeNullOrEmpty
    }
    
    ### Get-BulkActivatedProperty
    $Script:BulkActivatedProperties = Get-BulkActivatedProperty -BulkActivationID 234 @UnsafeCommonParams
    it 'Get-BulkActivatedProperty returns the correct data' {
        $BulkActivatedProperties.bulkActivationStatus | Should -Not -BeNullOrEmpty
    }
}
