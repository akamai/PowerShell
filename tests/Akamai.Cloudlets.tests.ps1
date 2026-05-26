BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Cloudlets Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Cloudlets'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestLegacyPolicyName = "pester_$Timestamp`_legacy"
        $TestSharedPolicyName = "pester_$Timestamp`_shared"
        $TestClonePolicyName = "pester_$Timestamp`_clone"
        $TestPolicyDescription = 'Testing only'
        $TestCloudletType = 'Request Control'
        $TestPolicyJson = @"
{
    "description": null,
    "matchRules": [
        {
            "type": "igMatchRule",
            "id": 0,
            "name": "AllowSampleIP",
            "start": 0,
            "end": 0,
            "matchURL": null,
            "matches": [
                {
                    "matchValue": "1.2.3.4",
                    "matchOperator": "equals",
                    "negate": false,
                    "caseSensitive": false,
                    "checkIPs": "CONNECTING_IP",
                    "matchType": "clientip"
                }
            ],
            "akaRuleId": "1234567890abcdef",
            "allowDeny": "allow"
        },
        {
            "type": "igMatchRule",
            "id": 0,
            "name": "DefaultDeny",
            "start": 0,
            "end": 0,
            "matchURL": null,
            "akaRuleId": "abcdef1234567890",
            "matchesAlways": true,
            "allowDeny": "deny"
        }
    ]
}
"@
        $TestPolicy = ConvertFrom-Json $TestPolicyJson
        $TestCSVFileName = "TestDrive:/cloudlet-$Timestamp.csv"
        $TestCloudletSchema = 'create-policy.json'
        $TestPropertyName = 'pester-ion'
        $TestLoadBalancerID = "pester_$Timestamp"
        $ExistingLoadBalancerVersion = Get-CloudletLoadBalancerVersion -OriginID pester -Version 1 @CommonParams
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Cloudlets"
        $PD = @{}

    }

    AfterAll {
        Get-CloudletPolicy -Legacy -All @CommonParams | `
            Where-Object name -eq $TestLegacyPolicyName | `
            Remove-CloudletPolicy -Legacy @CommonParams
        Get-CloudletPolicy @CommonParams | `
            Where-Object name -in $TestSharedPolicyName, $TestClonePolicyName | `
            Remove-CloudletPolicy @CommonParams

        Get-CloudletLoadBalancer @CommonParams | `
            Where-Object originId -eq $TestLoadBalancerID | `
            Remove-CloudletLoadBalancer @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 Cloudlet
    #------------------------------------------------

    Context 'Get-Cloudlet' {
        It 'returns a list using the legacy API' {
            $TestParams = @{
                'Legacy' = $true
            }
            $PD.GetCloudletLegacy = Get-Cloudlet @TestParams @CommonParams
            $PD.GetCloudletLegacy[0].cloudletCode | Should -Not -BeNullOrEmpty
        }
        It 'returns a list using the shared API' {
            $PD.GetCloudletShared = Get-Cloudlet @CommonParams
            $PD.GetCloudletShared[0].cloudletType | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #               CloudletGroup
    #------------------------------------------------

    Context 'Get-CloudletGroup' {
        It 'returns a list of groups' {
            $PD.GetCloudletGroupAll = Get-CloudletGroup @CommonParams
            $PD.GetCloudletGroupAll[0].groupName | Should -Not -BeNullOrEmpty
        }
        It 'returns a single group by ID' {
            $TestParams = @{
                'GroupID' = $TestGroupID
            }
            $PD.GetCloudletGroupSingle = Get-CloudletGroup @TestParams @CommonParams
            $PD.GetCloudletGroupSingle.groupId | Should -Be $TestGroupID
        }
    }

    #------------------------------------------------
    #                CloudletPolicy
    #------------------------------------------------

    Context 'New-CloudletPolicy' {
        It 'creates a new legacy policy' {
            $TestParams = @{
                'CloudletType' = $TestCloudletType
                'GroupID'      = $TestGroupID
                'Name'         = $TestLegacyPolicyName
                'Legacy'       = $true
            }
            $PD.NewCloudletPolicyLegacy = New-CloudletPolicy @TestParams @CommonParams
            $PD.NewCloudletPolicyLegacy.name | Should -Be $TestLegacyPolicyName
        }
        It 'creates a new shared policy' {
            $TestParams = @{
                'CloudletType' = $TestCloudletType
                'GroupID'      = $TestGroupID
                'Name'         = $TestSharedPolicyName
            }
            $PD.NewCloudletPolicyShared = New-CloudletPolicy @TestParams @CommonParams
            $PD.NewCloudletPolicyShared.name | Should -Be $TestSharedPolicyName
        }
    }


    Context 'Get-CloudletPolicy' {
        It 'return a list of legacy policies' {
            $TestParams = @{
                'Legacy' = $true
            }
            $PD.GetCloudletPolicyLegacyAll = Get-CloudletPolicy @TestParams @CommonParams
            $PD.GetCloudletPolicyLegacyAll[0].policyId | Should -Not -BeNullOrEmpty
        }
        It 'return a single legacy policy by ID' {
            $TestParams = @{
                'PolicyID' = $PD.NewCloudletPolicyLegacy.policyId
                'Legacy'   = $true
            }
            $PD.GetCloudletPolicyLegacySingle = Get-CloudletPolicy @TestParams @CommonParams
            $PD.GetCloudletPolicyLegacySingle.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
        It 'return a list of shared policies' {
            $PD.GetCloudletPolicySharedAll = Get-CloudletPolicy @CommonParams
            $PD.GetCloudletPolicySharedAll[0].id | Should -Not -BeNullOrEmpty
        }
        It 'return a single shared policy by ID' {
            $PD.GetCloudletPolicySharedSingle = $PD.NewCloudletPolicyShared.id | Get-CloudletPolicy @CommonParams
            $PD.GetCloudletPolicySharedSingle.id | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }

    Context 'Set-CloudletPolicy' {
        It 'updates a legacy policy' {
            $TestParams = @{
                'GroupID'     = $TestGroupID
                'PolicyID'    = $PD.NewCloudletPolicyLegacy.policyId
                'Description' = 'New description'
                'Legacy'      = $true
            }
            $PD.SetCloudletPolicyLegacy = Set-CloudletPolicy @TestParams @CommonParams
            $PD.SetCloudletPolicyLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
        It 'updates a shared policy' {
            $TestParams = @{
                'GroupID'     = $TestGroupID
                'PolicyID'    = $PD.NewCloudletPolicyShared.id
                'Description' = 'New description'
            }
            $PD.SetCloudletPolicyShared = Set-CloudletPolicy @TestParams @CommonParams
            $PD.SetCloudletPolicyShared.id | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }

    Context 'Copy-CloudletPolicy' {
        It 'clones correctly' {
            $PD.CopyCloudletPolicy = $PD.NewCloudletPolicyShared | Copy-CloudletPolicy -NewName $TestClonePolicyName @CommonParams
            $PD.CopyCloudletPolicy.name | Should -Be $TestClonePolicyName
        }
    }
    #------------------------------------------------
    #           CloudletPolicyVersion
    #------------------------------------------------

    Context 'New-CloudletPolicyVersion' {
        It 'creates a new version of a legacy policy by param' {
            $TestParams = @{
                'Body'     = $TestPolicyJson
                'PolicyID' = $PD.NewCloudletPolicyLegacy.policyId
                'Legacy'   = $true
            }
            $PD.NewCloudletPolicyVersionByParamLegacy = New-CloudletPolicyVersion @TestParams @CommonParams
            $PD.NewCloudletPolicyVersionByParamLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
        }
        It 'creates a new version of a shared policy by param' {
            $TestParams = @{
                'Body'     = $TestPolicyJson
                'PolicyID' = $PD.NewCloudletPolicyShared.id
            }
            $PD.NewCloudletPolicyVersionByParamShared = New-CloudletPolicyVersion @TestParams @CommonParams
            $PD.NewCloudletPolicyVersionByParamShared.policyId | Should -Be $PD.NewCloudletPolicyShared.id
        }
    }

    Context 'Get-CloudletPolicyVersion' {
        It 'lists all versions of a legacy policy' {
            $PD.LegacyPolicyVersions = $PD.NewCloudletPolicyLegacy | Get-CloudletPolicyVersion -Legacy @CommonParams
            $PD.LegacyPolicyVersions[0].Version | Should -Not -BeNullOrEmpty
        }
        It 'gets a specified version of a legacy policy' {
            $PD.LegacyPolicyVersion = $PD.NewCloudletPolicyLegacy | Get-CloudletPolicyVersion -Version 2 -Legacy @CommonParams
            $PD.LegacyPolicyVersion.Version | Should -Be 2
        }
        It 'gets the latest version of a legacy policy' {
            $TestParams = @{
                'PolicyID' = $PD.NewCloudletPolicyLegacy.policyId
                'Version'  = 'latest'
                'Legacy'   = $true
            }
            $PD.LatestLegacyPolicyVersion = Get-CloudletPolicyVersion @TestParams @CommonParams
            $PD.LatestLegacyPolicyVersion.Version | Should -Be 2
        }
        It 'gets a specified version of a shared policy' {
            $PD.SharedPolicyVersion = $PD.NewCloudletPolicyShared | Get-CloudletPolicyVersion -Version 1 @CommonParams
            $PD.SharedPolicyVersion.Version | Should -Be 1
        }
        It 'gets the latest version of a shared policy' {
            $PD.LatestSharedPolicyVersion = $PD.NewCloudletPolicyShared | Get-CloudletPolicyVersion -Version latest @CommonParams
            $PD.LatestSharedPolicyVersion.Version | Should -Be 1
        }
        It 'lists all versions of a shared policy' {
            $PD.SharedPolicyVersions = $PD.NewCloudletPolicyShared | Get-CloudletPolicyVersion @CommonParams
            $PD.SharedPolicyVersions[0].Version | Should -Not -BeNullOrEmpty
        }
        It 'handles null input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith { return 'IAR executed' }
            $DebugOutput = & {} | Get-CloudletPolicyVersion
            $DebugOutput | Should -Not -BeLike 'IAR executed'
        }
    }

    Context 'New-CloudletPolicyVersion' {
        It 'creates a new version of a legacy policy by pipeline' {
            $PD.NewCloudletPolicyVersionByPipelineLegacy = $PD.LegacyPolicyVersion | New-CloudletPolicyVersion -Legacy @CommonParams
            $PD.NewCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $PD.NewCloudletPolicyLegacy.policyId
            $PD.NewCloudletPolicyVersionByPipelineLegacy.version | Should -Be 3
        }
        It 'creates a new version of a shared policy by pipeline' {
            $PD.NewCloudletPolicyVersionByPipelineShared = $PD.SharedPolicyVersion | New-CloudletPolicyVersion @CommonParams
            $PD.NewCloudletPolicyVersionByPipelineShared.policyId | Should -Be $PD.NewCloudletPolicyShared.id
            $PD.NewCloudletPolicyVersionByPipelineShared.version | Should -Be 2
        }
    }

    Context 'Set-CloudletPolicyVersion' {
        It 'updates a legacy policy by param' {
            $TestParams = @{
                'Body'     = (ConvertTo-Json -Depth 10 $PD.LegacyPolicyVersion)
                'PolicyID' = $PD.NewCloudletPolicyLegacy.policyId
                'Version'  = $PD.LegacyPolicyVersion.version
                'Legacy'   = $true
            }
            $PD.SetCloudletPolicyVersionByParamLegacy = Set-CloudletPolicyVersion @TestParams @CommonParams
            $PD.SetCloudletPolicyVersionByParamLegacy.policyId | Should -Be $PD.LegacyPolicyVersion.policyId
        }
        It 'updates a legacy policy by pipeline' {
            $PD.SetCloudletPolicyVersionByPipelineLegacy = $PD.LegacyPolicyVersion | Set-CloudletPolicyVersion -Legacy @CommonParams
            $PD.SetCloudletPolicyVersionByPipelineLegacy.policyId | Should -Be $PD.LegacyPolicyVersion.policyId
        }
        It 'updates a shared policy by param' {
            $TestParams = @{
                'Body'     = (ConvertTo-Json -Depth 10 $PD.SharedPolicyVersion)
                'PolicyID' = $PD.NewCloudletPolicyShared.id
                'Version'  = $PD.SharedPolicyVersion.version
            }
            $PD.SetCloudletPolicyVersionByParamShared = Set-CloudletPolicyVersion @TestParams @CommonParams
            $PD.SetCloudletPolicyVersionByParamShared.policyId | Should -Be $PD.SharedPolicyVersion.policyId
        }
        It 'updates a shared policy by pipeline' {
            $PD.SetCloudletPolicyVersionByPipelineShared = $PD.SharedPolicyVersion | Set-CloudletPolicyVersion @CommonParams
            $PD.SetCloudletPolicyVersionByPipelineShared.policyId | Should -Be $PD.SharedPolicyVersion.policyId
        }
    }

    #------------------------------------------------
    #           CloudletPolicyDetails
    #------------------------------------------------

    Context 'Expand-CloudletPolicyDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Cloudlets/Functions/Private/Expand-CloudletPolicyDetails.ps1
        }
        It 'expands a legacy policy' {
            $PD.ExpandCloudletPolicyDetailsLegacy = Expand-CloudletPolicyDetails -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version latest -Legacy @CommonParams
            $PD.ExpandCloudletPolicyDetailsLegacy | Should -Match '[0-9]+'
        }
        It 'expands a shared policy' {
            $PD.ExpandCloudletPolicyDetailsShared = Expand-CloudletPolicyDetails -PolicyID $PD.NewCloudletPolicyShared.id -Version latest @CommonParams
            $PD.ExpandCloudletPolicyDetailsShared | Should -Match '[0-9]+'
        }
        AfterAll {
            Remove-Item -Path Function:/Expand-CloudletPolicyDetails -Force
        }
    }

    #------------------------------------------------
    #              CloudletSchema
    #------------------------------------------------

    Context 'Get-CloudletSchema' {
        It 'lists schemas' {
            $PD.Schemas = Get-CloudletSchema -CloudletType $TestCloudletType @CommonParams
            $PD.Schemas[0].title | Should -Not -BeNullOrEmpty
        }
        It 'returns a specific schema by name' {
            $PD.Schema = Get-CloudletSchema -SchemaName $TestCloudletSchema @CommonParams
            $PD.Schema.title | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #         CloudletPolicyVersionRule
    #------------------------------------------------

    Context 'New-CloudletPolicyVersionRule' {
        It 'creates a new rule by param' {
            $TestParams = @{
                'Body'     = $TestPolicy.matchRules[0]
                'PolicyID' = $PD.NewCloudletPolicyLegacy.policyId
                'Version'  = 2
            }
            $PD.NewRuleParam = New-CloudletPolicyVersionRule @TestParams @CommonParams
            $PD.NewRuleParam.akaRuleId | Should -Not -BeNullOrEmpty
        }
        It 'creates a new rule by pipeline' {
            $PD.NewRulePipeline = $TestPolicy.matchRules[0] | New-CloudletPolicyVersionRule -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 @CommonParams
            $PD.NewRulePipeline.akaRuleId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletPolicyVersionRule' {
        It 'returns the correct data' {
            $PD.Rule = $PD.LatestLegacyPolicyVersion | Get-CloudletPolicyVersionRule -AkaRuleID $PD.LatestLegacyPolicyVersion.matchRules[0].akaruleId @CommonParams
            $PD.Rule.akaRuleId | Should -Be $PD.LegacyPolicyVersion.matchRules[0].akaruleId
        }
    }

    Context 'Set-CloudletPolicyVersionRule' {
        It 'updates a rule by param' {
            $TestParams = @{
                'AkaRuleID' = $PD.LegacyPolicyVersion.matchRules[0].akaruleId
                'Body'      = $PD.LegacyPolicyVersion.matchRules[0]
                'PolicyID'  = $PD.NewCloudletPolicyLegacy.policyId
                'Version'   = 2
            }
            $PD.SetRuleParam = Set-CloudletPolicyVersionRule @TestParams @CommonParams
            $PD.SetRuleParam.akaRuleId | Should -Be $PD.LegacyPolicyVersion.matchRules[0].akaruleId
        }
        It 'updates a rule by pipeline' {
            $PD.SetRulePipeline = $PD.LegacyPolicyVersion.matchRules[0] | Set-CloudletPolicyVersionRule -AkaRuleID $PD.LegacyPolicyVersion.matchRules[0].akaruleId -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Version 2 @CommonParams
            $PD.SetRulePipeline.akaRuleId | Should -Be $PD.LegacyPolicyVersion.matchRules[0].akaruleId
        }
    }

    #------------------------------------------------
    #            CloudletLoadBalancer
    #------------------------------------------------

    Context 'Load Balancer' -Tag 'Load Balancer' {
        Context 'New-CloudletLoadBalancer' {
            It 'creates a load balancer' {
                $TestParams = @{
                    'OriginID' = $TestLoadBalancerID
                }
                $NewCloudletLoadBalancer = New-CloudletLoadBalancer @TestParams @CommonParams
                $NewCloudletLoadBalancer.originId | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-CloudletLoadBalancer' {
            It 'returns a list' {
                $PD.LoadBalancers = Get-CloudletLoadBalancer @CommonParams
                $PD.LoadBalancers[0].originId | Should -Not -BeNullOrEmpty
            }
            It 'returns a single load balancer by ID' {
                $PD.LoadBalancer = Get-CloudletLoadBalancer -OriginID $TestLoadBalancerID @CommonParams
                $PD.LoadBalancer.originId | Should -Be $TestLoadBalancerID
            }
        }

        Context 'Set-CloudletLoadBalancer' {
            It 'updates by param' {
                $PD.SetLoadBalancerParam = Set-CloudletLoadBalancer -Body $PD.LoadBalancer -OriginID $TestLoadBalancerID @CommonParams
                $PD.SetLoadBalancerParam.originId | Should -Be $TestLoadBalancerID
            }
            It 'updates by pipeline' {
                $PD.SetLoadBalancerPipeline = $PD.LoadBalancer | Set-CloudletLoadBalancer @CommonParams
                $PD.SetLoadBalancerPipeline.originId | Should -Be $TestLoadBalancerID
            }
        }

        #------------------------------------------------
        #          CloudletLoadBalancerVersion
        #------------------------------------------------

        Context 'New-CloudletLoadBalancerVersion' {
            It 'creates a new version by param' {
                $PD.NewLBVersionParam = New-CloudletLoadBalancerVersion -Body $ExistingLoadBalancerVersion -OriginID $TestLoadBalancerID @CommonParams
                $PD.NewLBVersionParam.originId | Should -Be $TestLoadBalancerID
            }
            It 'creates a new version by pipeline' {
                $PD.NewLBVersionPipeline = $PD.NewLBVersionParam | New-CloudletLoadBalancerVersion @CommonParams
                $PD.NewLBVersionPipeline.originId | Should -Be $TestLoadBalancerID
            }
        }

        Context 'Get-CloudletLoadBalancerVersion' {
            It 'lists versions' {
                $PD.LoadBalancerVersions = Get-CloudletLoadBalancerVersion -OriginID $TestLoadBalancerID @CommonParams
                $PD.LoadBalancerVersions[0].originId | Should -Be $TestLoadBalancerID
            }
            It 'gets the latest version' {
                $PD.LoadBalancerVersion = $PD.LoadBalancer | Get-CloudletLoadBalancerVersion -Version latest @CommonParams
                $PD.LoadBalancerVersion.originId | Should -Be $TestLoadBalancerID
            }
        }

        Context 'Set-CloudletLoadBalancerVersion' {
            It 'updates by param' {
                $PD.SetLBVersionParam = Set-CloudletLoadBalancerVersion -Body $PD.NewLBVersionPipeline -OriginID $TestLoadBalancerID -Version $PD.NewLBVersionPipeline.version @CommonParams
                $PD.SetLBVersionParam.originId | Should -Be $TestLoadBalancerID
            }
            It 'updates by pipeline' {
                $PD.SetLBVersionPipeline = $PD.NewLBVersionPipeline | Set-CloudletLoadBalancerVersion @CommonParams
                $PD.SetLBVersionPipeline.originId | Should -Be $TestLoadBalancerID
            }
        }

        #------------------------------------------------
        #          CloudletLoadBalancerDetails
        #------------------------------------------------

        Context 'Expand-CloudletLoadBalancerDetails' {
            BeforeAll {
                . $PSScriptRoot/../src/Akamai.Cloudlets/Functions/Private/Expand-CloudletLoadBalancerDetails.ps1
            }
            It 'returns the correct data' {
                $PD.LBDetails = Expand-CloudletLoadBalancerDetails -OriginID $TestLoadBalancerID -Version latest @CommonParams
                $PD.LBDetails | Should -Match '[\d]+'
            }
            AfterAll {
                Remove-Item -Path Function:/Expand-CloudletLoadBalancerDetails -Force
            }
        }

        #------------------------------------------------
        #         CloudletLoadBalancerActivation
        #------------------------------------------------

        Context 'New-CloudletLoadBalancerActivation' {
            It 'returns the correct data' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletLoadBalancerActivation.json"
                    return $Response | ConvertFrom-Json
                }
                $TestParams = @{
                    'Network'  = 'STAGING'
                    'OriginID' = 'test_originId'
                    'Version'  = 1
                }
                $NewCloudletLoadBalancerActivation = New-CloudletLoadBalancerActivation @TestParams
                $NewCloudletLoadBalancerActivation.network | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-CloudletLoadBalancerActivation' {
            It 'gets activations for a single load balancer' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletLoadBalancerActivation.json"
                    return $Response | ConvertFrom-Json
                }
                $TestParams = @{
                    'OriginID' = 'test_originId'
                }
                $GetCloudletLoadBalancerActivationSingle = Get-CloudletLoadBalancerActivation @TestParams
                $GetCloudletLoadBalancerActivationSingle[0].Version | Should -Not -BeNullOrEmpty
            }
            It 'gets activations for all load balancers' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletLoadBalancerActivation.json"
                    return $Response | ConvertFrom-Json
                }
                $GetCloudletLoadBalancerActivationAll = Get-CloudletLoadBalancerActivation
                $GetCloudletLoadBalancerActivationAll.PSObject.Properties.Name.count | Should -BeGreaterThan 0
            }
        }

        Context 'Remove-CloudletLoadBalancer' {
            It 'deletes the load balancer' {
                $PD.LoadBalancer | Remove-CloudletLoadBalancer @CommonParams
            }
        }
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------


    Context 'Remove-CloudletPolicyVersion' {
        It 'throws no errors' {
            $PD.NewCloudletPolicyVersionByPipelineShared | Remove-CloudletPolicyVersion @CommonParams
        }
    }

    Context 'Remove-CloudletPolicy' {
        It 'deletes legacy policy' {
            Remove-CloudletPolicy -PolicyID $PD.NewCloudletPolicyLegacy.policyId -Legacy @CommonParams
        }
        It 'deletes shared policy' {
            Remove-CloudletPolicy -PolicyID $PD.NewCloudletPolicyShared.id @CommonParams
        }
        It 'deletes copy policy' {
            Remove-CloudletPolicy -PolicyID $PD.CopyCloudletPolicy.id @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith { return 'IAR executed' }
            $DebugOutput = & {} | Remove-CloudletPolicy
            $DebugOutput | Should -Not -BeLike 'IAR executed'
        }
    }

    #------------------------------------------------
    #             CloudletActivation
    #------------------------------------------------

    Context 'New-CloudletPolicyActivation' {
        It 'activates a legacy policy' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AdditionalPropertyNames' = 'www'
                'Network'                 = 'STAGING'
                'PolicyID'                = 111111
                'Version'                 = 1
            }
            $NewCloudletActivationLegacy = New-CloudletPolicyActivation @TestParams
            $NewCloudletActivationLegacy.policyInfo.policyId | Should -Not -BeNullOrEmpty
        }
        It 'activates a shared policy' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'  = 'STAGING'
                'PolicyID' = 22222
                'Version'  = 1
            }
            $NewCloudletActivationShared = New-CloudletPolicyActivation @TestParams
            $NewCloudletActivationShared.policyId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #             CloudletDeactivation
    #------------------------------------------------

    Context 'New-CloudletPolicyDeactivation' {
        It 'deactivates a shared policy' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudletPolicyDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'  = 'STAGING'
                'PolicyID' = 22222
                'Version'  = 1
            }
            $NewCloudletDeactivation = New-CloudletPolicyDeactivation @TestParams
            $NewCloudletDeactivation.policyId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #            CloudletPolicyProperty
    #------------------------------------------------

    Context 'Get-CloudletPolicyProperty' -Tag 'Get-CloudletPolicyProperty' {
        It 'returns properties from a legacy policy' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PolicyID' = 111111
                'Legacy'   = $true
            }
            $PolicyPropertyLegacy = Get-CloudletPolicyProperty @TestParams
            $PolicyPropertyLegacy.cloudletsOrigins | Should -Not -BeNullOrEmpty
        }
        It 'returns properties from a shared policy' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyProperty_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PolicyID' = 22222
            }
            $PolicyPropertyShared = Get-CloudletPolicyProperty @TestParams
            $PolicyPropertyShared[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudletProperty' {
        It 'returns a dictionary' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletProperty.json"
                return $Response | ConvertFrom-Json
            }
            $GetCloudletProperty = Get-CloudletProperty
            $GetCloudletProperty.PSObject.Properties.Name.Count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #           CloudletPolicyActivation
    #------------------------------------------------

    Context 'Get-CloudletPolicyActivation' {
        It 'returns a single activation' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ActivationID' = 1234
                'PolicyID'     = 22222
            }
            $PolicyActivation = Get-CloudletPolicyActivation @TestParams
            $PolicyActivation.network | Should -Not -BeNullOrEmpty
        }
        It 'returns a list of legacy activations' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PolicyID' = 11111
                'Legacy'   = $true
            }
            $PolicyActivationsLegacy = Get-CloudletPolicyActivation @TestParams
            $PolicyActivationsLegacy[0].policyInfo.policyId | Should -Not -BeNullOrEmpty
        }
        It 'returns a list of shared activations' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.Cloudlets -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudletPolicyActivation_2.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'PolicyID' = 22222
            }
            $PolicyActivationsShared = Get-CloudletPolicyActivation @TestParams
            $PolicyActivationsShared[0].id | Should -Not -BeNullOrEmpty
        }
    }
}

