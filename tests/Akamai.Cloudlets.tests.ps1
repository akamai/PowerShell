Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Cloudlets/Akamai.Cloudlets.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestLegacyPolicyName = 'akamaipowershell_legacy'
$Script:TestSharedPolicyName = 'akamaipowershell_shared'
$Script:TestClonePolicyName = 'akamaipowershell_clone'
$Script:TestPolicyDescription = 'Testing only'
$Script:TestCloudletType = 'Request Control'
$Script:TestPolicyJson = '{"description":null,"matchRules":[{"type":"igMatchRule","id":0,"name":"AllowSampleIP","start":0,"end":0,"matchURL":null,"matches":[{"matchValue":"1.2.3.4","matchOperator":"equals","negate":false,"caseSensitive":false,"checkIPs":"CONNECTING_IP","matchType":"clientip"}],"akaRuleId":"1234567890abcdef","allowDeny":"allow"},{"type":"igMatchRule","id":0,"name":"DefaultDeny","start":0,"end":0,"matchURL":null,"akaRuleId":"abcdef1234567890","matchesAlways":true,"allowDeny":"deny"}]}'
$Script:TestPolicy = ConvertFrom-Json $TestPolicyJson
$Script:TestCSVFileName = 'cloudlet.csv'
$Script:TestCloudletSchema = 'create-policy.json'
$Script:TestPropertyName = 'akamaipowershell-testing'
$Script:TestLoadBalancerID = 'akamaipowershell_testing'

