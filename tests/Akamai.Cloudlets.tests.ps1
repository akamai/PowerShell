Describe 'Safe Akamai.Cloudlets Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Cloudlets/Akamai.Cloudlets.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestLegacyPolicyName = 'akamaipowershell_legacy'
        $TestSharedPolicyName = 'akamaipowershell_shared'
        $TestClonePolicyName = 'akamaipowershell_clone'
        $TestPolicyDescription = 'Testing only'
        $TestCloudletType = 'Request Control'
        $TestPolicyJson = '{"description":null,"matchRules":[{"type":"igMatchRule","id":0,"name":"AllowSampleIP","start":0,"end":0,"matchURL":null,"matches":[{"matchValue":"1.2.3.4","matchOperator":"equals","negate":false,"caseSensitive":false,"checkIPs":"CONNECTING_IP","matchType":"clientip"}],"akaRuleId":"1234567890abcdef","allowDeny":"allow"},{"type":"igMatchRule","id":0,"name":"DefaultDeny","start":0,"end":0,"matchURL":null,"akaRuleId":"abcdef1234567890","matchesAlways":true,"allowDeny":"deny"}]}'
        $TestPolicy = ConvertFrom-Json $TestPolicyJson
        $TestCSVFileName = 'cloudlet.csv'
        $TestCloudletSchema = 'create-policy.json'
        $TestPropertyName = 'akamaipowershell-testing'
        $TestLoadBalancerID = 'akamaipowershell_testing'
        $PD = @{}
        
    }

    AfterAll {
        # Temporary scoping of -All param as it isn't supported in 5.1 yet
        if ($PSVersionTable.PSVersion.Major -gt 5) {
            Get-CloudletPolicy -Legacy -All @CommonParams | Where-Object name -eq $TestLegacyPolicyName | ForEach-Object { Remove-CloudletPolicy -PolicyID $_.policyId -Legacy @CommonParams }
        }
        Get-CloudletPolicy @CommonParams | Where-Object name -in $TestSharedPolicyName, $TestClonePolicyName | ForEach-Object { Remove-CloudletPolicy -PolicyID $_.id @CommonParams }
        if ((Test-Path $TestCSVFileName)) {
            Remove-Item -Force $TestCSVFileName
        }
    }

    #------------------------------------------------
    #                 Cloudlet                  
    #------------------------------------------------

    Context 'Get-Cloudlet - Parameter Set legacy' {
        It 'returns the correct data' {
            $PD.GetCloudletLegacy = Get-Cloudlet -Legacy @CommonParams
            $PD.GetCloudletLegacy[0].cloudletCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Cloudlet - Parameter Set shared' {
        It 'returns the correct data' {
            $PD.GetCloudletShared = Get-Cloudlet @CommonParams
            $PD.GetCloudletShared[0].cloudletType | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CloudletGroup                  
    #------------------------------------------------

    Context 'Get-CloudletGroup, All' {
        It 'returns the correct data' {
            $PD.GetCloudletGroupAll = Get-CloudletGroup @CommonParams
            $PD.GetCloudletGroupAll[0].groupName | Should -Not -BeNullOrEmpty
        }
    }
    Context 'Get-CloudletGroup, single' {
        It 'returns the correct data' {
            $PD.GetCloudletGroupSingle = Get-CloudletGroup -GroupID $TestGroupID @CommonParams
            $PD.GetCloudletGroupSingle.groupId | Should -Be $TestGroupID
        }
    }

    #------------------------------------------------
    #                 CloudletPolicy                  
    #------------------------------------------------

    Context 'New-CloudletPolicy - Parameter Set legacy' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyLegacy = New-CloudletPolicy -CloudletType $TestCloudletType -GroupID $TestGroupID -Name $TestLegacyPolicyName -Legacy @CommonParams
            $PD.NewCloudletPolicyLegacy.name | Should -Be $TestLegacyPolicyName
        }
    }

    Context 'New-CloudletPolicy - Parameter Set shared' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyShared = New-CloudletPolicy -CloudletType $TestCloudletType -GroupID $TestGroupID -Name $TestSharedPolicyName @CommonParams
            $PD.NewCloudletPolicyShared.name | Should -Be $TestSharedPolicyName
        }
    }

    Context 'Get-CloudletPolicy - Legacy - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyLegacyAll = Get-CloudletPolicy -Legacy @CommonParams
            $PD.GetCloudletPolicyLegacyAll[0].policyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletPolicy - Legacy - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyLegacySingle = Get-CloudletPolicy -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams
            $PD.GetCloudletPolicyLegacySingle.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
    }
    
    Context 'Get-CloudletPolicy - Shared - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicySharedAll = Get-CloudletPolicy @CommonParams
            $PD.GetCloudletPolicySharedAll[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletPolicy - Shared - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicySharedSingle = Get-CloudletPolicy -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams
            $PD.GetCloudletPolicySharedSingle.id | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }

    Context 'Set-CloudletPolicy, legacy' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyLegacy = Set-CloudletPolicy -GroupID $TestGroupID -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Description 'New description' -Legacy @CommonParams
            $PD.SetCloudletPolicyLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
    }

    Context 'Set-CloudletPolicy, shared' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyShared = Set-CloudletPolicy -GroupID $TestGroupID -PolicyID $PD.NewCloudletPolicyShared.id -Description 'New description' @CommonParams
            $PD.SetCloudletPolicyShared.id | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }

    Context 'Copy-CloudletPolicy' {
        It 'clones correctly' {
            $PD.CopyCloudletPolicy = Copy-CloudletPolicy -GroupID $TestGroupID -NewName $TestClonePolicyName -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams
            $PD.CopyCloudletPolicy.name | Should -Be $TestClonePolicyName
        }
    }
    #------------------------------------------------
    #                 CloudletPolicyVersion                  
    #------------------------------------------------
    
    Context 'New-CloudletPolicyVersion by parameter, legacy' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionByParamLegacy = New-CloudletPolicyVersion -Body $TestPolicyJson -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams
            $PD.NewCloudletPolicyVersionByParamLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
    }
    
    Context 'New-CloudletPolicyVersion by pipeline, legacy' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionByPipelineLegacy = ($TestPolicy | New-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams)
            $PD.NewCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
    }
    
    Context 'New-CloudletPolicyVersion by parameter, shared' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionByParamShared = New-CloudletPolicyVersion -Body $TestPolicyJson -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams
            $PD.NewCloudletPolicyVersionByParamShared.policyId | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }
    
    Context 'New-CloudletPolicyVersion by pipeline, shared' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionByPipelineShared = ($TestPolicy | New-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams)
            $PD.NewCloudletPolicyVersionByPipelineShared.policyId | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set all - Legacy' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionAllLegacy = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams
            $PD.GetCloudletPolicyVersionAllLegacy[0].Version | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set single - Legacy' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionSingleLegacy = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 -Legacy @CommonParams
            $PD.GetCloudletPolicyVersionSingleLegacy.Version | Should -Be 2
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set single - Legacy' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionSingleLegacyLatest = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version latest -Legacy @CommonParams
            $PD.GetCloudletPolicyVersionSingleLegacyLatest.Version | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set all - Shared' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionAllShared = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams
            $PD.GetCloudletPolicyVersionAllShared[0].Version | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set single - Shared' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionSingleShared = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id -Version 1 @CommonParams
            $PD.GetCloudletPolicyVersionSingleShared.Version | Should -Be 1
        }
    }
    
    Context 'Get-CloudletPolicyVersion - Parameter Set single - Shared' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionSingleSharedLatest = Get-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id -Version latest @CommonParams
            $PD.GetCloudletPolicyVersionSingleShared.Version | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-CloudletPolicyVersion by parameter, legacy' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionByParamLegacy = Set-CloudletPolicyVersion -Body (ConvertTo-Json -Depth 10 $PD.GetCloudletPolicyVersionSingleLegacy) -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version $PD.GetCloudletPolicyVersionSingleLegacy.version -Legacy @CommonParams
            $PD.SetCloudletPolicyVersionByParamLegacy.policyId | Should -Be $PD.GetCloudletPolicyVersionSingleLegacy.policyId
        }
    }
    
    Context 'Set-CloudletPolicyVersion by pipeline, legacy' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionByPipelineLegacy = ($PD.GetCloudletPolicyVersionSingleLegacy | Set-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version $PD.GetCloudletPolicyVersionSingleLegacy.version -Legacy @CommonParams)
            $PD.SetCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $PD.GetCloudletPolicyVersionSingleLegacy.policyId
        }
    }
    
    Context 'Set-CloudletPolicyVersion by parameter, shared' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionByParamShared = Set-CloudletPolicyVersion -Body (ConvertTo-Json -Depth 10 $PD.GetCloudletPolicyVersionSingleShared) -PolicyID $PD.NewCloudletPolicyShared.id -Version $PD.GetCloudletPolicyVersionSingleShared.version @CommonParams
            $PD.SetCloudletPolicyVersionByParamShared.policyId | Should -Be $PD.GetCloudletPolicyVersionSingleShared.policyId
        }
    }
    
    Context 'Set-CloudletPolicyVersion by pipeline, shared' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionByPipelineShared = ($PD.GetCloudletPolicyVersionSingleShared | Set-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id -Version $PD.GetCloudletPolicyVersionSingleShared.version @CommonParams)
            $PD.SetCloudletPolicyVersionByPipelineShared.policyId | Should -Be $PD.GetCloudletPolicyVersionSingleShared.policyId
        }
    }

    #------------------------------------------------
    #                 CloudletPolicyDetails                  
    #------------------------------------------------

    Context 'Expand-CloudletPolicyDetails, legacy' {
        It 'returns the correct data' {
            $PD.ExpandCloudletPolicyDetailsLegacy = Expand-CloudletPolicyDetails -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version latest -Legacy @CommonParams
            $PD.ExpandCloudletPolicyDetailsLegacy | Should -Match '[0-9]+'
        }
    }
    
    Context 'Expand-CloudletPolicyDetails, shared' {
        It 'returns the correct data' {
            $PD.ExpandCloudletPolicyDetailsShared = Expand-CloudletPolicyDetails -PolicyID $PD.NewCloudletPolicyShared.id -Version latest @CommonParams
            $PD.ExpandCloudletPolicyDetailsShared | Should -Match '[0-9]+'
        }
    }
    
    #------------------------------------------------
    #                 CloudletPolicyCSV                  
    #------------------------------------------------
    
    Context 'Get-CloudletPolicyCSV' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyCSV = Get-CloudletPolicyCSV -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version latest -OutputFileName $TestCSVFileName  @CommonParams
            $TestCSVFileName | Should -Exist
        }
    }

    #------------------------------------------------
    #                 CloudletSchema                  
    #------------------------------------------------

    Context 'Get-CloudletSchema - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetCloudletSchemaAll = Get-CloudletSchema -CloudletType $TestCloudletType @CommonParams
            $PD.GetCloudletSchemaAll[0].title | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletSchema - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetCloudletSchemaSingle = Get-CloudletSchema -SchemaName $TestCloudletSchema @CommonParams
            $PD.GetCloudletSchemaSingle.title | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CloudletPolicyVersionRule                  
    #------------------------------------------------

    Context 'New-CloudletPolicyVersionRule by parameter, legacy' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionRuleByParam = New-CloudletPolicyVersionRule -Body $TestPolicy.matchRules[0] -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 1 @CommonParams
            $PD.NewCloudletPolicyVersionRuleByParam.akaRuleId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudletPolicyVersionRule by pipeline, legacy' {
        It 'returns the correct data' {
            $PD.NewCloudletPolicyVersionRuleByPipeline = ($TestPolicy.matchRules[0] | New-CloudletPolicyVersionRule -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 1 @CommonParams)
            $PD.NewCloudletPolicyVersionRuleByPipeline.akaRuleId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletPolicyVersionRule' {
        It 'returns the correct data' {
            $PD.GetCloudletPolicyVersionRule = Get-CloudletPolicyVersionRule -AkaRuleID $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 @CommonParams
            $PD.GetCloudletPolicyVersionRule.akaRuleId | Should -Be $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
        }
    }

    Context 'Set-CloudletPolicyVersionRule by parameter' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionRuleByParam = Set-CloudletPolicyVersionRule -AkaRuleID $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -Body $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0] -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 @CommonParams
            $PD.SetCloudletPolicyVersionRuleByParam.akaRuleId | Should -Be $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
        }
    }

    Context 'Set-CloudletPolicyVersionRule by pipeline' {
        It 'returns the correct data' {
            $PD.SetCloudletPolicyVersionRuleByPipeline = ($PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0] | Set-CloudletPolicyVersionRule -AkaRuleID $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 @CommonParams)
            $PD.SetCloudletPolicyVersionRuleByPipeline.akaRuleId | Should -Be $PD.GetCloudletPolicyVersionSingleLegacy.matchRules[0].akaruleId
        }
    }
    
    #------------------------------------------------
    #                 CloudletLoadBalancer                  
    #------------------------------------------------

    Context 'Get-CloudletLoadBalancer - Parameter Set single' {
        It 'returns the correct data' {
            $PD.GetCloudletLoadBalancerSingle = Get-CloudletLoadBalancer -OriginID $TestLoadBalancerID @CommonParams
            $PD.GetCloudletLoadBalancerSingle.originId | Should -Be $TestLoadBalancerID
        }
    }

    Context 'Get-CloudletLoadBalancer - Parameter Set all' {
        It 'returns the correct data' {
            $PD.GetCloudletLoadBalancerAll = Get-CloudletLoadBalancer @CommonParams
            $PD.GetCloudletLoadBalancerAll[0].originId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-CloudletLoadBalancer by Param' {
        It 'updates correctly' {
            $PD.SetCloudletLoadBalancerByParam = Set-CloudletLoadBalancer -Body $PD.GetCloudletLoadBalancerSingle -OriginID $TestLoadBalancerID @CommonParams
            $PD.SetCloudletLoadBalancerByParam.originId | Should -Be $TestLoadBalancerID
        }
    }
    
    Context 'Set-CloudletLoadBalancer by pipeline' {
        It 'updates correctly' {
            $PD.SetCloudletLoadBalancerByPipeline = ($PD.GetCloudletLoadBalancerSingle | Set-CloudletLoadBalancer -OriginID $TestLoadBalancerID @CommonParams)
            $PD.SetCloudletLoadBalancerByPipeline.originId | Should -Be $TestLoadBalancerID
        }
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerVersion                  
    #------------------------------------------------
    
    Context 'Get-CloudletLoadBalancerVersion' {
        It 'returns the correct data' {
            $PD.GetCloudletLoadBalancerVersion = Get-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -Version latest @CommonParams
            $PD.GetCloudletLoadBalancerVersion.originId | Should -Be $TestLoadBalancerID
        }
    }

    Context 'New-CloudletLoadBalancerVersion by parameter' {
        It 'returns the correct data' {
            $PD.NewCloudletLoadBalancerVersionByParam = New-CloudletLoadBalancerVersion -Body $PD.GetCloudletLoadBalancerVersion -OriginID $TestLoadBalancerID @CommonParams
            $PD.NewCloudletLoadBalancerVersionByParam.originId | Should -Be $TestLoadBalancerID
        }
    }
    
    Context 'New-CloudletLoadBalancerVersion by pipeline' {
        It 'returns the correct data' {
            $PD.NewCloudletLoadBalancerVersionByPipeline = $PD.GetCloudletLoadBalancerVersion | New-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID @CommonParams
            $PD.NewCloudletLoadBalancerVersionByPipeline.originId | Should -Be $TestLoadBalancerID
        }
    }
    
    Context 'Set-CloudletLoadBalancerVersion by parameter' {
        It 'returns the correct data' {
            $PD.SetCloudletLoadBalancerVersionByParam = Set-CloudletLoadBalancerVersion -Body $PD.NewCloudletLoadBalancerVersionByPipeline -OriginID $TestLoadBalancerID -Version $PD.NewCloudletLoadBalancerVersionByPipeline.version @CommonParams
            $PD.SetCloudletLoadBalancerVersionByParam.originId | Should -Be $TestLoadBalancerID
        }
    }
    
    Context 'Set-CloudletLoadBalancerVersion by pipeline' {
        It 'returns the correct data' {
            $PD.SetCloudletLoadBalancerVersionByPipeline = $PD.NewCloudletLoadBalancerVersionByPipeline | Set-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID -Version $PD.NewCloudletLoadBalancerVersionByPipeline.version @CommonParams
            $PD.SetCloudletLoadBalancerVersionByPipeline.originId | Should -Be $TestLoadBalancerID
        }
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerDetails                  
    #------------------------------------------------

    Context 'Expand-CloudletLoadBalancerDetails' {
        It 'returns the correct data' {
            $PD.ExpandCloudletLoadBalancerDetails = Expand-CloudletLoadBalancerDetails -OriginID $TestLoadBalancerID -Version latest @CommonParams
            $PD.ExpandCloudletLoadBalancerDetails | Should -Match '[\d]+'
        }
    }

    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    
    Context 'Remove-CloudletPolicyVersion' {
        It 'returns the correct data' {
            Remove-CloudletPolicyVersion -PolicyID $PD.NewCloudletPolicyShared.id -Version latest @CommonParams 
        }
    }

    Context 'Remove-CloudletPolicy, legacy' {
        It 'throws no errors' {
            Remove-CloudletPolicy -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams 
        }
    }
    Context 'Remove-CloudletPolicy, shared' {
        It 'throws no errors' {
            Remove-CloudletPolicy -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams 
        }
    }
    Context 'Remove-CloudletPolicy, clone' {
        It 'throws no errors' {
            Remove-CloudletPolicy -PolicyID $PD.CopyCloudletPolicy.id @CommonParams 
        }
    }
}

Describe 'Unsafe Akamai.Cloudlets Tests' {

    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Cloudlets/Akamai.Cloudlets.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Cloudlets"
        $PD = @{}
    }

    #------------------------------------------------
    #                 CloudletActivation                  
    #------------------------------------------------

    Context 'New-CloudletPolicyActivation - Parameter Set legacy' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyActivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewCloudletActivationLegacy = New-CloudletPolicyActivation -Network STAGING -PolicyID 111111 -Version 1 -AdditionalPropertyNames www.example.com -Legacy
            $NewCloudletActivationLegacy.policyInfo.policyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudletPolicyActivation - Parameter Set shared' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $NewCloudletActivationShared = New-CloudletPolicyActivation -Network STAGING -PolicyID 22222 -Version 1
            $NewCloudletActivationShared.policyId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CloudletDeactivation                  
    #------------------------------------------------

    Context 'New-CloudletPolicyDeactivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewCloudletDeactivation = New-CloudletPolicyDeactivation -Network STAGING -PolicyID 22222 -Version 1
            $NewCloudletDeactivation.policyId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CloudletPolicyProperty                  
    #------------------------------------------------

    Context 'Get-CloudletPolicyProperty, legacy' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyProperty.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletPolicyPropertyLegacy = Get-CloudletPolicyProperty -PolicyID 111111 -Legacy
            $GetCloudletPolicyPropertyLegacy.PSObject.Properties.Name.Count | Should -BeGreaterThan 0
        }
    }
    
    Context 'Get-CloudletPolicyProperty, shared' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyProperty_1.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletPolicyPropertyShared = Get-CloudletPolicyProperty -PolicyID 22222
            $GetCloudletPolicyPropertyShared[0].Name | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletPolicyProperty' {
        It 'returns a dictionary' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyProperty.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletProperty = Get-CloudletProperty
            $GetCloudletProperty.PSObject.Properties.Name.Count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 CloudletPolicyActivation                  
    #------------------------------------------------

    Context 'Get-CloudletPolicyActivation - Parameter Set single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletPolicyActivationSingle = Get-CloudletPolicyActivation -PolicyID 22222 -ActivationID 1234
            $GetCloudletPolicyActivationSingle.network | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletPolicyActivation - Parameter Set all - Legacy' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletPolicyActivationAllLegacy = Get-CloudletPolicyActivation -PolicyID 11111 -Legacy
            $GetCloudletPolicyActivationAllLegacy[0].policyInfo.policyId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletPolicyActivation - Parameter Set all - Shared' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation_2.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletPolicyActivationAllShared = Get-CloudletPolicyActivation -PolicyID 22222
            $GetCloudletPolicyActivationAllShared[0].id | Should -Not -BeNullOrEmpty
        }
    }


    #------------------------------------------------
    #                 CloudletLoadBalancer                  
    #------------------------------------------------

    Context 'New-CloudletLoadBalancer' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletLoadBalancer.json"
                return $Response | ConvertFrom-Json
            }
            $NewCloudletLoadBalancer = New-CloudletLoadBalancer -OriginID test_originId
            $NewCloudletLoadBalancer.originId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CloudletLoadBalancerActivation                  
    #------------------------------------------------

    Context 'New-CloudletLoadBalancerActivation' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletLoadBalancerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $NewCloudletLoadBalancerActivation = New-CloudletLoadBalancerActivation -Network STAGING -OriginID test_originId -Version 1
            $NewCloudletLoadBalancerActivation.network | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletLoadBalancerActivation, single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletLoadBalancerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletLoadBalancerActivationSingle = Get-CloudletLoadBalancerActivation -OriginID test_originId
            $GetCloudletLoadBalancerActivationSingle[0].Version | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudletLoadBalancerActivation, all' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletLoadBalancerActivation.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletLoadBalancerActivationAll = Get-CloudletLoadBalancerActivation
            $GetCloudletLoadBalancerActivationAll.PSObject.Properties.Name.count | Should -BeGreaterThan 0
        }
    }

    AfterAll {

    }

}