Describe 'Safe Akamai.Cloudlets Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 Cloudlet                  
    #------------------------------------------------

    ### Get-Cloudlet - Parameter Set 'legacy'
    $Script:GetCloudletLegacy = Get-Cloudlet -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-Cloudlet (legacy) returns the correct data' {
        $GetCloudletLegacy[0].cloudletCode | Should -Not -BeNullOrEmpty
    }

    ### Get-Cloudlet - Parameter Set 'shared'
    $Script:GetCloudletShared = Get-Cloudlet -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-Cloudlet (shared) returns the correct data' {
        $GetCloudletShared[0].cloudletType | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CloudletGroup                  
    #------------------------------------------------

    ### Get-CloudletGroup, All
    $Script:GetCloudletGroupAll = Get-CloudletGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletGroup, all returns the correct data' {
        $GetCloudletGroupAll[0].groupName | Should -Not -BeNullOrEmpty
    
    }
    ### Get-CloudletGroup, single
    $Script:GetCloudletGroupSingle = Get-CloudletGroup -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletGroup, single returns the correct data' {
        $GetCloudletGroupSingle.groupId | Should -Be $TestGroupID
    }

    #------------------------------------------------
    #                 CloudletPolicy                  
    #------------------------------------------------

    ### New-CloudletPolicy - Parameter Set 'legacy'
    $Script:NewCloudletPolicyLegacy = New-CloudletPolicy -CloudletType $TestCloudletType -GroupID $TestGroupID -Name $TestLegacyPolicyName -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletPolicy (legacy) returns the correct data' {
        $NewCloudletPolicyLegacy.name | Should -Be $TestLegacyPolicyName
    }

    ### New-CloudletPolicy - Parameter Set 'shared'
    $Script:NewCloudletPolicyShared = New-CloudletPolicy -CloudletType $TestCloudletType -GroupID $TestGroupID -Name $TestSharedPolicyName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletPolicy (shared) returns the correct data' {
        $NewCloudletPolicyShared.name | Should -Be $TestSharedPolicyName
    }

    ### Get-CloudletPolicy - Legacy - Parameter Set 'all'
    $Script:GetCloudletPolicyLegacyAll = Get-CloudletPolicy -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicy, Legacy (all) returns the correct data' {
        $GetCloudletPolicyLegacyAll[0].policyId | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletPolicy - Legacy - Parameter Set 'single'
    $Script:GetCloudletPolicyLegacySingle = Get-CloudletPolicy -PolicyID $NewCloudletPolicyLegacy.policyId -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicy, Legacy (single) returns the correct data' {
        $GetCloudletPolicyLegacySingle.policyId | Should -Be $NewCloudletPolicyLegacy.policyId
    }
    
    ### Get-CloudletPolicy - Shared - Parameter Set 'all'
    $Script:GetCloudletPolicySharedAll = Get-CloudletPolicy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicy, Shared (all) returns the correct data' {
        $GetCloudletPolicySharedAll[0].id | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletPolicy - Shared - Parameter Set 'single'
    $Script:GetCloudletPolicySharedSingle = Get-CloudletPolicy -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicy, Shared (single) returns the correct data' {
        $GetCloudletPolicySharedSingle.id | Should -Be $NewCloudletPolicyShared.id
    }

    ### Set-CloudletPolicy, legacy
    $Script:SetCloudletPolicyLegacy = Set-CloudletPolicy -GroupID $TestGroupID -PolicyID $NewCloudletPolicyLegacy.policyId -Description 'New description' -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletPolicy, legacy returns the correct data' {
        $SetCloudletPolicyLegacy.policyId | Should -Be $NewCloudletPolicyLegacy.policyId
    }

    ### Set-CloudletPolicy, shared
    $Script:SetCloudletPolicyShared = Set-CloudletPolicy -GroupID $TestGroupID -PolicyID $NewCloudletPolicyShared.id -Description 'New description' -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletPolicy, shared returns the correct data' {
        $SetCloudletPolicyShared.id | Should -Be $NewCloudletPolicyShared.id
    }

    ### Copy-CloudletPolicy
    $Script:CopyCloudletPolicy = Copy-CloudletPolicy -GroupID $TestGroupID -NewName $TestClonePolicyName -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Copy-CloudletPolicy clones correctly' {
        $CopyCloudletPolicy.name | Should -Be $TestClonePolicyName
    }
    #------------------------------------------------
    #                 CloudletPolicyVersion                  
    #------------------------------------------------
    
    ### New-CloudletPolicyVersion by parameter, legacy
    $Script:NewCloudletPolicyVersionByParamLegacy = New-CloudletPolicyVersion -Body $TestPolicyJson -PolicyID $NewCloudletPolicyLegacy.policyId -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletPolicyVersion by param, legacy returns the correct data' {
        $NewCloudletPolicyVersionByParamLegacy.policyId | Should -Be $NewCloudletPolicyLegacy.policyId
    }
    
    ### New-CloudletPolicyVersion by pipeline, legacy
    $Script:NewCloudletPolicyVersionByPipelineLegacy = ($TestPolicy | New-CloudletPolicyVersion -PolicyID $NewCloudletPolicyLegacy.policyId -Legacy -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-CloudletPolicyVersion by pipeline, legacy returns the correct data' {
        $NewCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $NewCloudletPolicyLegacy.policyId
    }
    
    ### New-CloudletPolicyVersion by parameter, shared
    $Script:NewCloudletPolicyVersionByParamShared = New-CloudletPolicyVersion -Body $TestPolicyJson -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletPolicyVersion by param, shared returns the correct data' {
        $NewCloudletPolicyVersionByParamShared.policyId | Should -Be $NewCloudletPolicyShared.id
    }
    
    ### New-CloudletPolicyVersion by pipeline, shared
    $Script:NewCloudletPolicyVersionByPipelineShared = ($TestPolicy | New-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-CloudletPolicyVersion by pipeline, shared returns the correct data' {
        $NewCloudletPolicyVersionByPipelineShared.policyId | Should -Be $NewCloudletPolicyShared.id
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'all' - Legacy
    $Script:GetCloudletPolicyVersionAllLegacy = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyLegacy.policyId -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (all), legacy returns the correct data' {
        $GetCloudletPolicyVersionAllLegacy[0].Version | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'single' - Legacy
    $Script:GetCloudletPolicyVersionSingleLegacy = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyLegacy.policyId -Version 2 -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (single), legacy (specific) returns the correct data' {
        $GetCloudletPolicyVersionSingleLegacy.Version | Should -Be 2
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'single' - Legacy
    $Script:GetCloudletPolicyVersionSingleLegacyLatest = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyLegacy.policyId -Version latest -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (single), legacy (latest) returns the correct data' {
        $GetCloudletPolicyVersionSingleLegacyLatest.Version | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'all' - Shared
    $Script:GetCloudletPolicyVersionAllShared = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (all), shared returns the correct data' {
        $GetCloudletPolicyVersionAllShared[0].Version | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'single' - Shared
    $Script:GetCloudletPolicyVersionSingleShared = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -Version 1 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (single), shared (specific) returns the correct data' {
        $GetCloudletPolicyVersionSingleShared.Version | Should -Be 1
    }
    
    ### Get-CloudletPolicyVersion - Parameter Set 'single' - Shared
    $Script:GetCloudletPolicyVersionSingleSharedLatest = Get-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -Version latest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersion (single), shared (latest) returns the correct data' {
        $GetCloudletPolicyVersionSingleShared.Version | Should -Not -BeNullOrEmpty
    }
    
    ### Set-CloudletPolicyVersion by parameter, legacy
    $Script:SetCloudletPolicyVersionByParamLegacy = Set-CloudletPolicyVersion -Body (ConvertTo-Json -Depth 10 $GetCloudletPolicyVersionSingleLegacy) -PolicyID $NewCloudletPolicyLegacy.policyId -Version $GetCloudletPolicyVersionSingleLegacy.version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletPolicyVersion by param returns the correct data' {
        $SetCloudletPolicyVersionByParamLegacy.policyId | Should -Be $GetCloudletPolicyVersionSingleLegacy.policyId
    }
    
    ### Set-CloudletPolicyVersion by pipeline, legacy
    $Script:SetCloudletPolicyVersionByPipelineLegacy = ($GetCloudletPolicyVersionSingleLegacy | Set-CloudletPolicyVersion -PolicyID $NewCloudletPolicyLegacy.policyId -Version $GetCloudletPolicyVersionSingleLegacy.version -Legacy -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CloudletPolicyVersion by pipeline returns the correct data' {
        $SetCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $GetCloudletPolicyVersionSingleLegacy.policyId
    }
    
    ### Set-CloudletPolicyVersion by parameter, shared
    $Script:SetCloudletPolicyVersionByParamShared = Set-CloudletPolicyVersion -Body (ConvertTo-Json -Depth 10 $GetCloudletPolicyVersionSingleShared) -PolicyID $NewCloudletPolicyShared.id -Version $GetCloudletPolicyVersionSingleShared.version -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletPolicyVersion by param returns the correct data' {
        $SetCloudletPolicyVersionByParamShared.policyId | Should -Be $GetCloudletPolicyVersionSingleShared.policyId
    }
    
    ### Set-CloudletPolicyVersion by pipeline, shared
    $Script:SetCloudletPolicyVersionByPipelineShared = ($GetCloudletPolicyVersionSingleShared | Set-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -Version $GetCloudletPolicyVersionSingleShared.version -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CloudletPolicyVersion by pipeline returns the correct data' {
        $SetCloudletPolicyVersionByPipelineShared.policyId | Should -Be $GetCloudletPolicyVersionSingleShared.policyId
    }

    #------------------------------------------------
    #                 CloudletPolicyDetails                  
    #------------------------------------------------

    ### Expand-CloudletPolicyDetails, legacy
    $Script:ExpandCloudletPolicyDetailsLegacy = Expand-CloudletPolicyDetails -PolicyID $NewCloudletPolicyLegacy.policyId -Version latest -Legacy -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Expand-CloudletPolicyDetails, legacy returns the correct data' {
        $ExpandCloudletPolicyDetailsLegacy | Should -Match '[0-9]+'
    }
    
    ### Expand-CloudletPolicyDetails, shared
    $Script:ExpandCloudletPolicyDetailsShared = Expand-CloudletPolicyDetails -PolicyID $NewCloudletPolicyShared.id -Version latest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Expand-CloudletPolicyDetails, legacy returns the correct data' {
        $ExpandCloudletPolicyDetailsShared | Should -Match '[0-9]+'
    }
    
    
    #------------------------------------------------
    #                 CloudletPolicyCSV                  
    #------------------------------------------------
    
    ### Get-CloudletPolicyCSV
    $Script:GetCloudletPolicyCSV = Get-CloudletPolicyCSV -PolicyID $NewCloudletPolicyLegacy.policyId -Version latest -OutputFileName $TestCSVFileName  -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyCSV returns the correct data' {
        $TestCSVFileName | Should -Exist
    }

    #------------------------------------------------
    #                 CloudletSchema                  
    #------------------------------------------------

    ### Get-CloudletSchema - Parameter Set 'all'
    $Script:GetCloudletSchemaAll = Get-CloudletSchema -CloudletType $TestCloudletType -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletSchema (all) returns the correct data' {
        $GetCloudletSchemaAll[0].title | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletSchema - Parameter Set 'single'
    $Script:GetCloudletSchemaSingle = Get-CloudletSchema -SchemaName $TestCloudletSchema -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletSchema (single) returns the correct data' {
        $GetCloudletSchemaSingle.title | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CloudletPolicyVersionRule                  
    #------------------------------------------------

    ### New-CloudletPolicyVersionRule by parameter, legacy
    $Script:NewCloudletPolicyVersionRuleByParam = New-CloudletPolicyVersionRule -Body $TestPolicy.matchRules[0] -PolicyID $NewCloudletPolicyLegacy.policyId -Version 1 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletPolicyVersionRule by param returns the correct data' {
        $NewCloudletPolicyVersionRuleByParam.akaRuleId | Should -Not -BeNullOrEmpty
    }

    ### New-CloudletPolicyVersionRule by pipeline, legacy
    $Script:NewCloudletPolicyVersionRuleByPipeline = ($TestPolicy.matchRules[0] | New-CloudletPolicyVersionRule -PolicyID $NewCloudletPolicyLegacy.policyId -Version 1 -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'New-CloudletPolicyVersionRule by pipeline returns the correct data' {
        $NewCloudletPolicyVersionRuleByPipeline.akaRuleId | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletPolicyVersionRule
    $Script:GetCloudletPolicyVersionRule = Get-CloudletPolicyVersionRule -AkaRuleID $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -PolicyID $NewCloudletPolicyLegacy.policyId -Version 2 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletPolicyVersionRule returns the correct data' {
        $GetCloudletPolicyVersionRule.akaRuleId | Should -Be $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
    }

    ### Set-CloudletPolicyVersionRule by parameter
    $Script:SetCloudletPolicyVersionRuleByParam = Set-CloudletPolicyVersionRule -AkaRuleID $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -Body $GetCloudletPolicyVersionSingleLegacy.matchRules[0] -PolicyID $NewCloudletPolicyLegacy.policyId -Version 2 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletPolicyVersionRule by param returns the correct data' {
        $SetCloudletPolicyVersionRuleByParam.akaRuleId | Should -Be $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
    }

    ### Set-CloudletPolicyVersionRule by pipeline
    $Script:SetCloudletPolicyVersionRuleByPipeline = ($GetCloudletPolicyVersionSingleLegacy.matchRules[0] | Set-CloudletPolicyVersionRule -AkaRuleID $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -PolicyID $NewCloudletPolicyLegacy.policyId -Version 2 -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CloudletPolicyVersionRule by pipeline returns the correct data' {
        $SetCloudletPolicyVersionRuleByPipeline.akaRuleId | Should -Be $GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
    }
    
    #------------------------------------------------
    #                 CloudletLoadBalancer                  
    #------------------------------------------------

    ### Get-CloudletLoadBalancer - Parameter Set 'single'
    $Script:GetCloudletLoadBalancerSingle = Get-CloudletLoadBalancer -OriginID $TestLoadBalancerID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletLoadBalancer (single) returns the correct data' {
        $GetCloudletLoadBalancerSingle.originId | Should -Be $TestLoadBalancerID
    }

    ### Get-CloudletLoadBalancer - Parameter Set 'all'
    $Script:GetCloudletLoadBalancerAll = Get-CloudletLoadBalancer -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletLoadBalancer (all) returns the correct data' {
        $GetCloudletLoadBalancerAll[0].originId | Should -Not -BeNullOrEmpty
    }

    ### Set-CloudletLoadBalancer by Param
    $Script:SetCloudletLoadBalancerByParam = Set-CloudletLoadBalancer -Body $GetCloudletLoadBalancerSingle -OriginID $TestLoadBalancerID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletLoadBalancer by param updates correctly' {
        $SetCloudletLoadBalancerByParam.originId | Should -Be $TestLoadBalancerID
    }
    
    ### Set-CloudletLoadBalancer by pipeline
    $Script:SetCloudletLoadBalancerByPipeline = ($GetCloudletLoadBalancerSingle | Set-CloudletLoadBalancer -OriginID $TestLoadBalancerID -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-CloudletLoadBalancer by pipeline updates correctly' {
        $SetCloudletLoadBalancerByPipeline.originId | Should -Be $TestLoadBalancerID
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerVersion                  
    #------------------------------------------------
    
    ### Get-CloudletLoadBalancerVersion
    $Script:GetCloudletLoadBalancerVersion = Get-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -Version latest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudletLoadBalancerVersion returns the correct data' {
        $GetCloudletLoadBalancerVersion.originId | Should -Be $TestLoadBalancerID
    }

    ### New-CloudletLoadBalancerVersion by parameter
    $Script:NewCloudletLoadBalancerVersionByParam = New-CloudletLoadBalancerVersion -Body $GetCloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletLoadBalancerVersion by param returns the correct data' {
        $NewCloudletLoadBalancerVersionByParam.originId | Should -Be $TestLoadBalancerID
    }
    
    ### New-CloudletLoadBalancerVersion by pipeline
    $Script:NewCloudletLoadBalancerVersionByPipeline = $GetCloudletLoadBalancerVersion | New-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudletLoadBalancerVersion by pipeline returns the correct data' {
        $NewCloudletLoadBalancerVersionByPipeline.originId | Should -Be $TestLoadBalancerID
    }
    
    ### Set-CloudletLoadBalancerVersion by parameter
    $Script:SetCloudletLoadBalancerVersionByParam = Set-CloudletLoadBalancerVersion -Body $NewCloudletLoadBalancerVersionByPipeline -OriginID $TestLoadBalancerID -Version $NewCloudletLoadBalancerVersionByPipeline.version -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletLoadBalancerVersion by param returns the correct data' {
        $SetCloudletLoadBalancerVersionByParam.originId | Should -Be $TestLoadBalancerID
    }
    
    ### Set-CloudletLoadBalancerVersion by pipeline
    $Script:SetCloudletLoadBalancerVersionByPipeline = $NewCloudletLoadBalancerVersionByPipeline | Set-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -Version $NewCloudletLoadBalancerVersionByPipeline.version -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-CloudletLoadBalancerVersion by pipeline returns the correct data' {
        $SetCloudletLoadBalancerVersionByPipeline.originId | Should -Be $TestLoadBalancerID
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerDetails                  
    #------------------------------------------------

    ### Expand-CloudletLoadBalancerDetails
    $Script:ExpandCloudletLoadBalancerDetails = Expand-CloudletLoadBalancerDetails -OriginID $TestLoadBalancerID -Version latest -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Expand-CloudletLoadBalancerDetails returns the correct data' {
        $ExpandCloudletLoadBalancerDetails | Should -Match '[\d]+'
    }

    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    
    ### Remove-CloudletPolicyVersion
    it 'Remove-CloudletPolicyVersion returns the correct data' {
        { Remove-CloudletPolicyVersion -PolicyID $NewCloudletPolicyShared.id -Version latest -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Remove-CloudletPolicy, legacy
    it 'Remove-CloudletPolicy, legacy throws no errors' {
        { Remove-CloudletPolicy -PolicyID $NewCloudletPolicyLegacy.policyId -Legacy -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    ### Remove-CloudletPolicy, shared
    it 'Remove-CloudletPolicy, shared throws no errors' {
        { Remove-CloudletPolicy -PolicyID $NewCloudletPolicyShared.id -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }
    ### Remove-CloudletPolicy, clone
    it 'Remove-CloudletPolicy, clone throws no errors' {
        { Remove-CloudletPolicy -PolicyID $CopyCloudletPolicy.id -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }


    AfterAll {
        Remove-Item -Force $TestCSVFileName
    }

}

Describe 'Safe Akamai.Cloudlets Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 CloudletActivation                  
    #------------------------------------------------

    ### New-CloudletPolicyActivation - Parameter Set 'legacy'
    $Script:NewCloudletActivationLegacy = New-CloudletPolicyActivation -Network STAGING -PolicyID 111111 -Version 1 -AdditionalPropertyNames $TestPropertyName -Legacy -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudletPolicyActivation (legacy) returns the correct data' {
        $NewCloudletActivationLegacy.policyInfo.policyId | Should -Not -BeNullOrEmpty
    }

    ### New-CloudletPolicyActivation - Parameter Set 'shared'
    $Script:NewCloudletActivationShared = New-CloudletPolicyActivation -Network STAGING -PolicyID 22222 -Version 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudletPolicyActivation (shared) returns the correct data' {
        $NewCloudletActivationShared.policyId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CloudletDeactivation                  
    #------------------------------------------------

    ### New-CloudletPolicyDeactivation
    $Script:NewCloudletDeactivation = New-CloudletPolicyDeactivation -Network STAGING -PolicyID 22222 -Version 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudletPolicyDeactivation returns the correct data' {
        $NewCloudletDeactivation.policyId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CloudletPolicyProperty                  
    #------------------------------------------------

    ### Get-CloudletPolicyProperty, legacy
    $Script:GetCloudletPolicyPropertyLegacy = Get-CloudletPolicyProperty -PolicyID 111111 -Legacy -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletPolicyProperty, legacy returns the correct data' {
        $GetCloudletPolicyPropertyLegacy.PSObject.Properties.Name.Count | Should -BeGreaterThan 0
    }
    
    ### Get-CloudletPolicyProperty, shared
    $Script:GetCloudletPolicyPropertyShared = Get-CloudletPolicyProperty -PolicyID 22222 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletPolicyProperty, shared returns the correct data' {
        $GetCloudletPolicyPropertyShared[0].Name | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletPolicyProperty
    $Script:GetCloudletProperty = Get-CloudletProperty -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'GetCloudletProperty returns a dictionary' {
        $GetCloudletProperty.PSObject.Properties.Name.Count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 CloudletPolicyActivation                  
    #------------------------------------------------

    ### Get-CloudletPolicyActivation - Parameter Set 'single'
    $Script:GetCloudletPolicyActivationSingle = Get-CloudletPolicyActivation -PolicyID 22222 -ActivationID 1234 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletPolicyActivation (single) returns the correct data' {
        $GetCloudletPolicyActivationSingle.network | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletPolicyActivation - Parameter Set 'all' - Legacy
    $Script:GetCloudletPolicyActivationAllLegacy = Get-CloudletPolicyActivation -PolicyID 11111 -Legacy -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletPolicyActivation (all) returns the correct data' {
        $GetCloudletPolicyActivationAllLegacy[0].policyInfo.policyId | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletPolicyActivation - Parameter Set 'all' - Shared
    $Script:GetCloudletPolicyActivationAllShared = Get-CloudletPolicyActivation -PolicyID 22222 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletPolicyActivation (all) returns the correct data' {
        $GetCloudletPolicyActivationAllShared[0].id | Should -Not -BeNullOrEmpty
    }


    #------------------------------------------------
    #                 CloudletLoadBalancer                  
    #------------------------------------------------

    ### New-CloudletLoadBalancer
    $Script:NewCloudletLoadBalancer = New-CloudletLoadBalancer -OriginID test_originId -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudletLoadBalancer returns the correct data' {
        $NewCloudletLoadBalancer.originId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerActivation                  
    #------------------------------------------------

    ### New-CloudletLoadBalancerActivation
    $Script:NewCloudletLoadBalancerActivation = New-CloudletLoadBalancerActivation -Network STAGING -OriginID test_originId -Version 1 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudletLoadBalancerActivation returns the correct data' {
        $NewCloudletLoadBalancerActivation.network | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudletLoadBalancerActivation, single
    $Script:GetCloudletLoadBalancerActivationSingle = Get-CloudletLoadBalancerActivation -OriginID test_originId -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletLoadBalancerActivation returns the correct data' {
        $GetCloudletLoadBalancerActivationSingle[0].Version | Should -Not -BeNullOrEmpty
    }
    
    ### Get-CloudletLoadBalancerActivation, all
    $Script:GetCloudletLoadBalancerActivationAll = Get-CloudletLoadBalancerActivation -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudletLoadBalancerActivation returns the correct data' {
        $GetCloudletLoadBalancerActivationAll.PSObject.Properties.Name.count | Should -BeGreaterThan 0
    }

    AfterAll {

    }

}