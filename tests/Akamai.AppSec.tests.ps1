BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.AppSec Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.AppSec'
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
        $TestConfigName = "pester-$Timestamp"
        $TestConfigDescription = "Powershell pester testing. Will be deleted shortly."
        $TestContractID = $env:PesterContractID
        $TestGroupID = [int] $env:PesterGroupID
        $TestHostname = $env:PesterHostname
        $TestFailoverHostname = $env:PesterFailoverHostname
        $TestNewHostname = $env:PesterHostname2
        $TestAPIEndpointID = $env:PesterAPIEndpointID
        $TestCustomRule = '{"conditions":[{"type":"pathMatch","positiveMatch":true,"value":["/test"],"valueCase":false,"valueIgnoreSegment":false,"valueNormalize":false,"valueWildcard":true}],"name":"cr1","operation":"AND","ruleActivated":false,"structured":true,"tag":["tag1"],"version":1}'
        $TestNotes = "Akamai PowerShell Test"
        $TestPolicyName = 'Example'
        $TestPolicyPrefix = 'EX01'
        $TestPolicyMode = 'ASE_MANUAL'
        $TestAPIMatchTargetBody = @"
{"type":"api","apis":[{"id":$TestAPIEndpointID}],"securityPolicy":{"policyId":"REPLACE_POLICY_ID"}}
"@
        $TestAPIMatchTarget = ConvertFrom-Json $TestAPIMatchTargetBody
        $TestSiteMatchTargetBody = @"
{"type":"website","hostnames": [ "$TestHostname" ], "filePaths": [ "/*" ], "securityPolicy": { "policyId": "REPLACE_POLICY_ID" }}
"@
        $TestSiteMatchTarget = ConvertFrom-Json $TestSiteMatchTargetBody
        $TestNetworkListID = $env:PesterNetworkListID
        $TestCustomDenyName = 'SampleCustomDeny'
        $TestCustomDenyBody = @"
{"name":"$TestCustomDenyName","description": "Old Description","parameters":[{"displayName":"Hostname","name":"custom_deny_hostname","value":"$TestFailoverHostname"},{"displayName":"Path","name":"custom_deny_path","value":"/"},{"displayName":"IncludeAkamaiReferenceID","name":"include_reference_id","value":"true"},{"displayName":"IncludeTrueClientIP","name":"include_true_ip","value":"false"},{"displayName":"Preventbrowsercaching","name":"prevent_browser_cache","value":"true"},{"displayName":"Responsecontenttype","name":"response_content_type","value":"application/json"},{"displayName":"Responsestatuscode","name":"response_status_code","value":"403"}]}
"@
        $TestRatePolicy1Name = 'Rate Policy 1'
        $TestRatePolicy2Name = 'Rate Policy 2'
        $TestRatePolicyBody = @"
{"averageThreshold":10,"burstThreshold":50,"clientIdentifier":"ip","matchType":"path","name":"$TestRatePolicy1Name","path":{"positiveMatch":true,"values":["/*"]},"pathMatchType":"Custom","pathUriPositiveMatch":true,"requestType":"ClientRequest","sameActionOnIpv6":false,"type":"WAF","useXForwardForHeaders":false}
"@
        $TestRatePolicy = ConvertFrom-Json $TestRatePolicyBody
        $TestRatePolicy.name = $TestRatePolicy2Name
        $TestSiemSettingsBody = '{"enableSiem":true,"enableForAllPolicies":true, "siemDefinitionId": 1}'
        $TestSiemSettings = ConvertFrom-Json $TestSiemSettingsBody
        $TestReputationProfile1Name = "AkamaiPowerShell Reputation Profile 1"
        $TestReputationProfile2Name = "AkamaiPowerShell Reputation Profile 2"
        $TestReputationProfileBody = @"
{"context":"DOSATCK","contextReadable":"DoSAttackers","enabled":true,"name":"$TestReputationProfile1Name","sharedIpHandling":"BOTH","threshold":7}
"@
        $TestReputationProfile = ConvertFrom-Json $TestReputationProfileBody
        $TestReputationProfile.name = $TestReputationProfile2Name
        $TestPragmaSettingsBody = '{"action":"REMOVE","conditionOperator":"AND"}'
        $TestPragmaSettings = ConvertFrom-Json $TestPragmaSettingsBody
        $TestExceptionBody = '{"exception":{"specificHeaderCookieParamXmlOrJsonNames":[{"names":["ExceptMe"],"selector":"REQUEST_HEADERS","wildcard":true}]}}'
        $TestException = ConvertFrom-Json $TestExceptionBody
        $TestRuleID = 950002
        $TestAttackGroupID = 'CMD'
        $TestURLProtectionPolicyJSON = @"
{"hostnamePaths":[{"hostname":"$TestHostname","paths":["/login"]}],"intelligentLoadShedding":false,"name":"Powershell test policy","rateThreshold":195}
"@
        $TestMalwarePolicyName = 'Powershell testing'
        $TestMalwarePolicyJSON = @"
{ "name": "$TestMalwarePolicyName", "hostnames": [], "paths": ["/*"] }
"@
        $TestHostnamesToAdd = @"
    {
        "hostnameList": [
            {
                "hostname": "$TestNewHostname"
            }
        ]
    }
"@
        $TestActivationJSON = @"
{
  "action": "ACTIVATE",
  "activationConfigs": [
    {
      "configId": 12345,
      "configVersion": 4
    }
  ],
  "network": "STAGING",
  "note": "Test",
  "notificationEmails": [
    "mail@example.com"
  ]
}
"@
        $TestCPCConfigID = $env:PesterCPCConfig
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.AppSec"
        $PD = @{}
    }

    AfterAll {
        Get-AppSecConfiguration @CommonParams | Where-Object name -eq $TestConfigName | Remove-AppSecConfiguration @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #-------------------------------------------------
    #                 Configuration
    #-------------------------------------------------

    Context 'New-AppSecConfiguration' {
        It 'creates successfully' {
            $TestParams = @{
                'Name'        = $TestConfigName
                'Description' = $TestConfigDescription
                'GroupID'     = $TestGroupID
                'ContractId'  = $TestContractID
                'Hostnames'   = $TestHostname
            }
            $PD.NewConfig = New-AppSecConfiguration @TestParams @CommonParams
            $PD.NewConfig.name | Should -Be $TestConfigName
        }
    }

    Context 'Get-AppSecConfiguration' {
        It 'gets a list of configs' {
            $PD.Configs = Get-AppSecConfiguration @CommonParams
            $PD.Configs | Should -Not -BeNullOrEmpty
        }
        It 'gets a config by name' {
            $TestParams = @{
                'ConfigName' = $TestConfigName
            }
            $PD.ConfigByName = Get-AppSecConfiguration @TestParams @CommonParams
            $PD.ConfigByName.name | Should -Be $TestConfigName
        }
        It 'get a config by ID' {
            $TestParams = @{
                'ConfigID' = $PD.NewConfig.configId
            }
            $PD.Config = Get-AppSecConfiguration @TestParams @CommonParams
            $PD.Config.name | Should -Be $TestConfigName
        }
        It 'get a config by pipeline' {
            $Config = $PD.NewConfig | Get-AppSecConfiguration @CommonParams
            $Config.name | Should -Be $TestConfigName
        }
    }

    Context 'Rename-AppSecConfiguration' {
        It 'successfully renames by param' {
            $TestParams = @{
                'ConfigID'    = $PD.Config.id
                'NewName'     = $TestConfigName
                'Description' = $TestConfigDescription
            }
            $RenameResult = Rename-AppSecConfiguration @TestParams @CommonParams
            $RenameResult.Name | Should -Be $TestConfigName
        }
        It 'successfully renames by pipeline' {
            $TestParams = @{
                'NewName'     = $TestConfigName
                'Description' = $TestConfigDescription
            }
            $RenameResult = $PD.Config | Rename-AppSecConfiguration @TestParams @CommonParams
            $RenameResult.Name | Should -Be $TestConfigName
        }
    }

    #-------------------------------------------------
    #                  Custom Rules
    #-------------------------------------------------

    Context 'New-AppSecCustomRule' {
        It 'creates successfully' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
                'Body'     = $TestCustomRule
            }
            $PD.NewCustomRule = New-AppSecCustomRule @TestParams @CommonParams
            $PD.NewCustomRule.id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecCustomRule' {
        It 'gets a list of rules by param' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
            }
            $CustomRules = Get-AppSecCustomRule @TestParams @CommonParams
            $CustomRules | Should -Not -BeNullOrEmpty
        }
        It 'gets a list of rules by pipeline' {
            $PD.CustomRules = $PD.Config | Get-AppSecCustomRule @CommonParams
            $PD.CustomRules | Should -Not -BeNullOrEmpty
        }
        It 'gets a single rule by ID' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
                'RuleID'   = $PD.NewCustomRule.id
            }
            $PD.CustomRule = Get-AppSecCustomRule @TestParams @CommonParams
            $PD.CustomRule.id | Should -Be $PD.NewCustomRule.id
        }
    }

    Context 'Set-AppSecCustomRule' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
            }
            $PD.SetCustomRule = $PD.NewCustomRule | Set-AppSecCustomRule @TestParams @CommonParams
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
                'RuleID'   = $PD.NewCustomRule.id
                'Body'     = $TestCustomRule
            }
            $PD.SetCustomRule = Set-AppSecCustomRule @TestParams @CommonParams
        }
    }

    #-------------------------------------------------
    #               Failover Hostnames
    #-------------------------------------------------

    Context 'Get-AppSecFailoverHostnames' {
        It 'does not throw' {
            $PD.FailoverHostnames = $PD.Config | Get-AppSecFailoverHostnames @CommonParams
        }
    }

    #-------------------------------------------------
    #                    Versions
    #-------------------------------------------------

    Context 'Get-AppSecConfigurationVersion' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID' = $PD.Config.id
            }
            $Versions = Get-AppSecConfigurationVersion @TestParams @CommonParams
            $Versions[0].configId | Should -Be $PD.Config.id
        }
        It 'gets a list by pipeline' {
            $PD.Versions = $PD.Config | Get-AppSecConfigurationVersion @CommonParams
            $PD.Versions[0].configId | Should -Be $PD.Config.id
        }
        It 'gets a single version' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.Version = Get-AppSecConfigurationVersion @TestParams @CommonParams
            $PD.Version.version | Should -Be 1
        }
    }

    Context 'New-AppSecConfigurationVersion' {
        It 'creates a new version by param' {
            $TestParams = @{
                'ID'                = $PD.Version.configId
                'CreateFromVersion' = $PD.Version.version
            }
            $PD.NewVersionParam = New-AppSecConfigurationVersion @TestParams @CommonParams
            $PD.NewVersionParam.configId | Should -Be $PD.Config.id
        }
        It 'creates a new version by pipeline' {
            $PD.NewVersion = $PD.Version | New-AppSecConfigurationVersion @CommonParams
            $PD.NewVersion.configId | Should -Be $PD.Config.id
        }
    }

    Context 'Remove-AppSecConfigurationVersion' {
        It 'removes by param' {
            $TestParams = @{
                'ID'            = $PD.NewVersionParam.configId
                'VersionNumber' = $PD.NewVersionParam.version
            }
            Remove-AppSecConfigurationVersion @TestParams @CommonParams
        }
        It 'removes by pipeline' {
            $PD.NewVersion | Remove-AppSecConfigurationVersion @CommonParams
        }
        It 'should throw for a missing version' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 100
            }
            { Get-AppSecConfigurationVersion @TestParams @CommonParams } | Should -Throw
        }
    }

    #-------------------------------------------------
    #               Version Notes
    #-------------------------------------------------

    Context 'Set-AppSecVersionNotes' {
        It 'sets notes correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Notes'         = $TestNotes
            }
            $PD.SetNotes = Set-AppSecVersionNotes @TestParams @CommonParams
            $PD.SetNotes | Should -Be $TestNotes
        }
    }

    Context 'Get-AppSecVersionNotes' {
        It 'gets notes correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.GetNotes = Get-AppSecVersionNotes @TestParams @CommonParams
            $PD.GetNotes | Should -Be $TestNotes
        }
    }

    #-------------------------------------------------
    #                    Hostnames
    #-------------------------------------------------

    Context 'Get-AppSecSelectableHostname' {
        It 'gets a list by param' {
            $TestParams = @{
                'ID'            = $PD.Version.configId
                'VersionNumber' = $PD.Version.version
            }
            $SelectableHostnames = Get-AppSecSelectableHostnames @TestParams @CommonParams
            $SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
        }
        It 'gets a list by pipeline' {
            $PD.SelectableHostnames = $PD.Version | Get-AppSecSelectableHostnames @CommonParams
            $PD.SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecSelectedHostnames' {
        It 'gets a list by param' {
            $TestParams = @{
                'ID'            = $PD.Version.configId
                'VersionNumber' = $PD.Version.version
            }
            $SelectedHostnames = Get-AppSecSelectedHostnames @TestParams @CommonParams
            $SelectedHostnames.hostnameList.hostname | Should -Be $TestHostname
        }
        It 'gets a list by pipeline' {
            $PD.SelectedHostnames = $PD.Version | Get-AppSecSelectedHostnames @CommonParams
            $PD.SelectedHostnames.hostnameList.hostname | Should -Be $TestHostname
        }
    }

    Context 'Add-AppSecSelectedHostnames' {
        It 'adds a hostname successfully' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestHostnamesToAdd
            }
            $PD.AddedHostnames = Add-AppSecSelectedHostnames @TestParams @CommonParams
            $PD.AddedHostnames.hostnameList.hostname | Should -Contain $TestNewHostname
        }
    }

    Context 'Set-AppSecSelectedHostnames' {
        It 'adds a hostname successfully' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $PD.AddedHostnames
            }
            $PD.UpdatedHostnames = Set-AppSecSelectedHostnames @TestParams @CommonParams
            $PD.UpdatedHostnames.hostnameList.count | Should -Be 2
        }
    }

    Context 'Remove-AppSecSelectedHostnames' {
        It 'removes the correct hostname' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.RemovedHostnames = $TestHostnamesToAdd | Remove-AppSecSelectedHostnames @TestParams @CommonParams
            $PD.RemovedHostnames.hostnameList.hostname | Should -Not -Contain $TestNewHostname
        }
    }

    Context 'Get-AppSecAvailableHostname' {
        It 'gets a list' {
            $TestParams = @{
                'ContractID' = $TestContractID
                'GroupID'    = $TestGroupID
            }
            $PD.SelectableHostnames = Get-AppSecAvailableHostnames @TestParams @CommonParams
            $PD.SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                    Policies
    #-------------------------------------------------

    Context 'New-AppSecPolicy' {
        It 'creates correctly without cloning' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyName'    = $TestPolicyName
                'PolicyPrefix'  = $TestPolicyPrefix
            }
            $PD.NewPolicy = New-AppSecPolicy @TestParams @CommonParams
            $PD.NewPolicy.policyName | Should -Be $TestPolicyName
        }
        It 'creates correctly by cloning policy by name' {
            $TestParams = @{
                'ConfigID'             = $PD.Config.id
                'VersionNumber'        = 1
                'PolicyName'           = "$TestPolicyName-clonename"
                'PolicyPrefix'         = "clo1"
                'CreateFromPolicyName' = $TestPolicyName
            }
            $PD.NewPolicyCloneName = New-AppSecPolicy @TestParams @CommonParams
            $PD.NewPolicyCloneName.policyName | Should -Be "$TestPolicyName-clonename"
        }
        It 'creates correctly by cloning policy by ID' {
            $TestParams = @{
                'ConfigID'           = $PD.Config.id
                'VersionNumber'      = 1
                'PolicyName'         = "$TestPolicyName-cloneid"
                'PolicyPrefix'       = "clo2"
                'CreateFromPolicyID' = $PD.NewPolicy.policyId
            }
            $PD.NewPolicyCloneID = New-AppSecPolicy @TestParams @CommonParams
            $PD.NewPolicyCloneID.policyName | Should -Be "$TestPolicyName-cloneid"
        }
    }

    Context 'Get-AppSecPolicy' {
        It 'returns a list with no policy name or ID' {
            $PD.Policies = $PD.Version | Get-AppSecPolicy @CommonParams
            $PD.Policies[0].policyId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct policy by ID by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Version.configId
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $Policy = Get-AppSecPolicy @TestParams @CommonParams
            $Policy.policyId | Should -Be $PD.NewPolicy.policyId
        }
        It 'returns the correct policy by ID by pipeline' {
            $TestParams = @{
                'PolicyID' = $PD.NewPolicy.policyId
            }
            $PD.Policy = $PD.Version | Get-AppSecPolicy @TestParams @CommonParams
            $PD.Policy.policyId | Should -Be $PD.NewPolicy.policyId
        }
        It 'by name returns the correct policy' {
            $TestParams = @{
                'ConfigName'    = $TestConfigName
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.PolicyByName = Get-AppSecPolicy @TestParams @CommonParams
            $PD.PolicyByName.policyId | Should -Be $PD.NewPolicy.policyId
        }
        It 'fails when name does not exist' {
            $TestParams = @{
                'ConfigName'    = $TestConfigName
                'VersionNumber' = 1
                'PolicyName'    = "not-a-real-policy"
            }
            { Get-AppSecPolicy @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Set-AppSecPolicy' {
        It 'renames a policy' {
            $TestParams = @{
                'NewName' = "Temp"
            }
            $PD.RenamePolicy = $PD.Policy | Set-AppSecPolicy @TestParams @CommonParams
            $PD.RenamePolicy.policyName | Should -Be "Temp"
        }
        It 'changes the name back to the original' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.Policy.policyId
                'NewName'       = $TestPolicyName
            }
            $PD.SetPolicy = Set-AppSecPolicy @TestParams @CommonParams
            $PD.SetPolicy.policyName | Should -Be $TestPolicyName
        }
    }

    #-------------------------------------------------
    #                  Match Targets
    #-------------------------------------------------

    Context 'New-AppSecMatchTarget' {
        It 'creates an api target' {
            $TestAPIMatchTarget.securityPolicy.policyId = $PD.NewPolicy.policyId
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestAPIMatchTarget
            }
            $PD.NewAPIMatchTarget = New-AppSecMatchTarget @TestParams @CommonParams
            $PD.NewAPIMatchTarget.configId | Should -Be $PD.Config.id
        }
        It 'creates a website target' {
            $TestSiteMatchTarget.securityPolicy.policyId = $PD.NewPolicy.policyId
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestSiteMatchTarget
            }
            $PD.NewWebsiteMatchTarget = New-AppSecMatchTarget @TestParams @CommonParams
            $PD.NewWebsiteMatchTarget.configId | Should -Be $PD.Config.id
        }
    }

    Context 'Get-AppSecMatchTarget' {
        It 'returns a list by param' {
            $TestParams = @{
                'ID'            = $PD.Version.configId
                'VersionNumber' = $PD.Version.version
            }
            $MatchTargets = Get-AppSecMatchTarget @TestParams @CommonParams
            $MatchTargets.apiTargets | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $PD.MatchTargets = $PD.Version | Get-AppSecMatchTarget @CommonParams
            $PD.MatchTargets.apiTargets | Should -Not -BeNullOrEmpty
        }
        Context 'get single target by ID' {
            BeforeAll {
                $TestParams = @{
                    'TargetID' = $PD.NewAPIMatchTarget.targetId
                }
            }
            It 'returns the correct target by param' {
                $TestParams = @{
                    'ID'            = $PD.Version.configId
                    'VersionNumber' = $PD.Version.version
                    'TargetID'      = $PD.NewAPIMatchTarget.targetId
                }
                $MatchTarget = Get-AppSecMatchTarget @TestParams @CommonParams
                $MatchTarget.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
                $MatchTarget.type | Should -Be 'api'
                $MatchTarget.apis[0].id | Should -Be $TestAPIEndpointID
                $MatchTarget.apis[0].name | Should -Not -BeNullOrEmpty
                $MatchTarget.sequence | Should -Not -BeNullOrEmpty
            }
            It 'returns the correct target by pipeline' {
                $PD.MatchTarget = $PD.Policy | Get-AppSecMatchTarget @TestParams @CommonParams
                $PD.MatchTarget.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
                $PD.MatchTarget.type | Should -Be 'api'
                $PD.MatchTarget.apis[0].id | Should -Be $TestAPIEndpointID
                $PD.MatchTarget.apis[0].name | Should -Not -BeNullOrEmpty
                $PD.MatchTarget.sequence | Should -Not -BeNullOrEmpty
            }
            It 'does not include names when set to do so' {
                # Pull again to check OmitChildObjects param
                $MatchTargetNoNames = $PD.Policy | Get-AppSecMatchTarget -OmitChildObjectName @TestParams @CommonParams
                $MatchTargetNoNames.apis[0].name | Should -BeNullOrEmpty
            }
            It 'does not include names when set to do so with alias' {
                # Pull again to check aliased IncludeChildObjectName param
                $MatchTargetNoNames = $PD.Policy | Get-AppSecMatchTarget -IncludeChildObjectName @TestParams @CommonParams
                $MatchTargetNoNames.apis[0].name | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Set-AppSecMatchTarget' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetMatchTargetByPipeline = $PD.NewAPIMatchTarget | Set-AppSecMatchTarget @TestParams @CommonParams
            $PD.SetMatchTargetByPipeline.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'TargetID'      = $PD.NewAPIMatchTarget.targetId
                'Body'          = $PD.NewAPIMatchTarget
            }
            $PD.SetMatchTargetByParam = Set-AppSecMatchTarget @TestParams @CommonParams
            $PD.SetMatchTargetByParam.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
        }
    }

    Context 'Set-AppSecMatchTargetOrder' {
        BeforeAll {
            $TargetOrder = @{
                'targetSequence' = @(
                    @{
                        'sequence' = 1
                        'targetId' = $PD.NewWebsiteMatchTarget.targetId
                    }
                )
                'type'           = "website"
            }
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetMatchTargetOrderByPipeline = $TargetOrder | Set-AppSecMatchTargetOrder @TestParams @CommonParams
            $PD.SetMatchTargetOrderByPipeline.targetSequence[0].targetId | Should -Be $PD.NewWebsiteMatchTarget.targetId
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TargetOrder
            }
            $PD.SetMatchTargetOrderByParam = Set-AppSecMatchTargetOrder @TestParams @CommonParams
            $PD.SetMatchTargetOrderByParam.targetSequence[0].targetId | Should -Be $PD.NewWebsiteMatchTarget.targetId
        }
    }

    #-------------------------------------------------
    #                IP/Geo Firewall
    #-------------------------------------------------

    Context 'Get-AppSecPolicyIPGeoFirewall' {
        It 'gets the policy by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $IPGeo = Get-AppSecPolicyIPGeoFirewall @TestParams @CommonParams
            $IPGeo.block | Should -Not -BeNullOrEmpty
        }
        It 'gets the policy by pipeline' {
            $PD.IPGeo = $PD.Policy | Get-AppSecPolicyIPGeoFirewall @CommonParams
            $PD.IPGeo.block | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyIPGeoFirewall by pipeline' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetIPGeoByPipeline = $PD.IPGeo | Set-AppSecPolicyIPGeoFirewall @TestParams @CommonParams
            $PD.SetIPGeoByPipeline.block | Should -Be $PD.IPGeo.block
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = $PD.IPGeo
            }
            $PD.SetIPGeoByParam = Set-AppSecPolicyIPGeoFirewall @TestParams @CommonParams
            $PD.SetIPGeoByParam.block | Should -Be $PD.IPGeo.block
        }
    }

    #-------------------------------------------------
    #                  Rate Policies
    #-------------------------------------------------

    Context 'New-AppSecRatePolicy' {
        It 'creates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestRatePolicyBody
            }
            $PD.NewRatePolicyByBody = New-AppSecRatePolicy @TestParams @CommonParams
            $PD.NewRatePolicyByBody.name | Should -Be $TestRatePolicy1Name
        }
        It 'creates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.NewRatePolicyByPipeline = $TestRatePolicy | New-AppSecRatePolicy @TestParams @CommonParams
            $PD.NewRatePolicyByPipeline.name | Should -Be $TestRatePolicy2Name
        }
    }

    Context 'Get-AppSecRatePolicy' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $RatePolicies = Get-AppSecRatePolicy @TestParams @CommonParams
            $RatePolicies.count | Should -Be 2
        }
        It 'gets a list by pipeline' {
            $PD.RatePolicies = $PD.Version | Get-AppSecRatePolicy @CommonParams
            $PD.RatePolicies.count | Should -Be 2
        }
        It 'gets a single policy by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
            }
            $PD.RatePolicy = Get-AppSecRatePolicy @TestParams @CommonParams
            $PD.RatePolicy.name | Should -Be $TestRatePolicy1Name
        }
    }

    Context 'Set-AppSecRatePolicy' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetRatePolicyByPipeline = $PD.NewRatePolicyByBody | Set-AppSecRatePolicy @TestParams @CommonParams
            $PD.SetRatePolicyByPipeline.name | Should -Be $TestRatePolicy1Name
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'Body'          = $PD.NewRatePolicyByBody
            }
            $PD.SetRatePolicyByParam = Set-AppSecRatePolicy @TestParams @CommonParams
            $PD.SetRatePolicyByParam.name | Should -Be $TestRatePolicy1Name
        }
    }

    #-------------------------------------------------
    #                   Custom Deny
    #-------------------------------------------------

    Context 'New-AppSecCustomDenyAction' {
        It 'creates correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestCustomDenyBody
            }
            $PD.NewCustomDenyAction = New-AppSecCustomDenyAction @TestParams @CommonParams
            $PD.NewCustomDenyAction.name | Should -Be $TestCustomDenyName
        }
    }

    Context 'Get-AppSecCustomDenyAction' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $CustomDenyActions = Get-AppSecCustomDenyAction @TestParams @CommonParams
            $CustomDenyActions[0].name | Should -Be $TestCustomDenyName
        }
        It 'gets a list of actions by pipeline' {
            $PD.CustomDenyActions = $PD.Version | Get-AppSecCustomDenyAction @CommonParams
            $PD.CustomDenyActions[0].name | Should -Be $TestCustomDenyName
        }
        It 'gets a single action by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'CustomDenyID'  = $PD.NewCustomDenyAction.id
            }
            $PD.CustomDenyAction = Get-AppSecCustomDenyAction @TestParams @CommonParams
            $PD.CustomDenyAction.name | Should -Be $TestCustomDenyName
        }
    }

    Context 'Set-AppSecCustomDenyAction' {
        It 'updates by pipeline' {
            $PD.NewCustomDenyAction.description = "updated"
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetCustomDenyActionByPipeline = $PD.NewCustomDenyAction | Set-AppSecCustomDenyAction @TestParams @CommonParams
            $PD.SetCustomDenyActionByPipeline.description | Should -Be "updated"
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'CustomDenyID'  = $PD.NewCustomDenyAction.id
                'Body'          = $PD.NewCustomDenyAction
            }
            $PD.SetCustomDenyActionByParam = Set-AppSecCustomDenyAction @TestParams @CommonParams
            $PD.NewCustomDenyAction.description = "updated"
            $PD.SetCustomDenyActionByParam.description | Should -Be "updated"
        }
    }

    #-------------------------------------------------
    #                       SIEM
    #-------------------------------------------------


    Context 'Set-AppSecSiemSettings' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestSiemSettingsBody
            }
            $PD.SetSIEMSettings = Set-AppSecSiemSettings @TestParams @CommonParams
            $PD.SetSIEMSettings.enableForAllPolicies | Should -Be $true
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetSIEMSettings = $TestSiemSettings | Set-AppSecSiemSettings @TestParams @CommonParams
            $PD.SetSIEMSettings.enableForAllPolicies | Should -Be $true
        }
    }

    Context 'Get-AppSecSiemSettings' {
        It 'gets the right settings' {
            $PD.SIEMSettings = $PD.Version | Get-AppSecSiemSettings @CommonParams
            $PD.SIEMSettings.enableForAllPolicies | Should -Be $true
        }
    }

    #-------------------------------------------------
    #               Reputation Profiles
    #-------------------------------------------------

    Context 'New-AppSecReputationProfile' {
        It 'creates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestReputationProfileBody
            }
            $PD.NewReputationProfileByBody = New-AppSecReputationProfile @TestParams @CommonParams
            $PD.NewReputationProfileByBody.name | Should -Be $TestReputationProfile1Name
        }
        It 'creates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.NewReputationProfileByPipeline = $TestReputationProfile | New-AppSecReputationProfile @TestParams @CommonParams
            $PD.NewReputationProfileByPipeline.name | Should -Be $TestReputationProfile2Name
        }
    }

    Context 'Get-AppSecReputationProfile' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $ReputationProfiles = Get-AppSecReputationProfile @TestParams @CommonParams
            $ReputationProfiles.count | Should -Not -BeNullOrEmpty
        }
        It 'gets a list by pipeline' {
            $PD.ReputationProfiles = $PD.Version | Get-AppSecReputationProfile @CommonParams
            $PD.ReputationProfiles.count | Should -Not -BeNullOrEmpty
        }
        It 'gets a single profile by ID' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 1
                'ReputationProfileID' = $PD.NewReputationProfileByBody.id
            }
            $PD.ReputationProfile = Get-AppSecReputationProfile @TestParams @CommonParams
            $PD.ReputationProfile.id | Should -Be $PD.NewReputationProfileByBody.id
        }
    }

    Context 'Set-AppSecReputationProfile' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetReputationProfileByPipeline = $PD.NewReputationProfileByBody | Set-AppSecReputationProfile @TestParams @CommonParams
            $PD.SetReputationProfileByPipeline.id | Should -Be $PD.NewReputationProfileByBody.id
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 1
                'ReputationProfileID' = $PD.NewReputationProfileByBody.id
                'Body'                = $PD.NewReputationProfileByBody
            }
            $PD.SetReputationProfileByParam = Set-AppSecReputationProfile @TestParams @CommonParams
            $PD.SetReputationProfileByParam.id | Should -Be $PD.NewReputationProfileByBody.id
        }
    }

    #-------------------------------------------------
    #                    Advanced
    #-------------------------------------------------

    Context 'Get-AppSecEvasivePathMatch' {
        It 'returns the settings by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $EvasivePathMatch = Get-AppSecEvasivePathMatch @TestParams @CommonParams
            $EvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
        It 'returns the settings by pipeline' {
            $PD.EvasivePathMatch = $PD.Version | Get-AppSecEvasivePathMatch @CommonParams
            $PD.EvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecEvasivePathMatch' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = 1
                'EnablePathMatch' = $true
            }
            $PD.SetEvasivePathMatch = Set-AppSecEvasivePathMatch @TestParams @CommonParams
            $PD.SetEvasivePathMatch.enablePathMatch | Should -Be $true
        }
    }

    Context 'Get-AppSecLogging' {
        It 'returns the settings by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $Logging = Get-AppSecLogging @TestParams @CommonParams
            $Logging.allowSampling | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.Logging = $PD.Version | Get-AppSecLogging @CommonParams
            $PD.Logging.allowSampling | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecLogging' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetLoggingByPipeline = $PD.Logging | Set-AppSecLogging @TestParams @CommonParams
            $PD.SetLoggingByPipeline.allowSampling | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = ConvertTo-Json -Depth 10 $PD.Logging
            }
            $PD.SetLoggingByBody = Set-AppSecLogging @TestParams @CommonParams
            $PD.SetLoggingByBody.allowSampling | Should -Not -BeNullOrEmpty
        }
    }


    Context 'Set-AppSecPragmaSettings' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $TestPragmaSettingsBody
            }
            $PD.SetPragmaSettingsByBody = Set-AppSecPragmaSettings @TestParams @CommonParams
            $PD.SetPragmaSettingsByBody.action | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetPragmaSettingsByPipeline = $TestPragmaSettings | Set-AppSecPragmaSettings @TestParams @CommonParams
            $PD.SetPragmaSettingsByPipeline.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPragmaSettings' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PragmaSettings = Get-AppSecPragmaSettings @TestParams @CommonParams
            $PragmaSettings.action | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PragmaSettings = $PD.Version | Get-AppSecPragmaSettings @CommonParams
            $PD.PragmaSettings.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPrefetch' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $Prefetch = Get-AppSecPrefetch @TestParams @CommonParams
            $Prefetch.enableAppLayer | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.Prefetch = $PD.Version | Get-AppSecPrefetch @CommonParams
            $PD.Prefetch.enableAppLayer | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPrefetch' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetPrefetchByPipeline = $PD.Prefetch | Set-AppSecPrefetch @TestParams @CommonParams
            $PD.SetPrefetchByPipeline.enableAppLayer | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = ConvertTo-Json -Depth 10 $PD.Prefetch
            }
            $PD.SetPrefetchByBody = Set-AppSecPrefetch @TestParams @CommonParams
            $PD.SetPrefetchByBody.enableAppLayer | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecRequestSizeLimit' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $RequestSizeLimit = Get-AppSecRequestSizeLimit @TestParams @CommonParams
            $RequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.RequestSizeLimit = $PD.Version | Get-AppSecRequestSizeLimit @CommonParams
            $PD.RequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecRequestSizeLimit' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'         = $PD.Config.id
                'VersionNumber'    = 1
                'RequestSizeLimit' = 32
            }
            $PD.SetRequestSizeLimit = Set-AppSecRequestSizeLimit @TestParams @CommonParams
            $PD.SetRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 32
        }
    }

    Context 'Get-AppSecAttackPayload' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $AttackPayload = Get-AppSecAttackPayload @TestParams @CommonParams
            $AttackPayload.requestBody | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.AttackPayload = $PD.Version | Get-AppSecAttackPayload @CommonParams
            $PD.AttackPayload.requestBody | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecAttackPayload' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Body'          = $PD.AttackPayload
            }
            $PD.SetAttackPayloadByBody = Set-AppSecAttackPayload @TestParams @CommonParams
            $PD.SetAttackPayloadByBody.requestBody | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetAttackPayloadByPipeline = $PD.AttackPayload | Set-AppSecAttackPayload @TestParams @CommonParams
            $PD.SetAttackPayloadByPipeline.requestBody | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPIISettings' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PIISettings = Get-AppSecPIISettings @TestParams @CommonParams
            $PIISettings.enablePiiLearning | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PIISettings = $PD.Version | Get-AppSecPIISettings @CommonParams
            $PD.PIISettings.enablePiiLearning | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPIISettings' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'          = $PD.Config.id
                'VersionNumber'     = 1
                'EnablePIILearning' = $true
            }
            $PD.SetPIISettingsByParam = Set-AppSecPIISettings @TestParams @CommonParams
            $PD.SetPIISettingsByParam.enablePiiLearning | Should -Be $true
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.SetPIISettingsByPipeline = $PD.PIISettings | Set-AppSecPIISettings @TestParams @CommonParams
            $PD.SetPIISettingsByPipeline.enablePiiLearning | Should -Be $PD.PIISettings.enablePiiLearning
        }
    }

    #-------------------------------------------------
    #                   Protections
    #-------------------------------------------------

    Context 'Get-AppSecPolicyProtections' {
        It 'gets protection data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $Protections = Get-AppSecPolicyProtections @TestParams @CommonParams
            $Protections.applyApiConstraints | Should -Not -BeNullOrEmpty
        }
        It 'gets protection data by pipeline' {
            $PD.Protections = $PD.Policy | Get-AppSecPolicyProtections @CommonParams
            $PD.Protections.applyApiConstraints | Should -Not -BeNullOrEmpty

            # Enable all protections for later use
            $PD.Protections.PSObject.Properties.Name | ForEach-Object {
                $PD.Protections.$_ = $true
            }
        }
    }


    Context 'Set-AppSecPolicyProtections' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetProtectionsByPipeline = $PD.Protections | Set-AppSecPolicyProtections @TestParams @CommonParams
            $PD.SetProtectionsByPipeline.applyApiConstraints | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -Depth 10 $PD.Protections
            }
            $PD.SetProtectionsByBody = Set-AppSecPolicyProtections @TestParams @CommonParams
            $PD.SetProtectionsByBody.applyApiConstraints | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                   Penalty Box
    #-------------------------------------------------

    Context 'Get-AppSecPolicyPenaltyBox' {
        It 'gets protection data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $PenaltyBox = Get-AppSecPolicyPenaltyBox @TestParams @CommonParams
            $PenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data' {
            $PD.PenaltyBox = $PD.Policy | Get-AppSecPolicyPenaltyBox @CommonParams
            $PD.PenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPenaltyBox' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetPenaltyBoxByPipeline = $PD.PenaltyBox | Set-AppSecPolicyPenaltyBox @TestParams @CommonParams
            $PD.SetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -Depth 10 $PD.PenaltyBox
            }
            $PD.SetPenaltyBoxByBody = Set-AppSecPolicyPenaltyBox @TestParams @CommonParams
            $PD.SetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #             Penalty Box Condition
    #-------------------------------------------------

    Context 'Penalty Box Conditions' {
        BeforeEach {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
        }
        Context 'Set-AppSecPolicyPenaltyBoxCondition' {
            It 'sets a condition for the penalty box' {
                $Condition = @{
                    'conditionOperator' = "AND"
                    'conditions'        = @(
                        @{
                            'type'          = "requestHeaderMatch"
                            'header'        = "X-Test"
                            'positiveMatch' = $true
                            'value'         = "yeehah!"
                            'valueCase'     = $false
                            'valueWildcard' = $false
                        }
                    )
                }
                $PD.SetPenaltyBoxCondition = $Condition | Set-AppSecPolicyPenaltyBoxCondition @TestParams @CommonParams
                $PD.SetPenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
        }
    
        Context 'Get-AppSecPolicyPenaltyBoxCondition' {
            It 'retrieves the penalty box conditions by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.Policy.policyId
                }
                $PenaltyBoxCondition = Get-AppSecPolicyPenaltyBoxCondition @TestParams @CommonParams
                $PenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
            It 'retrieves the penalty box conditions by pipeline' {
                $PD.PenaltyBoxCondition = $PD.Policy | Get-AppSecPolicyPenaltyBoxCondition @CommonParams
                $PD.PenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
        }
    }

    #-------------------------------------------------
    #               Rate Policy Actions
    #-------------------------------------------------

    Context 'Set-AppSecPolicyRatePolicy' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'IPv4Action'    = 'deny'
                'IPv6Action'    = 'deny'
            }
            $PD.SetRatePolicyAction = Set-AppSecPolicyRatePolicy @TestParams @CommonParams
            $PD.SetRatePolicyAction.ipv4Action | Should -Be 'deny'
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'IPv4Action'    = 'pattern_fail'
                'IPv6Action'    = 'alert'
            }
            { Set-AppSecPolicyRatePolicy @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.NewConfig.config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'IPv4Action'    = 'alert'
                'IPv6Action'    = 'alert'
            }
            { Set-AppSecPolicyRatePolicy @TestParams @CommonParams } | Should -Throw
        }

        It 'fails action pattern validation' {
            { Set-AppSecPolicyRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RatePolicyID $PD.NewRatePolicyByBody.id -IPv4Action 'pattern_fail' -IPv6Action alert @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            { Set-AppSecPolicyRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 'pattern_fail' -PolicyID $PD.NewPolicy.policyId -RatePolicyID $PD.NewRatePolicyByBody.id -IPv4Action alert -IPv6Action alert @CommonParams } | Should -Throw
        }
    }

    Context 'Get-AppSecPolicyRatePolicy' {
        It 'returns the correct data' {
            $PD.RatePolicyActions = $PD.Policy | Get-AppSecPolicyRatePolicy @CommonParams
            $PD.RatePolicyActions[0].id | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #             Rate Policy Evaluation
    #-------------------------------------------------

    Context 'Set-AppSecEvaluationRatePolicy' {
        BeforeAll {
            # Set rate policy action to deny
            $ActionParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'IPv4Action'    = 'deny'
                'IPv6Action'    = 'deny'
            }
            Set-AppSecPolicyRatePolicy @ActionParams @CommonParams

            # Add evaluation object for later test
            $PD.NewRatePolicyByBody | Add-Member -MemberType NoteProperty -Name evaluation -Value @{ 
                'averageThreshold' = 5
                'burstThreshold'   = 25
                'counterType'      = 'region_aggregated' 
            }
            $SetParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'Body'          = $PD.NewRatePolicyByBody
            }
            Set-AppSecRatePolicy @SetParams @CommonParams
        }
        It 'updates evaluation action' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'RatePolicyID'  = $PD.NewRatePolicyByBody.id
                'Action'        = 'DISCARD'
            }
            $PD.SetEvalRatePolicy = Set-AppSecEvaluationRatePolicy @TestParams @CommonParams
            $PD.SetEvalRatePolicy.id | Should -Be $PD.NewRatePolicyByBody.id
        }
    }

    #-------------------------------------------------
    #             API Request Constraints
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAPIRequestConstraints' {
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $APIRequestConstraints = Get-AppSecPolicyAPIRequestConstraints @TestParams @CommonParams
            $APIRequestConstraints.action | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $PD.APIRequestConstraints = $PD.Policy | Get-AppSecPolicyAPIRequestConstraints @CommonParams
            $PD.APIRequestConstraints.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAPIRequestConstraints' {
        It 'without id - returns a list of actions' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Action'        = "alert"
                'APIID'         = $TestAPIEndpointID
            }
            $PD.SetAPIRequestConstraints = Set-AppSecPolicyAPIRequestConstraints @TestParams @CommonParams
            $PD.SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
        }

        It 'with id - returns the correct action' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'ApiID'         = $TestAPIEndpointID
                'Action'        = "alert"
            }
            $PD.SetAPIRequestConstraint = Set-AppSecPolicyAPIRequestConstraints @TestParams @CommonParams
            $PD.SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'ApiID'         = $TestAPIEndpointID
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyAPIRequestConstraints @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'ApiID'         = $TestAPIEndpointID
                'Action'        = "alert"
            }
            { Set-AppSecPolicyAPIRequestConstraints @TestParams @CommonParams } | Should -Throw
        }
    }

    #-------------------------------------------------
    #               Reputation Analysis
    #-------------------------------------------------

    Context 'Get-AppSecPolicyReputationAnalysis' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $ReputationAnalysis = Get-AppSecPolicyReputationAnalysis @TestParams @CommonParams
            $ReputationAnalysis.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.ReputationAnalysis = $PD.Policy | Get-AppSecPolicyReputationAnalysis @CommonParams
            $PD.ReputationAnalysis.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyReputationAnalysis' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetReputationAnalysisByPipeline = $PD.ReputationAnalysis | Set-AppSecPolicyReputationAnalysis @TestParams @CommonParams
            $PD.SetReputationAnalysisByPipeline.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -Depth 10 $PD.ReputationAnalysis
            }
            $PD.SetReputationAnalysisByBody = Set-AppSecPolicyReputationAnalysis @TestParams @CommonParams
            $PD.SetReputationAnalysisByBody.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #            Reputation Profile Actions
    #-------------------------------------------------

    Context 'Get-AppSecPolicyReputationProfile' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $ReputationProfileActions = Get-AppSecPolicyReputationProfile @TestParams @CommonParams
            $ReputationProfileActions.count | Should -BeGreaterThan 0
        }
        It 'gets a list by pipeline' {
            $PD.ReputationProfileActions = $PD.Policy | Get-AppSecPolicyReputationProfile @CommonParams
            $PD.ReputationProfileActions.count | Should -BeGreaterThan 0
        }
        It 'gets a sngle profile by ID' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 1
                'PolicyID'            = $PD.NewPolicy.policyId
                'ReputationProfileID' = $PD.ReputationProfileActions[0].id
            }
            $PD.ReputationProfileAction = Get-AppSecPolicyReputationProfile @TestParams @CommonParams
            $PD.ReputationProfileAction.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyReputationProfile' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 1
                'PolicyID'            = $PD.NewPolicy.policyId
                'ReputationProfileID' = $PD.ReputationProfileActions[0].id
                'Action'              = "deny"
            }
            $PD.SetReputationProfileAction = Set-AppSecPolicyReputationProfile @TestParams @CommonParams
            $PD.SetReputationProfileAction.action | Should -Be "deny"
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 1
                'PolicyID'            = $PD.NewPolicy.policyId
                'ReputationProfileID' = $PD.ReputationProfileActions[0].id
                'Action'              = 'pattern_fail'
            }
            { Set-AppSecPolicyReputationProfile @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = 'pattern_fail'
                'PolicyID'            = $PD.NewPolicy.policyId
                'ReputationProfileID' = $PD.ReputationProfileActions[0].id
                'Action'              = "deny"
            }
            { Set-AppSecPolicyReputationProfile @TestParams @CommonParams } | Should -Throw
        }
    }

    #-------------------------------------------------
    #                    Slow POST
    #-------------------------------------------------

    Context 'Get-AppSecPolicySlowPost' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $SlowPost = Get-AppSecPolicySlowPost @TestParams @CommonParams
            $SlowPost.slowRateThreshold | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.SlowPost = $PD.Policy | Get-AppSecPolicySlowPost @CommonParams
            $PD.SlowPost.slowRateThreshold | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicySlowPost' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetSlowPostByPipeline = $PD.SlowPost | Set-AppSecPolicySlowPost @TestParams @CommonParams
            $PD.SetSlowPostByPipeline.action | Should -Be $PD.SlowPost.action
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -depth 10 $PD.SlowPost
            }
            $PD.SetSlowPostByBody = Set-AppSecPolicySlowPost @TestParams @CommonParams
            $PD.SetSlowPostByBody.action | Should -Be $PD.SlowPost.action
        }
    }

    #-------------------------------------------------
    #               Custom Rule Actions
    #-------------------------------------------------

    Context 'Get-AppSecPolicyCustomRule' {
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $CustomRuleActions = Get-AppSecPolicyCustomRule @TestParams @CommonParams
            $CustomRuleActions[0].action | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $PD.CustomRuleActions = $PD.Policy | Get-AppSecPolicyCustomRule @CommonParams
            $PD.CustomRuleActions[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyCustomRule' {
        It 'updates successfully' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $PD.NewCustomRule.id
                'Action'        = 'deny'
            }
            $PD.SetCustomRuleAction = Set-AppSecPolicyCustomRule @TestParams @CommonParams
            $PD.SetCustomRuleAction.action | Should -Be 'deny'
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $PD.NewCustomRule.id
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyCustomRule @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $PD.NewCustomRule.id
                'Action'        = 'alert'
            }
            { Set-AppSecPolicyCustomRule @TestParams @CommonParams } | Should -Throw
        }
    }

    #-------------------------------------------------
    #               Custom Rule Usage
    #-------------------------------------------------

    Context 'Get-AppSecCustomRuleUsage' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'RuleID'        = $PD.NewCustomRule.id
            }
            $CustomRuleUsage = Get-AppSecCustomRuleUsage @TestParams @CommonParams
            $CustomRuleUsage[0].ruleId | Should -Be $PD.NewCustomRule.id
            $CustomRuleUsage[0].policies[0].policyId | Should -Be $PD.NewPolicy.policyId
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'RuleID' = $PD.NewCustomRule.id
            }
            $PD.CustomRuleUsage = $PD.Version | Get-AppSecCustomRuleUsage @TestParams @CommonParams
            $PD.CustomRuleUsage[0].ruleId | Should -Be $PD.NewCustomRule.id
            $PD.CustomRuleUsage[0].policies[0].policyId | Should -Be $PD.NewPolicy.policyId
        }

        # Remove rule action so we can delete later
        AfterAll {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $PD.NewCustomRule.id
                'Action'        = 'none'
            }
            Set-AppSecPolicyCustomRule @TestParams @CommonParams | Out-Null
        }
    }

    #-------------------------------------------------
    #             Policy Advanced Settings
    #-------------------------------------------------

    Context 'Get-AppSecPolicyEvasivePathMatch' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.Policy.policyId
            }
            $PolicyEvasivePathMatch = Get-AppSecPolicyEvasivePathMatch @TestParams @CommonParams
            $PolicyEvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyEvasivePathMatch = $PD.Policy | Get-AppSecPolicyEvasivePathMatch @CommonParams
            $PD.PolicyEvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvasivePathMatch' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = 1
                'PolicyID'        = $PD.NewPolicy.policyId
                'EnablePathMatch' = $true
            }
            $PD.PolicyEvasivePathMatch = Set-AppSecPolicyEvasivePathMatch @TestParams @CommonParams
            $PD.PolicyEvasivePathMatch.enablePathMatch | Should -Be $true
        }
    }

    Context 'Get-AppSecPolicyLogging' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $sPolicyLogging = Get-AppSecPolicyLogging @TestParams @CommonParams
            $sPolicyLogging.override | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyLogging = $PD.Policy | Get-AppSecPolicyLogging @CommonParams
            $PD.PolicyLogging.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyLogging' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetPolicyLoggingByPipeline = $PD.PolicyLogging | Set-AppSecPolicyLogging @TestParams @CommonParams
            $PD.SetPolicyLoggingByPipeline.override | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -depth 10 $PD.PolicyLogging
            }
            $PD.SetPolicyLoggingByBody = Set-AppSecPolicyLogging @TestParams @CommonParams
            $PD.SetPolicyLoggingByBody.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyPragmaSettings' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PolicyPragma = Get-AppSecPolicyPragmaSettings @TestParams @CommonParams
            $PolicyPragma.override | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyPragma = $PD.Policy | Get-AppSecPolicyPragmaSettings @CommonParams
            $PD.PolicyPragma.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPragmaSettings' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetPolicyPragmaByPipeline = $TestPragmaSettings | Set-AppSecPolicyPragmaSettings @TestParams @CommonParams
            $PD.SetPolicyPragmaByPipeline.action | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = $TestPragmaSettingsBody
            }
            $PD.SetPolicyPragmaByBody = Set-AppSecPolicyPragmaSettings @TestParams @CommonParams
            $PD.SetPolicyPragmaByBody.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRequestSizeLimit' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PolicyRequestSizeLimit = Get-AppSecPolicyRequestSizeLimit @TestParams @CommonParams
            $PolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyRequestSizeLimit = $PD.Policy | Get-AppSecPolicyRequestSizeLimit @CommonParams
            $PD.PolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRequestSizeLimit' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'         = $PD.Config.id
                'VersionNumber'    = 1
                'PolicyID'         = $PD.NewPolicy.policyId
                'RequestSizeLimit' = 8
                'Override'         = $true
            }
            $PD.SetPolicyRequestSizeLimit = Set-AppSecPolicyRequestSizeLimit @TestParams @CommonParams
            $PD.SetPolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 8
            $PD.SetPolicyRequestSizeLimit.override | Should -Be $true
        }
    }

    #-------------------------------------------------
    #                      WAF
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAttackGroup' {
        It 'gets a list of attack groups by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $AttackGroups = Get-AppSecPolicyAttackGroup @TestParams @CommonParams
            $AttackGroups.count | Should -BeGreaterThan 0
        }
        It 'gets a list of attack groups by pipeline' {
            $PD.AttackGroups = $PD.Policy | Get-AppSecPolicyAttackGroup @CommonParams
            $PD.AttackGroups.count | Should -BeGreaterThan 0
        }
        It 'gets a single attack group by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
            }
            $PD.AttackGroup = Get-AppSecPolicyAttackGroup @TestParams @CommonParams
            $PD.AttackGroup.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAttackGroup' {
        It 'sets correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = "deny"
            }
            $PD.SetAttackGroup = Set-AppSecPolicyAttackGroup @TestParams @CommonParams
            $PD.SetAttackGroup.action | Should -Be "deny"
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyAttackGroup @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.NewConfig.config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = 'alert'
            }
            { Set-AppSecPolicyAttackGroup @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Set-AppSecPolicyAttackGroupExceptions' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
            }
            $PD.SetAttackGroupExceptionsByPipeline = $TestException | Set-AppSecPolicyAttackGroupExceptions @TestParams @CommonParams
            $PD.SetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
                'Body'          = $TestExceptionBody
            }
            $PD.SetAttackGroupExceptionsByBody = Set-AppSecPolicyAttackGroupExceptions @TestParams @CommonParams
            $PD.SetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyAttackGroupExceptions' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
            }
            $AttackGroupExceptions = Get-AppSecPolicyAttackGroupExceptions @TestParams @CommonParams
            $AttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'AttackGroupID' = $TestAttackGroupID
            }
            $PD.AttackGroupExceptions = $PD.Policy | Get-AppSecPolicyAttackGroupExceptions @TestParams @CommonParams
            $PD.AttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRuleExceptions by pipeline' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
            }
            $PD.SetRuleExceptionsByPipeline = $TestException | Set-AppSecPolicyRuleExceptions @TestParams @CommonParams
            $PD.SetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Body'          = $TestExceptionBody
            }
            $PD.SetRuleExceptionsByBody = Set-AppSecPolicyRuleExceptions @TestParams @CommonParams
            $PD.SetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRuleExceptions' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
            }
            $RuleExceptions = Get-AppSecPolicyRuleExceptions @TestParams @CommonParams
            $RuleExceptions.exception | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'RuleID' = $TestRuleID
            }
            $PD.RuleExceptions = $PD.Policy | Get-AppSecPolicyRuleExceptions @TestParams @CommonParams
            $PD.RuleExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyMode' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PolicyMode = Get-AppSecPolicyMode @TestParams @CommonParams
            $PolicyMode.mode | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyMode = $PD.Policy | Get-AppSecPolicyMode @CommonParams
            $PD.PolicyMode.mode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyMode' {
        It 'sets correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Mode'          = 'ASE_MANUAL'
            }
            $PD.SetPolicyMode = Set-AppSecPolicyMode @TestParams @CommonParams
            $PD.SetPolicyMode.mode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRule' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PolicyRules = Get-AppSecPolicyRule @TestParams @CommonParams
            $PolicyRules.count | Should -BeGreaterThan 0
        }
        It 'gets a list by pipeline' {
            $PD.PolicyRules = $PD.Policy | Get-AppSecPolicyRule @CommonParams
            $PD.PolicyRules.count | Should -BeGreaterThan 0
        }
        It 'gets a single rule by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
            }
            $PD.Rule = Get-AppSecPolicyRule @TestParams @CommonParams
            $PD.Rule.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRule' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'deny'
            }
            $PD.SetRule = Set-AppSecPolicyRule @TestParams @CommonParams
            $PD.SetRule.action | Should -Be 'deny'
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyRule @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'alert'
            }
            { Set-AppSecPolicyRule @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Update-AppSecKRSRuleSet' {
        It 'sets correctly' {
            $TestParams = @{
                'Mode' = $TestPolicyMode
            }
            $PD.KRSRuleSet = $PD.Policy | Update-AppSecKRSRuleSet @TestParams @CommonParams
            $PD.KRSRuleSet.mode | Should -Be $TestPolicyMode
        }
    }

    Context 'Get-AppSecPolicyAdaptiveIntelligence' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $AdaptiveIntel = Get-AppSecPolicyAdaptiveIntelligence @TestParams @CommonParams
            $AdaptiveIntel.threatIntel | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.AdaptiveIntel = $PD.Policy | Get-AppSecPolicyAdaptiveIntelligence @CommonParams
            $PD.AdaptiveIntel.threatIntel | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAdaptiveIntelligence' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Action'        = 'on'
            }
            $PD.SetAdaptiveIntel = Set-AppSecPolicyAdaptiveIntelligence @TestParams @CommonParams
            $PD.SetAdaptiveIntel.threatIntel | Should -Be 'on'
        }
    }

    Context 'Get-AppSecPolicyUpgradeDetails' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $UpgradeDetails = Get-AppSecPolicyUpgradeDetails @TestParams @CommonParams
            $UpgradeDetails.current | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.UpgradeDetails = $PD.Policy | Get-AppSecPolicyUpgradeDetails @CommonParams
            $PD.UpgradeDetails.current | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                WAF Evaluation
    #-------------------------------------------------

    Context 'Set-AppSecPolicyEvaluationMode' {
        It 'returns the correct data' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Eval'          = 'START'
                'Mode'          = 'ASE_AUTO'
            }
            $PD.EvalMode = Set-AppSecPolicyEvaluationMode @TestParams @CommonParams
            $PD.EvalMode.eval | Should -Be 'enabled'
        }
    }

    Context 'Get-AppSecPolicyEvaluationRule' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $EvalPolicyRules = Get-AppSecPolicyEvaluationRule @TestParams @CommonParams
            $EvalPolicyRules.count | Should -BeGreaterThan 0
        }
        It 'gets a list by pipeline' {
            $PD.EvalPolicyRules = $PD.Policy | Get-AppSecPolicyEvaluationRule @CommonParams
            $PD.EvalPolicyRules.count | Should -BeGreaterThan 0
        }
        It 'gets a single rule by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
            }
            $PD.EvalRule = Get-AppSecPolicyEvaluationRule @TestParams @CommonParams
            $PD.EvalRule.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationRule' {
        It 'updates correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'deny'
            }
            $PD.EvalSetRule = Set-AppSecPolicyEvaluationRule @TestParams @CommonParams
            $PD.EvalSetRule.action | Should -Be 'deny'
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyEvaluationRule @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Action'        = 'alert'
            }
            { Set-AppSecPolicyEvaluationRule @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Get-AppSecPolicyEvaluationAttackGroup' {
        It 'gets a list of attack groups by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $EvalAttackGroups = Get-AppSecPolicyEvaluationAttackGroup @TestParams @CommonParams
            $EvalAttackGroups.count | Should -BeGreaterThan 0
        }
        It 'gets a list of attack groups by pipeline' {
            $PD.EvalAttackGroups = $PD.Policy | Get-AppSecPolicyEvaluationAttackGroup @CommonParams
            $PD.EvalAttackGroups.count | Should -BeGreaterThan 0
        }
        It 'gets a single attack group by ID' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
            }
            $PD.EvalAttackGroup = Get-AppSecPolicyEvaluationAttackGroup @TestParams @CommonParams
            $PD.EvalAttackGroup.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationAttackGroup' {
        It 'sets correctly' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = "deny"
            }
            $PD.EvalSetAttackGroup = Set-AppSecPolicyEvaluationAttackGroup @TestParams @CommonParams
            $PD.EvalSetAttackGroup.action | Should -Be "deny"
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = 'pattern_fail'
            }
            { Set-AppSecPolicyEvaluationAttackGroup @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'      = $PD.NewConfig.config.id
                'VersionNumber' = 'pattern_fail'
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $PD.AttackGroups[0].group
                'Action'        = 'alert'
            }
            { Set-AppSecPolicyEvaluationAttackGroup @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Set-AppSecPolicyEvaluationAttackGroupExceptions' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
            }
            $PD.EvalSetAttackGroupExceptionsByPipeline = $TestException | Set-AppSecPolicyEvaluationAttackGroupExceptions @TestParams @CommonParams
            $PD.EvalSetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
                'Body'          = $TestExceptionBody
            }
            $PD.EvalSetAttackGroupExceptionsByBody = Set-AppSecPolicyEvaluationAttackGroupExceptions @TestParams @CommonParams
            $PD.EvalSetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyEvaluationAttackGroupExceptions' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'AttackGroupID' = $TestAttackGroupID
            }
            $EvalAttackGroupExceptions = Get-AppSecPolicyEvaluationAttackGroupExceptions @TestParams @CommonParams
            $EvalAttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'AttackGroupID' = $TestAttackGroupID
            }
            $PD.EvalAttackGroupExceptions = $PD.Policy | Get-AppSecPolicyEvaluationAttackGroupExceptions @TestParams @CommonParams
            $PD.EvalAttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationRuleExceptions by pipeline' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
            }
            $PD.EvalSetRuleExceptionsByPipeline = $TestException | Set-AppSecPolicyEvaluationRuleExceptions @TestParams @CommonParams
            $PD.EvalSetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'RuleID'        = $TestRuleID
                'Body'          = $TestExceptionBody
            }
            $PD.EvalSetRuleExceptionsByBody = Set-AppSecPolicyEvaluationRuleExceptions @TestParams @CommonParams
            $PD.EvalSetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyEvaluationRuleExceptions' {
        It 'returns the correct data' {
            $TestParams = @{
                'RuleID' = $TestRuleID
            }
            $PD.EvalRuleExceptions = $PD.Policy | Get-AppSecPolicyEvaluationRuleExceptions @TestParams @CommonParams
            $PD.EvalRuleExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Penalty Box Evaluation
    #-------------------------------------------------

    Context 'Get-AppSecPolicyEvaluationPenaltyBox' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $EvalPenaltyBox = Get-AppSecPolicyEvaluationPenaltyBox @TestParams @CommonParams
            $EvalPenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.EvalPenaltyBox = $PD.Policy | Get-AppSecPolicyEvaluationPenaltyBox @CommonParams
            $PD.EvalPenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationPenaltyBox' {
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.EvalSetPenaltyBoxByPipeline = $PD.PenaltyBox | Set-AppSecPolicyEvaluationPenaltyBox @TestParams @CommonParams
            $PD.EvalSetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = ConvertTo-Json -Depth 10 $PD.PenaltyBox
            }
            $PD.EvalSetPenaltyBoxByBody = Set-AppSecPolicyEvaluationPenaltyBox @TestParams @CommonParams
            $PD.EvalSetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #          Evaluation Penalty Box Condition
    #-------------------------------------------------

    Context 'Evaluation Penalty Box Conditions' {
        BeforeEach {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
        }
        Context 'Set-AppSecPolicyEvaluationPenaltyBoxCondition' {
            It 'sets a condition for the penalty box' {
                $Condition = @{
                    'conditionOperator' = "AND"
                    'conditions'        = @(
                        @{
                            'type'          = "requestHeaderMatch"
                            'header'        = "X-Test"
                            'positiveMatch' = $true
                            'value'         = "yeehah!"
                            'valueCase'     = $false
                            'valueWildcard' = $false
                        }
                    )
                }
                $PD.SetEvalPenaltyBoxCondition = $Condition | Set-AppSecPolicyEvaluationPenaltyBoxCondition @TestParams @CommonParams
                $PD.SetEvalPenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
        }
    
        Context 'Get-AppSecPolicyEvaluationPenaltyBoxCondition' {
            It 'retrieves the penalty box conditions by param' {
                $EvalPenaltyBoxCondition = Get-AppSecPolicyEvaluationPenaltyBoxCondition @TestParams @CommonParams
                $EvalPenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
            It 'retrieves the penalty box conditions by pipeline' {
                $PD.EvalPenaltyBoxCondition = $PD.Policy | Get-AppSecPolicyEvaluationPenaltyBoxCondition @CommonParams
                $PD.EvalPenaltyBoxCondition.conditions[0].header | Should -Be "X-Test"
            }
        }
    }


    #-------------------------------------------------
    #                     Export
    #-------------------------------------------------

    Context 'Export-AppSecConfiguration' {
        It 'exports correctly by param, synchronous' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $Export = Export-AppSecConfiguration @TestParams @CommonParams
            $Export.configId | Should -Be $PD.Config.id
        }
        It 'exports correctly by pipeline, synchronous' {
            $PD.Export = $PD.Version | Export-AppSecConfiguration @CommonParams
            $PD.Export.configId | Should -Be $PD.Config.id
        }
        It 'waits 1m to clear the rate limit' {
            Start-Sleep -Seconds 60
        }
        It 'creates an export request by parameter, async' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'Async'         = $true
            }
            $PD.AsyncExport = Export-AppSecConfiguration @TestParams @CommonParams
            $PD.AsyncExport.exportId | Should -Not -BeNullOrEmpty
        }
        It 'waits for the export task to complete before continuing' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'ExportID'      = $PD.AsyncExport.exportId
            }
            $Export = Get-AppSecExportStatus @TestParams @CommonParams
            while ($Export.exportStatus -ne 'COMPLETED') {
                Start-Sleep -Seconds 10
                $Export = Get-AppSecExportStatus @TestParams @CommonParams
            }
        }
        It 'creates an export request by pipeline, async' {
            $TestParams = @{
                'Async' = $true
            }
            $AsyncExport = $PD.Version | Export-AppSecConfiguration @TestParams @CommonParams
            $AsyncExport.exportId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecExportStatus' {
        It 'retrieves export status by parameter' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'ExportID'      = $PD.AsyncExport.exportId
            }
            $ExportStatus = Get-AppSecExportStatus @TestParams @CommonParams
            $ExportStatus.exportId | Should -Be $PD.AsyncExport.exportId
            $ExportStatus.exportStatus | Should -Not -BeNullOrEmpty
        }
        It 'retrieves export status by piped version' {
            $TestParams = @{
                'ExportID' = $PD.AsyncExport.exportId
            }
            $ExportStatus = $PD.Version | Get-AppSecExportStatus @TestParams @CommonParams
            $ExportStatus.exportId | Should -Be $PD.AsyncExport.exportId
            $ExportStatus.exportStatus | Should -Not -BeNullOrEmpty
        }
        It 'retrieves export status by piped export' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.ExportStatus = $PD.AsyncExport | Get-AppSecExportStatus @TestParams @CommonParams
            $PD.ExportStatus.exportId | Should -Be $PD.AsyncExport.exportId
            $PD.ExportStatus.exportStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecExport' {
        It 'retrieves export results by parameter' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'ExportID'      = $PD.AsyncExport.exportId
            }
            $ExportResults = Get-AppSecExport @TestParams @CommonParams
            $ExportResults.configId | Should -Be $PD.Config.id
            $ExportResults.configName | Should -Be $PD.Config.name
            $ExportResults.securityPolicies | Should -Not -BeNullOrEmpty
        }
        It 'retrieves export results by piped export status' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $PD.ExportResults = $PD.ExportStatus | Get-AppSecExport @TestParams @CommonParams
            $PD.ExportResults.configId | Should -Be $PD.Config.id
            $PD.ExportResults.configName | Should -Be $PD.Config.name
            $PD.ExportResults.securityPolicies | Should -Not -BeNullOrEmpty
        }
        It 'retrieves export results by piped version' {
            $TestParams = @{
                'ExportID' = $PD.AsyncExport.exportId
            }
            $PD.ExportResultsByVersion = $PD.Version | Get-AppSecExport @TestParams @CommonParams
            $PD.ExportResultsByVersion.configId | Should -Be $PD.Config.id
            $PD.ExportResultsByVersion.configName | Should -Be $PD.Config.name
            $PD.ExportResultsByVersion.securityPolicies | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  SIEM Versions
    #-------------------------------------------------

    Context 'Export-AppSecConfigurationVersionDetails' {
        It 'returns the correct data' {
            $PD.SiemVersions = Get-AppSecSiemVersions @CommonParams
            $PD.SiemVersions[0].id | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               ContractsAndGroups
    #-------------------------------------------------

    Context 'Get-AppSecContractsAndGroups' {
        It 'returns a list' {
            $PD.Groups = Get-AppSecContractsAndGroups @CommonParams
            $PD.Groups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               URL Protection Policies
    #-------------------------------------------------

    Context 'New-AppSecURLProtectionPolicy' {
        It 'creates successfully' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'Body'          = $TestURLProtectionPolicyJSON
            }
            $PD.NewURLProtectionPolicy = New-AppSecURLProtectionPolicy @TestParams @CommonParams
            $PD.NewURLProtectionPolicy.configId | Should -Be $PD.Config.id
        }
    }

    Context 'Get-AppSecURLProtectionPolicy' {
        It 'gets a list of policies by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $GetURLProtectionPolicies = Get-AppSecURLProtectionPolicy @TestParams @CommonParams
            $GetURLProtectionPolicies[0].configId | Should -Be $PD.Config.id
        }
        It 'gets a list of policies by pipeline' {
            $PD.GetURLProtectionPolicies = $PD.Version | Get-AppSecURLProtectionPolicy @CommonParams
            $PD.GetURLProtectionPolicies[0].configId | Should -Be $PD.Config.id
        }
        It 'gets a single policy by ID' {
            $TestParams = @{
                'ConfigID'              = $PD.Config.id
                'VersionNumber'         = $PD.Version.version
                'URLProtectionPolicyID' = $PD.NewURLProtectionPolicy.policyId
            }
            $PD.GetURLProtectionPolicy = Get-AppSecURLProtectionPolicy @TestParams @CommonParams
            $PD.GetURLProtectionPolicy.configId | Should -Be $PD.Config.id
        }
    }

    Context 'Set-AppSecURLProtectionPolicy' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'              = $PD.Config.id
                'VersionNumber'         = $PD.Version.version
                'URLProtectionPolicyID' = $PD.NewURLProtectionPolicy.policyId
                'Body'                  = $PD.GetURLProtectionPolicy
            }
            $PD.SetURLProtectionPolicyByParam = Set-AppSecURLProtectionPolicy @TestParams @CommonParams
            $PD.SetURLProtectionPolicyByParam.configId | Should -Be $PD.Config.id
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
            }
            $PD.SetURLProtectionPolicyByPipeline = $PD.GetURLProtectionPolicy | Set-AppSecURLProtectionPolicy @TestParams @CommonParams
            $PD.SetURLProtectionPolicyByPipeline.configId | Should -Be $PD.Config.id
        }
    }

    Context 'Get-AppSecPolicyURLProtectionPolicy' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $GetPolicyURLProtectionPolicies = Get-AppSecPolicyURLProtectionPolicy @TestParams @CommonParams
            $GetPolicyURLProtectionPolicies[0].policyId | Should -Be $PD.GetURLProtectionPolicy.policyId
        }
        It 'returns the correct data by pipeline' {
            $PD.GetPolicyURLProtectionPolicies = $PD.Policy | Get-AppSecPolicyURLProtectionPolicy @CommonParams
            $PD.GetPolicyURLProtectionPolicies[0].policyId | Should -Be $PD.GetURLProtectionPolicy.policyId
        }
    }

    Context 'Set-AppSecPolicyURLProtectionPolicy' {
        It 'returns the correct data' {
            $TestParams = @{
                'ConfigID'              = $PD.Config.id
                'VersionNumber'         = $PD.Version.version
                'PolicyID'              = $PD.NewPolicy.policyId
                'URLProtectionPolicyID' = $PD.GetURLProtectionPolicy.policyId
                'Action'                = 'none'
            }
            $PD.SetPolicyURLProtectionPolicy = Set-AppSecPolicyURLProtectionPolicy @TestParams @CommonParams
            $PD.SetPolicyURLProtectionPolicy.action | Should -Be 'none'
            $PD.SetPolicyURLProtectionPolicy.policyId | Should -Be $PD.GetURLProtectionPolicy.policyId
        }
    }

    #-------------------------------------------------
    #               Attack Payload Settings
    #-------------------------------------------------

    Context 'Get-AppSecAttackPayload' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $GetAttackPayload = Get-AppSecAttackPayload @TestParams @CommonParams
            $GetAttackPayload.enabled | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.GetAttackPayload = $PD.Version | Get-AppSecAttackPayload @CommonParams
            $PD.GetAttackPayload.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecAttackPayload by param' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'Body'          = $PD.GetAttackPayload
            }
            $PD.SetAttackPayloadByParam = Set-AppSecAttackPayload @TestParams @CommonParams
            $PD.SetAttackPayloadByParam.enabled | Should -Be $PD.GetAttackPayload.enabled
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
            }
            $PD.SetAttackPayloadByPipeline = $PD.GetAttackPayload | Set-AppSecAttackPayload @TestParams @CommonParams
            $PD.SetAttackPayloadByPipeline.enabled | Should -Be $PD.GetAttackPayload.enabled
        }
    }

    Context 'Get-AppSecPolicyAttackPayload' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $GetPolicyAttackPayload = Get-AppSecPolicyAttackPayload @TestParams @CommonParams
            $GetPolicyAttackPayload.enabled | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $PD.GetPolicyAttackPayload = $PD.Policy | Get-AppSecPolicyAttackPayload @CommonParams
            $PD.GetPolicyAttackPayload.enabled | Should -Not -BeNullOrEmpty

            # Set enabled to false for later commands
            $PD.GetPolicyAttackPayload.enabled = $false
            $PD.GetPolicyAttackPayload.override = $true
        }
    }

    Context 'Set-AppSecPolicyAttackPayload' {
        It 'updates by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.NewPolicy.policyId
                'Body'          = $PD.GetPolicyAttackPayload
            }
            $PD.SetPolicyAttackPayloadByParam = Set-AppSecPolicyAttackPayload @TestParams @CommonParams
            $PD.SetPolicyAttackPayloadByParam.enabled | Should -Be $false
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetPolicyAttackPayloadByPipeline = $PD.GetPolicyAttackPayload | Set-AppSecPolicyAttackPayload @TestParams @CommonParams
            $PD.SetPolicyAttackPayloadByPipeline.enabled | Should -Be $false
        }
    }

    #-------------------------------------------------
    #               Malware Policies
    #-------------------------------------------------

    Context 'New-AppSecMalwarePolicy' {
        It 'creates successfully' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'Body'          = $TestMalwarePolicyJSON
            }
            $PD.NewMalwarePolicy = New-AppSecMalwarePolicy @TestParams @CommonParams
            $PD.NewMalwarePolicy.name | Should -Be $TestMalwarePolicyName
        }
    }

    Context 'Get-AppSecMalwarePolicy' {
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $GetMalwarePolicies = Get-AppSecMalwarePolicy @TestParams @CommonParams
            $GetMalwarePolicies[0].name | Should -Be $TestMalwarePolicyName
        }
        It 'gets a list by pipeline' {
            $PD.GetMalwarePolicies = $PD.Version | Get-AppSecMalwarePolicy @CommonParams
            $PD.GetMalwarePolicies[0].name | Should -Be $TestMalwarePolicyName
        }
        It 'get a policy by ID' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
            }
            $PD.GetMalwarePolicy = Get-AppSecMalwarePolicy @TestParams @CommonParams
            $PD.GetMalwarePolicy.id | Should -Be $PD.NewMalwarePolicy.id
        }
    }

    Context 'Get-AppSecMalwarePolicyContentType' {
        It 'gets the supported policy content types by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $MalwarePolicyContentTypes = Get-AppSecMalwarePolicyContentType @TestParams @CommonParams
            $MalwarePolicyContentTypes | Should -Contain 'text/plain'
        }
        It 'gets the supported policy content types by pipeline' {
            $PD.MalwarePolicyContentTypes = $PD.Version | Get-AppSecMalwarePolicyContentType @CommonParams
            $PD.MalwarePolicyContentTypes | Should -Contain 'text/plain'
        }
    }


    Context 'Set-AppSecMalwarePolicy' {
        It 'updates by params' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                'Body'            = $PD.GetMalwarePolicy
            }
            $PD.SetMalwarePolicyByParam = Set-AppSecMalwarePolicy @TestParams @CommonParams
            $PD.SetMalwarePolicyByParam.id | Should -Be $PD.NewMalwarePolicy.id
        }
        It 'updates by pipeline' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
            }
            $PD.SetMalwarePolicyByPipeline = $PD.GetMalwarePolicy | Set-AppSecMalwarePolicy @TestParams @CommonParams
            $PD.SetMalwarePolicyByPipeline.id | Should -Be $PD.NewMalwarePolicy.id
        }
    }

    Context 'Set-AppSecPolicyMalwarePolicy' {
        It 'returns a list' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'PolicyID'        = $PD.NewPolicy.policyId
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                'Action'          = 'alert'
                'UnscannedAction' = 'alert'
            }
            $PD.SetMalwarePolicyAction = Set-AppSecPolicyMalwarePolicy @TestParams @CommonParams
            $PD.SetMalwarePolicyAction.action | Should -Be 'alert'
            $PD.SetMalwarePolicyAction.unscannedAction | Should -Be 'alert'
        }

        It 'fails action pattern validation' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'PolicyID'        = $PD.NewPolicy.policyId
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                'Action'          = 'pattern_fail'
                'UnscannedAction' = 'alert'
            }
            { Set-AppSecPolicyMalwarePolicy @TestParams @CommonParams } | Should -Throw
        }

        It 'fails unscannedaction pattern validation' {
            $TestParams = @{
                'ConfigID'        = $PD.Config.id
                'VersionNumber'   = $PD.Version.version
                'PolicyID'        = $PD.NewPolicy.policyId
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                'Action'          = 'alert'
                'UnscannedAction' = 'pattern_fail'
            }
            { Set-AppSecPolicyMalwarePolicy @TestParams @CommonParams } | Should -Throw
        }

        It 'fails version pattern validation' {
            $TestParams = @{
                'ConfigID'        = $PD.NewConfig.config.id
                'VersionNumber'   = 'pattern_fail'
                'PolicyID'        = $PD.NewPolicy.policyId
                'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                'Action'          = 'alert'
                'UnscannedAction' = 'alert'
            }
            { Set-AppSecPolicyMalwarePolicy @TestParams @CommonParams } | Should -Throw
        }
    }

    Context 'Get-AppSecPolicyMalwarePolicy' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $GetMalwarePolicyActions = Get-AppSecPolicyMalwarePolicy @TestParams @CommonParams
            $GetMalwarePolicyActions[0].id | Should -Be $PD.NewMalwarePolicy.id
        }
        It 'returns the correct data by pipeline' {
            $PD.GetMalwarePolicyActions = $PD.Policy | Get-AppSecPolicyMalwarePolicy @CommonParams
            $PD.GetMalwarePolicyActions[0].id | Should -Be $PD.NewMalwarePolicy.id
        }
    }

    #-------------------------------------------------
    #               Policy API Endpoints
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAPIEndpoints' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PolicyAPIEndpoints = Get-AppSecPolicyAPIEndpoints @TestParams @CommonParams
            $PolicyAPIEndpoints[0].id | Should -Be $TestAPIEndpointID
        }
        It 'returns the correct data by pipeline' {
            $PD.PolicyAPIEndpoints = $PD.Policy | Get-AppSecPolicyAPIEndpoints @CommonParams
            $PD.PolicyAPIEndpoints[0].id | Should -Be $TestAPIEndpointID
        }
    }

    #-------------------------------------------------
    #                 Cookie Settings
    #-------------------------------------------------

    Context 'Get-AppSecCookieSettings' {
        It 'gets the cookie settings by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $CookieSettings = Get-AppSecCookieSettings @TestParams @CommonParams
            $CookieSettings.cookieDomain | Should -Not -BeNullOrEmpty
            $CookieSettings.useAllSecureTraffic | Should -Not -BeNullOrEmpty
        }
        It 'gets the cookie settings by pipeline' {
            $PD.CookieSettings = $PD.Version | Get-AppSecCookieSettings @CommonParams
            $PD.CookieSettings.cookieDomain | Should -Not -BeNullOrEmpty
            $PD.CookieSettings.useAllSecureTraffic | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecCookieSettings' {
        It 'updates by body' {
            $PD.CookieSettings.cookieDomain = 'legacy'
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
            }
            $PD.SetCookieSettingsBody = $PD.CookieSettings | Set-AppSecCookieSettings @TestParams @CommonParams
            $PD.SetCookieSettingsBody.cookieDomain | Should -Be $PD.CookieSettings.cookieDomain
            $PD.SetCookieSettingsBody.useAllSecureTraffic | Should -Be $PD.CookieSettings.useAllSecureTraffic
        }
        It 'updates by attributes' {
            $TestParams = @{
                'ConfigID'            = $PD.Config.id
                'VersionNumber'       = $PD.Version.version
                'CookieDomain'        = 'fqdn'
                'UseAllSecureTraffic' = $true
            }
            $PD.SetCookieSettingsAttr = Set-AppSecCookieSettings @TestParams @CommonParams
            $PD.SetCookieSettingsAttr.cookieDomain | Should -Be 'fqdn'
            $PD.SetCookieSettingsAttr.useAllSecureTraffic | Should -Be $true
        }
    }

    #-------------------------------------------------
    #                JA4 Fingerprint
    #-------------------------------------------------

    Context 'Set-AppSecJA4Fingerprint' {
        It 'returns the correct data' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'HeaderName'    = 'x-ja4-fingerprint'
            }
            $PD.SetJA4 = Set-AppSecJA4Fingerprint @TestParams @CommonParams
            $PD.SetJA4.headerNames | Should -Be @('x-ja4-fingerprint')
        }
    }

    Context 'Get-AppSecJA4Fingerprint' {
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
            }
            $JA4 = Get-AppSecJA4Fingerprint @TestParams @CommonParams
            $JA4.headerNames | Should -Be @('x-ja4-fingerprint')
        }
        It 'returns the correct data by pipeline' {
            $PD.JA4 = $PD.Version | Get-AppSecJA4Fingerprint @CommonParams
            $PD.JA4.headerNames | Should -Be @('x-ja4-fingerprint')
        }
    }

    #-------------------------------------------------
    #                    CVE
    #-------------------------------------------------

    Context 'CVE' -Tag 'CVE' {
        Context 'Get-AppSecCVE' {
            It 'gets a list of cves' {
                $PD.CVEs = Get-AppSecCVE @CommonParams
                $PD.CVEs.count | Should -BeGreaterThan 0
                $PD.CVEs[0].cveId | Should -Not -BeNullOrEmpty
            }
    
            It 'gets a single CVE by ID by param' {
                $TestParams = @{
                    'CveID' = $PD.CVEs[0].cveId
                }
                $CVE = Get-AppSecCVE @TestParams @CommonParams
                $CVE.cveId | Should -Be $PD.CVEs[0].cveId
            }

            It 'gets a single CVE by ID by pipeline' {
                $PD.CVE = $PD.CVEs[0] | Get-AppSecCVE @CommonParams
                $PD.CVE.cveId | Should -Be $PD.CVEs[0].cveId
            }
        }
    
        Context 'New-AppSecCVESubscription' {
            It 'creates a subscription' {
                $PD.NewCVESub = $PD.CVEs[0..9] | New-AppSecCVESubscription @CommonParams
                $PD.NewCVESub.count | Should -Be 10
                $PD.NewCVESub | Sort-Object | Should -Be ( $PD.CVEs[0..9].cveId | Sort-Object )
            }
        }

        Context 'Get-AppSecCVESubscription' {
            It 'retrieves a subscription' {
                $PD.CVESub = Get-AppSecCVESubscription @CommonParams
                $PD.CVESub.count | Should -Be 10
                $PD.CVESub.cveId | Sort-Object | Should -Be ( $PD.CVEs[0..9].cveId | Sort-Object )
            }
        }

        Context 'Remove-AppSecCVESubscription' {
            It 'removes a subscription' {
                $PD.RemoveCVESub = $PD.CVESub | Remove-AppSecCVESubscription @CommonParams
                $PD.RemoveCVESub | Sort-Object | Should -Be ( $PD.CVEs[0..9].cveId | Sort-Object )
            }
        }

        Context 'Get-AppSecCVECoverage' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecCVECoverage.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets a list of covered configs and policies by param' {
                $TestParams = @{
                    'CveID' = 'CVE-2025-6547'
                }
                $CVECoverage = Get-AppSecCVECoverage @TestParams @CommonParams
                $CVECoverage.configId | Should -Not -BeNullOrEmpty
                $CVECoverage.configName | Should -Not -BeNullOrEmpty
            }
            It 'gets a list of covered configs and policies by pipeline' {
                $CVECoverage = $PD.CVEs[0] | Get-AppSecCVECoverage @CommonParams
                $CVECoverage.configId | Should -Not -BeNullOrEmpty
                $CVECoverage.configName | Should -Not -BeNullOrEmpty
            }
        }

        AfterAll {
            Get-AppSecCVESubscription @CommonParams | Remove-AppSecCVESubscription @CommonParams
        }
    }

    #-------------------------------------------------
    #                 Rapid Rules
    #-------------------------------------------------

    Context 'Rapid Rules' -Tag 'Rapid Rules' {
        BeforeEach {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.NewPolicy.policyId
            }
        }

        Context 'Get-AppSecPolicyRapidRulesStatus' {
            It 'gets the current status by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.NewPolicy.policyId
                }
                $RapidRulesStatus = Get-AppSecPolicyRapidRulesStatus @TestParams @CommonParams
                $RapidRulesStatus.enabled | Should -Be $true
            }
            It 'gets the current status by pipeline' {
                $PD.RapidRulesStatus = $PD.Policy | Get-AppSecPolicyRapidRulesStatus @CommonParams
                $PD.RapidRulesStatus.enabled | Should -Be $true
            }
        }

        Context 'Enable/Disable by pipeline' {
            Context 'Disable-AppSecPolicyRapidRules' {
                It 'disables the feature by pipeline' {
                    $PD.DisableRapidRules = $PD.Policy | Disable-AppSecPolicyRapidRules @CommonParams
                    $PD.DisableRapidRules.enabled | Should -Be $false
                }
            }
    
            Context 'Enable-AppSecPolicyRapidRules' {
                It 'disables the feature' {
                    $PD.EnableRapidRules = $PD.Policy | Enable-AppSecPolicyRapidRules @CommonParams
                    $PD.EnableRapidRules.enabled | Should -Be $true
                }
            }
        }

        Context 'Enable/Disable by param' {
            Context 'Disable-AppSecPolicyRapidRules' {
                It 'disables the feature by param' {
                    $PD.DisableRapidRules = Disable-AppSecPolicyRapidRules @TestParams @CommonParams
                    $PD.DisableRapidRules.enabled | Should -Be $false
                }
            }
    
            Context 'Enable-AppSecPolicyRapidRules' {
                It 'disables the feature by param' {
                    $PD.EnableRapidRules = Enable-AppSecPolicyRapidRules @TestParams @CommonParams
                    $PD.EnableRapidRules.enabled | Should -Be $true
                }
            }
        }

        Context 'Get-AppSecPolicyRapidRule' {
            It 'gets a list of rapid rules by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.NewPolicy.policyId
                }
                $RapidRules = Get-AppSecPolicyRapidRule @TestParams @CommonParams
                $RapidRules.count | Should -BeGreaterThan 0
                $RapidRules[0].id | Should -Not -BeNullOrEmpty
                $RapidRules[0].version | Should -Not -BeNullOrEmpty
                $RapidRules[0].riskScoreGroups | Should -Not -BeNullOrEmpty
            }

            It 'gets a list of rapid rules by pipeline' {
                $PD.RapidRules = $PD.Policy | Get-AppSecPolicyRapidRule @CommonParams
                $PD.RapidRules.count | Should -BeGreaterThan 0
                $PD.RapidRules[0].id | Should -Not -BeNullOrEmpty
                $PD.RapidRules[0].version | Should -Not -BeNullOrEmpty
                $PD.RapidRules[0].riskScoreGroups | Should -Not -BeNullOrEmpty
            }
    
            It 'gets a single rule by ID' {
                $TestParams = @{
                    'RuleID'      = $PD.RapidRules[0].id
                    'RuleVersion' = $PD.RapidRules[0].version
                }
                $PD.RapidRule = $PD.Policy | Get-AppSecPolicyRapidRule @TestParams @CommonParams
                $PD.RapidRule.action | Should -Be $PD.RapidRules[0].action
                $PD.RapidRule.lock | Should -Be $PD.RapidRules[0].lock
            }
        }

        Context 'Get-AppSecPolicyRapidRuleDefaultAction' {
            It 'retrieves the default action by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.NewPolicy.policyId
                }
                $RapidRulesDefault = Get-AppSecPolicyRapidRuleDefaultAction @TestParams @CommonParams
                $RapidRulesDefault.action | Should -Be 'alert'
            }
            It 'retrieves the default action by pipeline' {
                $PD.RapidRulesDefault = $PD.Policy | Get-AppSecPolicyRapidRuleDefaultAction @CommonParams
                $PD.RapidRulesDefault.action | Should -Be 'alert'
            }
        }

        Context 'Set-AppSecPolicyRapidRuleDefaultAction' {
            It 'updates the default action' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'action'        = 'deny'
                }
                $PD.SetRapidRulesDefault = Set-AppSecPolicyRapidRuleDefaultAction @TestParams @CommonParams
                $PD.SetRapidRulesDefault.action | Should -Be 'deny'
            }

            It 'fails when the specified action is invalid' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'action'        = 'ponder'
                }
                { Set-AppSecPolicyRapidRuleDefaultAction @TestParams @CommonParams } | Should -Throw
            }
        }

        Context 'Get-AppSecPolicyRapidRuleLock' {
            It "retrieves the rule's lock status by param" {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'RuleID'        = $PD.RapidRules[0].id
                }
                $RapidRuleLockStatus = Get-AppSecPolicyRapidRuleLock @TestParams @CommonParams
                $RapidRuleLockStatus.enabled | Should -Be $false
            }
            It "retrieves the rule's lock status by pipeline" {
                $TestParams = @{
                    'RuleID' = $PD.RapidRules[0].id
                }
                $PD.RapidRuleLockStatus = $PD.Policy | Get-AppSecPolicyRapidRuleLock @TestParams @CommonParams
                $PD.RapidRuleLockStatus.enabled | Should -Be $false
            }
        }

        Context 'Lock/Unlock/Set by pipeline' {
            Context 'Unlock-AppSecPolicyRapidRule' {
                It 'unlocks by pipeline' {
                    $TestParams = @{
                        'RuleID' = $PD.RapidRules[0].id
                    }
                    $PD.RapidRuleUnlock = $PD.Policy | Unlock-AppSecPolicyRapidRule @TestParams @CommonParams
                    $PD.RapidRuleUnlock.enabled | Should -Be $false
                }
            }
    
            Context 'Set-AppSecPolicyRapidRule' {
                It 'updates the default action' {
                    $TestParams.action = 'deny'
                    $PD.SetRapidRulesDefault = $PD.RapidRules[0] | Set-AppSecPolicyRapidRule @TestParams @CommonParams
                    $PD.SetRapidRulesDefault.action | Should -Be 'deny'
                }
    
                It 'fails when the specified action is invalid' {
                    $TestParams.action = 'ponder'
                    { Set-AppSecPolicyRapidRuleDefaultAction @TestParams @CommonParams } | Should -Throw
                }
            }
    
            Context 'Lock-AppSecPolicyRapidRule' {
                It 'locks by pipeline' {
                    $TestParams = @{
                        'RuleID' = $PD.RapidRules[0].id
                    }
                    $PD.RapidRuleLock = $PD.Policy | Lock-AppSecPolicyRapidRule @TestParams @CommonParams
                    $PD.RapidRuleLock.enabled | Should -Be $true
                }
            }
        }

        Context 'Lock/Unlock by param' {
            Context 'Unlock-AppSecPolicyRapidRule' {
                It 'unlocks by param' {
                    $TestParams.RuleID = $PD.RapidRules[0].id
                    $RapidRuleUnlock = Unlock-AppSecPolicyRapidRule @TestParams @CommonParams
                    $RapidRuleUnlock.enabled | Should -Be $false
                }
            }
            
            Context 'Lock-AppSecPolicyRapidRule' {
                It 'locks by param' {
                    $TestParams.RuleID = $PD.RapidRules[0].id
                    $RapidRuleLock = Lock-AppSecPolicyRapidRule @TestParams @CommonParams
                    $RapidRuleLock.enabled | Should -Be $true
                }
            }
        }

        Context 'Set-AppSecPolicyRapidRuleCondition' {
            It 'updates the rule condition' {
                $TestParams.ruleId = $PD.RapidRules[0].id
                $TestParams.Body = @{
                    "exception" = @{
                        "specificHeaderCookieParamXmlOrJsonNames" = @(
                            @{
                                "names"    = @(
                                    "X-Test"
                                )
                                "selector" = "REQUEST_HEADERS_NAMES"
                                "wildcard" = $true
                            }
                        )
                    }
                }
                $PD.SetRapidRulesCondition = Set-AppSecPolicyRapidRuleCondition @TestParams @CommonParams
                $PD.SetRapidRulesCondition.exception.specificHeaderCookieParamXmlOrJsonNames[0].names[0] | Should -Be 'X-Test'
            }
        }

        Context 'Get-AppSecPolicyRapidRuleCondition' {
            It 'updates the rule condition' {
                $TestParams = @{
                    'ruleId' = $PD.RapidRules[0].id
                }
                $PD.RapidRulesCondition = $PD.Policy | Get-AppSecPolicyRapidRuleCondition @TestParams @CommonParams
                $PD.RapidRulesCondition.exception.specificHeaderCookieParamXmlOrJsonNames[0].names[0] | Should -Be 'X-Test'
            }
        }
    }

    #-------------------------------------------------
    #                    CPC
    #-------------------------------------------------

    Context 'Get-AppSecPolicyCPC' {
        It 'gets the CPC settings by param' {
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = 1
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $CPC = Get-AppSecPolicyCPC @TestParams @CommonParams
            $CPC.edgeInjection.autoLoadStaging | Should -Be $false
        }
        It 'gets the CPC settings by pipeline' {
            $PD.CPC = $PD.Policy | Get-AppSecPolicyCPC @CommonParams
            $PD.CPC.edgeInjection.autoLoadStaging | Should -Be $false
        }
    }

    Context 'Set-AppSecPolicyCPC' {
        It 'updates CPC' {
            $PD.CPC.edgeInjection.autoLoadStaging = $true
            $PD.CPC.edgeInjection.clientSideProtectionConfigId = $TestCPCConfigID
            $TestParams = @{
                'ConfigID'      = $PD.Config.id
                'VersionNumber' = $PD.Version.version
                'PolicyID'      = $PD.NewPolicy.policyId
            }
            $PD.SetCPC = $PD.CPC | Set-AppSecPolicyCPC @TestParams @CommonParams
            $PD.SetCPC.edgeInjection.autoLoadStaging | Should -Be $true
        }
    }

    #-------------------------------------------------
    #                    Expand
    #-------------------------------------------------

    Context 'Expand-AppSecConfigDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.AppSec/Functions/Private/Expand-AppSecConfigDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache

            $ProductionActiveConfig = $PD.Configs | Where-Object productionVersion | Select-Object -First 1
            $StagingActiveConfig = $PD.Configs | Where-Object stagingVersion | Select-Object -First 1
        }
        It 'finds the right config by name' {
            $TestParams = @{
                'ConfigName' = $TestConfigName
            }
            $ExpandedConfigID, $null, $null = Expand-AppSecConfigDetails @TestParams @CommonParams
            $ExpandedConfigID | Should -Be $PD.NewConfig.configId
            $AkamaiDataCache.AppSec.Configs.$TestConfigName.ConfigID | Should -Be $ExpandedConfigID
        }
        It "throws when trying to find a config which doesn't exist" {
            $TestParams = @{
                'ConfigName' = "some-random-config-which-doesnt-exist"
            }
            { Expand-AppSecConfigDetails @TestParams @CommonParams } | Should -Throw 'Security config * not found.'
        }
        It 'finds the right production version' {
            $TestParams = @{
                'ConfigID'      = $ProductionActiveConfig.id
                'VersionNumber' = 'production'
            }
            $ProductionConfigID, $ExpandedVersion, $null = Expand-AppSecConfigDetails @TestParams @CommonParams
            $ProductionConfigID | Should -Be $ProductionActiveConfig.id
            $ExpandedVersion | Should -Be $ProductionActiveConfig.productionVersion
            $AkamaiDataCache.AppSec.Configs.($ProductionActiveConfig.name).ConfigID | Should -Be $ProductionConfigID
        }
        It 'fails if retrieving production version and none exist' {
            $TestParams = @{
                'ConfigID'      = $PD.NewConfig.configId
                'VersionNumber' = 'production'
            }
            { Expand-AppSecConfigDetails @TestParams @CommonParams } | Should -throw 'No production-active version*'
        }
        It 'finds the right staging version' {
            $TestParams = @{
                'ConfigID'      = $ProductionActiveConfig.id
                'VersionNumber' = 'staging'
            }
            $StagingConfigID, $ExpandedVersion, $null = Expand-AppSecConfigDetails @TestParams @CommonParams
            $StagingConfigID | Should -Be $StagingActiveConfig.id
            $ExpandedVersion | Should -Be $StagingActiveConfig.stagingVersion
            $AkamaiDataCache.AppSec.Configs.($StagingActiveConfig.name).ConfigID | Should -Be $StagingConfigID
        }
        It 'fails if retrieving staging version and none exist' {
            $TestParams = @{
                'ConfigID'      = $PD.NewConfig.configId
                'VersionNumber' = 'staging'
            }
            { Expand-AppSecConfigDetails @TestParams @CommonParams } | Should -throw 'No staging-active version*'
        }
        It 'finds the right policy by name' {
            $TestParams = @{
                'ConfigName'    = $TestConfigName
                'VersionNumber' = 'latest'
                'PolicyName'    = $PD.NewPolicy.policyName
            }
            $PD.ExpandedConfigID, $PD.ExpandedConfigVersion, $PD.ExpandedPolicyID = Expand-AppSecConfigDetails @TestParams @CommonParams
            $PD.ExpandedConfigID | Should -Be $PD.Config.id
            $PD.ExpandedConfigVersion | Should -Be $PD.Version.version
            $PD.ExpandedPolicyID | Should -Be $PD.NewPolicy.policyId
            $AkamaiDataCache.AppSec.Configs.$TestConfigName.ConfigID | Should -Be $PD.ExpandedConfigID
            $AkamaiDataCache.AppSec.Configs.$TestConfigName.Policies.$TestPolicyName.PolicyID | Should -Be $PD.ExpandedPolicyID
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-AppSecConfigDetails -Force
        }
    }

    #-------------------------------------------------
    #               Behavioral DDoS
    #-------------------------------------------------

    Context 'Behavioral DDoS' -Tag 'Behavioral DDoS' {
        Context 'New-AppSecBehavioralDDOS' {
            It 'retrieves the settings' {
                $TestBDEProfile = @{
                    "hostnames"   = @(
                        $TestHostname
                    )
                    "sensitivity" = "MODERATE"
                    "name"        = "Pester"
                }
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'Body'          = $TestBDEProfile
                }
                $PD.NewBDEProfile = New-AppSecBehavioralDDOS @TestParams @CommonParams
                $PD.NewBDEProfile.profileId | Should -Not -BeNullOrEmpty
                $PD.NewBDEProfile.configId | Should -Be $PD.Config.id
                $PD.NewBDEProfile.hostnames | Should -Be @($TestHostname)
                $PD.NewBDEProfile.name | Should -Be "Pester"
            }
        }

        Context 'Get-AppSecBehavioralDDOS' {
            It 'gets a list of profiles by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
                $BDEProfiles = Get-AppSecBehavioralDDOS @TestParams @CommonParams
                $BDEProfiles[0].configId | Should -Be $PD.Config.id
                $BDEProfiles[0].hostnames | Should -Be @($TestHostname)
                $BDEProfiles[0].name | Should -Be "Pester"
            }
            It 'gets a list of profiles by pipeline' {
                $PD.BDEProfiles = $PD.Version | Get-AppSecBehavioralDDOS @CommonParams
                $PD.BDEProfiles[0].configId | Should -Be $PD.Config.id
                $PD.BDEProfiles[0].hostnames | Should -Be @($TestHostname)
                $PD.BDEProfiles[0].name | Should -Be "Pester"
            }
            It 'gets a single profile by ID' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'ProfileID'     = $PD.NewBDEProfile.profileId
                }
                $PD.BDEProfile = Get-AppSecBehavioralDDOS @TestParams @CommonParams
                $PD.BDEProfile.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.BDEProfile.configId | Should -Be $PD.Config.id
                $PD.BDEProfile.hostnames | Should -Be @($TestHostname)
                $PD.BDEProfile.name | Should -Be "Pester"
            }
        }

        Context 'Set-AppSecBehavioralDDOS' {
            It 'updates by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'ProfileID'     = $PD.NewBDEProfile.profileId
                    'Body'          = $PD.BDEProfile
                }
                $PD.SetBDEProfileParam = Set-AppSecBehavioralDDOS @TestParams @CommonParams
                $PD.SetBDEProfileParam.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.SetBDEProfileParam.configId | Should -Be $PD.Config.id
                $PD.SetBDEProfileParam.hostnames | Should -Be @($TestHostname)
                $PD.SetBDEProfileParam.name | Should -Be "Pester"
            }
            It 'updates by pipeline' {
                $PD.SetBDEProfilePipeline = $PD.BDEProfile | Set-AppSecBehavioralDDOS @CommonParams
                $PD.SetBDEProfilePipeline.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.SetBDEProfilePipeline.configId | Should -Be $PD.Config.id
                $PD.SetBDEProfilePipeline.hostnames | Should -Be @($TestHostname)
                $PD.SetBDEProfilePipeline.name | Should -Be "Pester"
            }
        }

        Context 'Set-AppSecPolicyBehavioralDDOS' {
            It 'sets the profile action for this policy' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'ProfileID'     = $PD.NewBDEProfile.profileId
                    'Action'        = 'alert'
                }
                $PD.SetBDEProfileAction = Set-AppSecPolicyBehavioralDDOS @TestParams @CommonParams
                $PD.SetBDEProfileAction.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.SetBDEProfileAction.action | Should -Be 'alert'
            }

            It 'fails when the action is invalid' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'ProfileID'     = $PD.NewBDEProfile.profileId
                    'Action'        = 'ponder'
                }
                { Set-AppSecPolicyBehavioralDDOS @TestParams @CommonParams } | Should -Throw
            }
        }

        Context 'Get-AppSecPolicyBehavioralDDOS' {
            It 'gets the profile action for this policy by param' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = $PD.NewPolicy.policyId
                }
                $GetBDEProfileAction = Get-AppSecPolicyBehavioralDDOS @TestParams @CommonParams
                $GetBDEProfileAction.profileId | Should -Be $PD.NewBDEProfile.profileId
                $GetBDEProfileAction.action | Should -Be 'alert'
            }
            It 'gets the profile action for this policy by pipeline' {
                $PD.GetBDEProfileAction = $PD.Policy | Get-AppSecPolicyBehavioralDDOS @CommonParams
                $PD.GetBDEProfileAction.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.GetBDEProfileAction.action | Should -Be 'alert'
            }
        }

        Context 'Set-AppSecPolicyBehavioralDDOS' {
            It 'removes the action so we can remove the profile' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                    'PolicyID'      = $PD.NewPolicy.policyId
                    'ProfileID'     = $PD.NewBDEProfile.profileId
                    'Action'        = 'none'
                }
                $PD.SetBDEProfileAction = Set-AppSecPolicyBehavioralDDOS @TestParams @CommonParams
                $PD.SetBDEProfileAction.profileId | Should -Be $PD.NewBDEProfile.profileId
                $PD.SetBDEProfileAction.action | Should -Be 'none'
            }
        }

        Context 'Remove-AppSecBehavioralDDOS' {
            It 'removes successfully' {
                $PD.BDEProfile | Remove-AppSecBehavioralDDOS @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' } 
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                }
                $DebugOutput = & {} | Remove-AppSecBehavioralDDOS @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
    }

    #-------------------------------------------------
    #                   Activations
    #-------------------------------------------------

    Context 'New-AppSecActivation' {
        It 'activates by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Network'            = 'STAGING'
                'NotificationEmails' = 'mail@example.com'
                'Note'               = 'testing'
            }
            $Activate = $PD.Version | New-AppSecActivation @TestParams
            $Activate.activationId | Should -Not -BeNullOrEmpty
        }
        It 'activates by body' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestActivationJSON
            }
            $Activate = New-AppSecActivation @TestParams
            $Activate.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecActivationHistory' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationHistory.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID' = 12345
            }
            $Activations = Get-AppSecActivationHistory @TestParams
            $Activations.count | Should -BeGreaterThan 0
        }
        It 'returns a list by pipeline' {
            $Activations = $PD.Config | Get-AppSecActivationHistory
            $Activations.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecActivationRequestStatus' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationRequestStatus.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns the correct data by pipeline' {
            $ActivationRequest = 'f81c92c5-b150-4c41-9b53-9cef7969150a' | Get-AppSecActivationRequestStatus
            $ActivationRequest.statusId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by param' {
            $TestParams = @{
                'StatusID' = 'f81c92c5-b150-4c41-9b53-9cef7969150a'
            }
            $ActivationRequest = Get-AppSecActivationRequestStatus @TestParams
            $ActivationRequest.statusId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecActivationStatus' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns the correct data by pipeline' {
            $ActivationStatus = 1234 | Get-AppSecActivationStatus
            $ActivationStatus.activationId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by param' {
            $TestParams = @{
                'ActivationID' = 1234
            }
            $ActivationStatus = Get-AppSecActivationStatus @TestParams
            $ActivationStatus.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  Subscriptions
    #-------------------------------------------------

    Context 'Get-AppSecSubscribers' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecSubscribers.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID' = 12345
                'Feature'  = 'AAG_TUNING_REC'
            }
            $Subscribers = Get-AppSecSubscribers @TestParams
            $Subscribers.count | Should -BeGreaterThan 0
        }
        It 'returns a list by pipeline' {
            $TestParams = @{
                'ConfigID' = 12345
            }
            $Subscribers = 'AAG_TUNING_REC' | Get-AppSecSubscribers @TestParams
            $Subscribers.count | Should -BeGreaterThan 0
        }
    }

    Context 'New-AppSecSubscription' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecSubscription.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'    = 12345
                'Feature'     = 'AAG_TUNING_REC'
                'Subscribers' = 'email@example.com', 'email2@example.com'
            }
            New-AppSecSubscription @TestParams
        }
    }

    Context 'Remove-AppSecSubscription' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecSubscription.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'    = 12345
                'Feature'     = 'AAG_TUNING_REC'
                'Subscribers' = 'email@example.com', 'email2@example.com'
            }
            Remove-AppSecSubscription @TestParams
        }
    }

    #-------------------------------------------------
    #             Tuning Recommendations
    #-------------------------------------------------

    Context 'Get-AppSecPolicyTuningRecommendations' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyTuningRecommendations.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by pipeline' {
            $Recommendations = $PD.Policy | Get-AppSecPolicyTuningRecommendations
            $Recommendations.ruleRecommendations | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $Recommendations = Get-AppSecPolicyTuningRecommendations @TestParams
            $Recommendations.ruleRecommendations | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyTuningRecommendations' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyTuningRecommendations.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Action'        = 'ACCEPT'
                'SelectorID'    = 84220
            }
            Set-AppSecPolicyTuningRecommendations @TestParams
        }
    }

    Context 'Get-AppSecPolicyAttackGroupRecommendations' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyAttackGroupRecommendations.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'AttackGroupID' = 'CMD'
            }
            $AttackGroupRecommendations = Get-AppSecPolicyAttackGroupRecommendations @TestParams
            $AttackGroupRecommendations.group | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $TestParams = @{
                'AttackGroupID' = 'CMD'
            }
            $AttackGroupRecommendations = $PD.Policy | Get-AppSecPolicyAttackGroupRecommendations @TestParams
            $AttackGroupRecommendations.group | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRuleRecommendations' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyRuleRecommendations.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'RuleID'        = 12345
            }
            $RuleRecommendations = Get-AppSecPolicyRuleRecommendations @TestParams
            $RuleRecommendations.id | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $TestParams = @{
                'RuleID' = 12345
            }
            $RuleRecommendations = $PD.Policy | Get-AppSecPolicyRuleRecommendations @TestParams
            $RuleRecommendations.id | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                 API Discovery
    #-------------------------------------------------

    Context 'New-AppSecDiscoveredAPIEndpoint' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecDiscoveredAPIEndpoint.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'creates based on existing API' {
            $TestParams = @{
                'Hostname'    = 'www.example.com'
                'BasePath'    = '/api'
                'ApiEndpoint' = 123456
                'Version'     = 1
            }
            $NewDiscoveredAPI = New-AppSecDiscoveredAPIEndpoint @TestParams
            $NewDiscoveredAPI.apiEndPointId | Should -Not -BeNullOrEmpty
            $NewDiscoveredAPI.apiEndPointHosts | Should -Not -BeNullOrEmpty
            $NewDiscoveredAPI.apiEndPointVersion | Should -Not -BeNullOrEmpty
        }
        It 'creates based on new API' {
            $TestParams = @{
                'Hostname'   = 'www.example.com'
                'BasePath'   = '/api'
                'ContractID' = '1-2AB34C'
                'GroupID'    = '12345'
                'APIName'    = 'Pester'
            }
            $NewDiscoveredAPI = New-AppSecDiscoveredAPIEndpoint @TestParams
            $NewDiscoveredAPI.apiEndPointId | Should -Not -BeNullOrEmpty
            $NewDiscoveredAPI.apiEndPointHosts | Should -Not -BeNullOrEmpty
            $NewDiscoveredAPI.apiEndPointVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecDiscoveredAPI' {
        It 'gets a list of apis' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredAPI_1.json"
                return $Response | ConvertFrom-Json
            }
            $DiscoveredAPIs = Get-AppSecDiscoveredAPI
            $DiscoveredAPIs[0].basePath | Should -Not -BeNullOrEmpty
        }
        It 'gets a single discovered API by hostname and path' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Hostname' = 'www.example.com'
                'BasePath' = '/api'
            }
            $PD.DiscoveredAPI = Get-AppSecDiscoveredAPI @TestParams
            $PD.DiscoveredAPI.apiEndpointIds | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Hide-AppSecDiscoveredAPI' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Hide-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'hides the API by param' {
            $TestParams = @{
                'Hostname' = 'www.example.com'
                'BasePath' = '/api'
                'Reason'   = 'NOT_ELIGIBLE'
            }
            $HideDiscoveredAPI = Hide-AppSecDiscoveredAPI @TestParams
            $HideDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
        It 'hides the API by pipeline' {
            $TestParams = @{
                'Reason' = 'NOT_ELIGIBLE'
            }
            $HideDiscoveredAPI = $PD.DiscoveredAPI | Hide-AppSecDiscoveredAPI @TestParams
            $HideDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Show-AppSecDiscoveredAPI' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Show-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'shows the API by param' {
            $TestParams = @{
                'Hostname' = 'www.example.com'
                'BasePath' = '/api'
                'Reason'   = 'FALSE_POSITIVE'
            }
            $ShowDiscoveredAPI = Show-AppSecDiscoveredAPI @TestParams
            $ShowDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
        It 'shows the API by pipeline' {
            $TestParams = @{
                'Reason' = 'FALSE_POSITIVE'
            }
            $ShowDiscoveredAPI = $PD.DiscoveredAPI | Show-AppSecDiscoveredAPI @TestParams
            $ShowDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecDiscoveredApiEndpoints' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredApiEndpoints.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'Hostname' = 'www.example.com'
                'BasePath' = '/api'
            }
            $DiscoveredAPIEndpoints = Get-AppSecDiscoveredApiEndpoints @TestParams
            $DiscoveredAPIEndpoints[0].apiEndpointId | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $DiscoveredAPIEndpoints = $PD.DiscoveredAPI | Get-AppSecDiscoveredApiEndpoints
            $DiscoveredAPIEndpoints[0].apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Match Targets
    #-------------------------------------------------

    Context 'Get-AppSecHostnameMatchTargets' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecHostnameMatchTargets.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns the correct data by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'Hostname'      = 'www.example.com'
            }
            $HostnameMatchTargets = Get-AppSecHostnameMatchTargets @TestParams
            $HostnameMatchTargets.websiteTargets[0].configId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by pipeline' {
            $TestParams = @{
                'Hostname' = 'www.example.com'
            }
            $HostnameMatchTargets = $PD.Version | Get-AppSecHostnameMatchTargets @TestParams
            $HostnameMatchTargets.websiteTargets[0].configId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Hostname Coverage
    #  (moved to unsafe due to timeouts in test account)
    #-------------------------------------------------

    Context 'Get-AppSecHostnameCoverage' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecHostnameCoverage.json"
                return $Response | ConvertFrom-Json
            }
            $Coverage = Get-AppSecHostnameCoverage
            $Coverage.count | Should -BeGreaterThan 0
        }
    }

    #-------------------------------------------------
    #                Hostname Overlap
    #-------------------------------------------------

    Context 'Get-AppSecHostnameOverlap' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecHostnameOverlap.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a list of overlapping versions by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'Hostname'      = 'www.example.com'
            }
            $Overlaps = Get-AppSecHostnameOverlap @TestParams
            $Overlaps.count | Should -BeGreaterThan 0
            $Overlaps[0].configId | Should -BeGreaterThan 0
            $Overlaps[0].configName | Should -BeGreaterThan 0
            $Overlaps[0].contractId | Should -BeGreaterThan 0
        }
        It 'gets a list of overlapping versions by pipeline' {
            $TestParams = @{
                'Hostname' = 'www.example.com'
            }
            $Overlaps = $PD.Version | Get-AppSecHostnameOverlap @TestParams
            $Overlaps.count | Should -BeGreaterThan 0
            $Overlaps[0].configId | Should -BeGreaterThan 0
            $Overlaps[0].configName | Should -BeGreaterThan 0
            $Overlaps[0].contractId | Should -BeGreaterThan 0
        }
    }

    #-------------------------------------------------
    #                Bypass Network Lists
    #-------------------------------------------------

    Context 'Get-AppSecBypassNetworkLists' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
            }
            $BypassNL = Get-AppSecBypassNetworkLists @TestParams
            $BypassNL[0].id | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $PD.BypassNL = $PD.Version | Get-AppSecBypassNetworkLists
            $PD.BypassNL[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecBypassNetworkLists' {
        It 'updates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'NetworkLists'  = '123_EXAMPLE'
            }
            $SetBypassNL = Set-AppSecBypassNetworkLists @TestParams
            $SetBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
        }
    }

    Context 'Get-AppSecPolicyBypassNetworkLists' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'returns a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $GetPolicyBypassNL = Get-AppSecPolicyBypassNetworkLists @TestParams
            $GetPolicyBypassNL[0].id | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $PD.GetPolicyBypassNL = $PD.Policy | Get-AppSecPolicyBypassNetworkLists
            $PD.GetPolicyBypassNL[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyBypassNetworkLists' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $SetPolicyBypassNL = $PD.GetPolicyBypassNL.id | Set-AppSecPolicyBypassNetworkLists @TestParams
            $SetPolicyBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
        }
    }

    #-------------------------------------------------
    #                Policy Selected Hostnames
    #-------------------------------------------------

    Context 'Get-AppSecPolicySelectedHostnames' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $PolicySelectedHostnames = Get-AppSecPolicySelectedHostnames @TestParams
            $PolicySelectedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
        It 'gets a list by pipeline' {
            $PolicySelectedHostnames = $PD.Policy | Get-AppSecPolicySelectedHostnames
            $PolicySelectedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-AppSecPolicySelectedHostnames' {
        It 'adds a hostname successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Add-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Body'          = $TestHostnamesToAdd
            }
            $PD.PolicyAddedHostnames = Add-AppSecPolicySelectedHostnames @TestParams
            $PD.PolicyAddedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicySelectedHostnames' {
        It 'adds a hostname successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Body'          = $PD.PolicyAddedHostnames
            }
            $PolicyUpdatedHostnames = Set-AppSecPolicySelectedHostnames @TestParams
            $PolicyUpdatedHostnames.hostnameList.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-AppSecPolicySelectedHostnames' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'removes the correct hostname by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Body'          = $TestHostnamesToAdd
            }
            $PolicyRemovedHostnames = Remove-AppSecPolicySelectedHostnames @TestParams
            $PolicyRemovedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
        It 'removes the correct hostname by pipeline' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $PolicyRemovedHostnames = $TestHostnamesToAdd | Remove-AppSecPolicySelectedHostnames @TestParams
            $PolicyRemovedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #              Evaluation Hostnames
    #-------------------------------------------------

    Context 'Get-AppSecEvaluationHostnames' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
            }
            $GetEvaluationHostnames = Get-AppSecEvaluationHostnames @TestParams
            $GetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
        It 'gets a list by pipeline' {
            $PD.GetEvaluationHostnames = $PD.Version | Get-AppSecEvaluationHostnames
            $PD.GetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'Body'          = $PD.GetEvaluationHostnames
            }
            $SetEvaluationHostnames = Set-AppSecEvaluationHostnames @TestParams
            $SetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Protect-AppSecEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Protect-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'Body'          = $PD.GetEvaluationHostnames
            }
            $ProtectEvaluationHostnames = Protect-AppSecEvaluationHostnames @TestParams
            $ProtectEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyEvaluationHostnames' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'gets a list by param' {
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
            }
            $GetPolicyEvaluationHostnames = Get-AppSecPolicyEvaluationHostnames @TestParams
            $GetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
        It 'gets a list by pipeline' {
            $PD.GetPolicyEvaluationHostnames = $PD.Policy | Get-AppSecPolicyEvaluationHostnames
            $PD.GetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Body'          = $PD.GetPolicyEvaluationHostnames
            }
            $SetPolicyEvaluationHostnames = Set-AppSecPolicyEvaluationHostnames @TestParams
            $SetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Protect-AppSecPolicyEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Protect-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'ConfigID'      = 12345
                'VersionNumber' = 1
                'PolicyID'      = 'EX01_123456'
                'Body'          = $PD.GetPolicyEvaluationHostnames
            }
            $ProtectPolicyEvaluationHostnames = Protect-AppSecPolicyEvaluationHostnames @TestParams
            $ProtectPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Onboarding
    #-------------------------------------------------

    Context 'Onboarding' -Tag 'Onboarding' {
        BeforeAll {
            $TestOnboardHostname1 = "onboard1-$timestamp.akamaipowershell.com"
            $TestOnboardHostname2 = "onboard2-$timestamp.akamaipowershell.com"
        }
        Context 'New-AppSecOnboarding' {
            It 'creates successfully by param' {
                $TestParams = @{
                    'Hostnames'              = $TestOnboardHostname1
                    'ContractID'             = $TestContractID
                    'GroupID'                = $TestGroupID
                    'CreateNewResourcesOnly' = $false
                }
                $PD.NewOnboardingParam = New-AppSecOnboarding @TestParams @CommonParams
                $PD.NewOnboardingParam.hostnames | Should -Contain $TestOnboardHostname1
                $PD.NewOnboardingParam.contractId | Should -Be $TestContractID
                $PD.NewOnboardingParam.groupId | Should -Be $TestGroupID
                $PD.NewOnboardingParam.onboardingId | Should -Match '^[\d]+$'
            }
            It 'creates successfully by body' {
                $Body = @{
                    'contractId' = $TestContractID
                    'groupId'    = $TestGroupID
                    'hostnames'  = @($TestOnboardHostname2)
                }
                $PD.NewOnboardingBody = $Body | New-AppSecOnboarding @CommonParams
                $PD.NewOnboardingBody.hostnames | Should -Contain $TestOnboardHostname2
                $PD.NewOnboardingBody.contractId | Should -Be $TestContractID
                $PD.NewOnboardingBody.groupId | Should -Be $TestGroupID
                $PD.NewOnboardingBody.onboardingId | Should -Match '^[\d]+$'
            }
        }
    
        Context 'Get-AppSecOnboarding' {
            It 'gets a list' {
                $PD.Onboardings = Get-AppSecOnboarding @CommonParams
                $PD.Onboardings.count | Should -BeGreaterOrEqual 2
                $PD.Onboardings.onboardingId | Should -Contain $PD.NewOnboardingParam.onboardingId
                $PD.Onboardings.onboardingId | Should -Contain $PD.NewOnboardingBody.onboardingId
            }
            It 'gets a list, filtered by hostname' {
                $TestParams = @{
                    'Hostnames' = $TestOnboardHostname1
                }
                $PD.Onboardings = Get-AppSecOnboarding @TestParams @CommonParams
                $PD.Onboardings[0].onboardingId | Should -Be $PD.NewOnboardingParam.onboardingId
            }
            It 'gets a specific onboarding by ID by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboardings[0].onboardingId
                }
                $Onboarding = Get-AppSecOnboarding @TestParams @CommonParams
                $Onboarding.onboardingId | Should -Be $PD.Onboardings[0].onboardingId
            }
            It 'gets a specific onboarding by ID by pipeline' {
                $PD.Onboarding = $PD.Onboardings[0] | Get-AppSecOnboarding @CommonParams
                $PD.Onboarding.onboardingId | Should -Be $PD.Onboardings[0].onboardingId
            }
        }

        Context 'Get-AppSecOnboardingSettings' {
            It 'gets onboard settings' {
                $PD.OnboardingSettings = $PD.Onboarding | Get-AppSecOnboardingSettings @CommonParams
                $PD.OnboardingSettings.delivery.origins[0].hostname | Should -Be $TestOnboardHostname1
                $PD.OnboardingSettings.security | Should -Not -BeNullOrEmpty
                $PD.OnboardingSettings.certificate | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Set-AppSecOnboardingSettings' {
            It 'gets onboard settings' {
                $TestParams = @{
                    'OnboardingID' = $PD.NewOnboardingParam.onboardingId
                }
                $PD.SetOnboardingSettings = $PD.OnboardingSettings | Set-AppSecOnboardingSettings @TestParams @CommonParams
                $PD.SetOnboardingSettings.delivery.origins[0].hostname | Should -Be $TestOnboardHostname1
                $PD.SetOnboardingSettings.security | Should -Not -BeNullOrEmpty
                $PD.SetOnboardingSettings.certificate | Should -Not -BeNullOrEmpty
            }
        }

        Context 'New-AppSecOnboardingActivation' {
            It 'actvates successfully' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecOnboardingActivation.json"
                    return $Response | ConvertFrom-Json
                }
                $TestParams = @{
                    'Network'            = 'STAGING'
                    'NotificationEmails' = 'noreply@akamai.com'
                    'OnboardingID'       = $PD.Onboarding.OnboardingID
                }
                $PD.NewOnboardActivation = New-AppSecOnboardingActivation @TestParams
                $PD.NewOnboardActivation.activationId | Should -Not -BeNullOrEmpty
                $PD.NewOnboardActivation.activationStatus | Should -Not -BeNullOrEmpty
                $PD.NewOnboardActivation.network | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'Get-AppSecOnboardingActivation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecOnboardingActivation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets an activation by param' {
                $TestParams = @{
                    'ActivationID' = $PD.NewOnboardActivation.activationId
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardActivation = Get-AppSecOnboardingActivation @TestParams
                $OnboardActivation.activationId | Should -Not -BeNullOrEmpty
                $OnboardActivation.activationStatus | Should -Not -BeNullOrEmpty
                $OnboardActivation.network | Should -Not -BeNullOrEmpty
            }
            It 'gets an activation by pipeline' {
                $TestParams = @{
                    'ActivationID' = $PD.NewOnboardActivation.activationId
                }
                $PD.OnboardActivation = $PD.Onboarding | Get-AppSecOnboardingActivation @TestParams
                $PD.OnboardActivation.activationId | Should -Not -BeNullOrEmpty
                $PD.OnboardActivation.activationStatus | Should -Not -BeNullOrEmpty
                $PD.OnboardActivation.network | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-AppSecOnboardingCertificateValidation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecOnboardingCertificateValidation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardCertValidation = Get-AppSecOnboardingCertificateValidation @TestParams
                $OnboardCertValidation.certificateValidateLink | Should -Not -BeNullOrEmpty
                $OnboardCertValidation.certificateValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardCertValidation = $PD.Onboarding | Get-AppSecOnboardingCertificateValidation
                $PD.OnboardCertValidation.certificateValidateLink | Should -Not -BeNullOrEmpty
                $PD.OnboardCertValidation.certificateValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Submit-AppSecOnboardingCertificateValidation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Submit-AppSecOnboardingCertificateValidation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'submits a cert validation by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardSubmitCertValidation = Submit-AppSecOnboardingCertificateValidation @TestParams
                $OnboardSubmitCertValidation.certificateValidateLink | Should -Not -BeNullOrEmpty
                $OnboardSubmitCertValidation.certificateValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'submits a cert validation by pipeline' {
                $PD.OnboardSubmitCertValidation = $PD.Onboarding | Submit-AppSecOnboardingCertificateValidation
                $PD.OnboardSubmitCertValidation.certificateValidateLink | Should -Not -BeNullOrEmpty
                $PD.OnboardSubmitCertValidation.certificateValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-AppSecOnboardingCNAMERecord' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecOnboardingCNAMERecord.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardCNAMERecord = Get-AppSecOnboardingCNAMERecord @TestParams
                $OnboardCNAMERecord.cnameValidateLink | Should -Not -BeNullOrEmpty
                $OnboardCNAMERecord.cnameValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardCNAMERecord = $PD.Onboarding | Get-AppSecOnboardingCNAMERecord
                $PD.OnboardCNAMERecord.cnameValidateLink | Should -Not -BeNullOrEmpty
                $PD.OnboardCNAMERecord.cnameValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Submit-AppSecOnboardingCNAMERecord' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Submit-AppSecOnboardingCNAMERecord.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardSubmitCNAMERecord = Submit-AppSecOnboardingCNAMERecord @TestParams
                $OnboardSubmitCNAMERecord.onboardingLink | Should -Not -BeNullOrEmpty
                $OnboardSubmitCNAMERecord.cnameValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardSubmitCNAMERecord = $PD.Onboarding | Submit-AppSecOnboardingCNAMERecord
                $PD.OnboardSubmitCNAMERecord.onboardingLink | Should -Not -BeNullOrEmpty
                $PD.OnboardSubmitCNAMERecord.cnameValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-AppSecOnboardingOriginValidation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecOnboardingOriginValidation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardOriginValidation = Get-AppSecOnboardingOriginValidation @TestParams
                $OnboardOriginValidation.originValidateLink | Should -Not -BeNullOrEmpty
                $OnboardOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardOriginValidation = $PD.Onboarding | Get-AppSecOnboardingOriginValidation
                $PD.OnboardOriginValidation.originValidateLink | Should -Not -BeNullOrEmpty
                $PD.OnboardOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Skip-AppSecOnboardingOriginValidation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Skip-AppSecOnboardingOriginValidation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardSkipOriginValidation = Skip-AppSecOnboardingOriginValidation @TestParams
                $OnboardSkipOriginValidation.onboardingLink | Should -Not -BeNullOrEmpty
                $OnboardSkipOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardSkipOriginValidation = $PD.Onboarding | Skip-AppSecOnboardingOriginValidation
                $PD.OnboardSkipOriginValidation.onboardingLink | Should -Not -BeNullOrEmpty
                $PD.OnboardSkipOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
        }
        
        Context 'Submit-AppSecOnboardingOriginValidation' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Submit-AppSecOnboardingOriginValidation.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'gets certificate validations by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.Onboarding.OnboardingID
                }
                $OnboardSubmitOriginValidation = Submit-AppSecOnboardingOriginValidation @TestParams
                $OnboardSubmitOriginValidation.onboardingLink | Should -Not -BeNullOrEmpty
                $OnboardSubmitOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
            It 'gets certificate validations by pipeline' {
                $PD.OnboardSubmitOriginValidation = $PD.Onboarding | Submit-AppSecOnboardingOriginValidation
                $PD.OnboardSubmitOriginValidation.onboardingLink | Should -Not -BeNullOrEmpty
                $PD.OnboardSubmitOriginValidation.originValidationStatus | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Remove-AppSecOnboarding' {
            It 'removes successfully by param' {
                $TestParams = @{
                    'OnboardingID' = $PD.NewOnboardingParam.onboardingId
                }
                Remove-AppSecOnboarding @TestParams @CommonParams
            }
            It 'removes successfully by pipeline' {
                $PD.NewOnboardingBody | Remove-AppSecOnboarding @CommonParams
            }
            it 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecOnboarding @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
    }

    #-------------------------------------------------
    #                    Diff
    #-------------------------------------------------

    Context 'Compare-AppSecConfigurationVersions' {
        BeforeAll {
            $NewVersion = $PD.Version | New-AppSecConfigurationVersion @CommonParams
            Start-Sleep -Seconds 2
        }
        It 'creates a diff by param' {
            $TestParams = @{
                'ConfigName' = $TestConfigName
                'From'       = 1
                'To'         = $NewVersion.Version
            }
            $Diff = Compare-AppSecConfigurationVersions @TestParams @CommonParams
            $Diff.configId | Should -Be $PD.Config.id
            $Diff.outcome | Should -Not -BeNullOrEmpty
            $Diff.securityPolicies | Should -Not -BeNullOrEmpty
        }
        It 'creates a diff by pipeline' {
            $TestParams = @{
                'To' = $NewVersion.Version
            }
            $PD.Diff = $PD.Version | Compare-AppSecConfigurationVersions @TestParams @CommonParams
            $PD.Diff.configId | Should -Be $PD.Config.id
            $PD.Diff.outcome | Should -Not -BeNullOrEmpty
            $PD.Diff.securityPolicies | Should -Not -BeNullOrEmpty
        }
        AfterAll {
            $NewVersion | Remove-AppSecConfigurationVersion @CommonParams
        }
    }

    #-------------------------------------------------
    #                    Removals
    #-------------------------------------------------

    Context 'Remove-AppSecMatchTarget' {
        Context 'By Pipeline' {
            BeforeEach {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
            }
            It 'removes API target successfully' {
                $PD.NewAPIMatchTarget | Remove-AppSecMatchTarget @TestParams @CommonParams
            }
            It 'removes website target successfully' {
                $PD.NewWebsiteMatchTarget.targetId | Remove-AppSecMatchTarget @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecMatchTarget @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecMatchTarget.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'TargetID'      = 123456
                }
                Remove-AppSecMatchTarget @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecMalwarePolicy' {
        Context 'By Pipeline' {
            BeforeAll {
                $SetParams = @{
                    'ConfigID'        = $PD.Config.id
                    'VersionNumber'   = $PD.Version.version
                    'PolicyID'        = $PD.NewPolicy.policyId
                    'MalwarePolicyID' = $PD.NewMalwarePolicy.id
                    'Action'          = 'none'
                    'UnscannedAction' = 'none'
                }
                Set-AppSecPolicyMalwarePolicy @SetParams @CommonParams | Out-Null
            }
            BeforeEach {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = $PD.Version.version
                }
            }
            It 'completes successfully' {
                $PD.GetMalwarePolicy | Remove-AppSecMalwarePolicy @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecMalwarePolicy @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecMalwarePolicy.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'        = $PD.Config.id
                    'VersionNumber'   = 1
                    'MalwarePolicyID' = 123456
                }
                Remove-AppSecMalwarePolicy @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecPolicy' {
        Context 'By Pipeline' {
            It 'completes successfully' {
                $PD.NewPolicy | Remove-AppSecPolicy @CommonParams
                # Wait for the policy removal to really complete
                Start-Sleep -Seconds 5
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
                $DebugOutput = & {} | Remove-AppSecPolicy @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecPolicy.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'PolicyID'      = 'EX01_123456'
                }
                Remove-AppSecPolicy @TestParams @CommonParams
            }
        }
    }


    Context 'Remove-AppSecReputationProfile' {
        Context 'By Pipeline' {
            BeforeEach {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
            }
            It 'completes successfully' {
                $PD.NewReputationProfileByBody | Remove-AppSecReputationProfile @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecReputationProfile @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecReputationProfile.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'            = $PD.Config.id
                    'VersionNumber'       = 1
                    'ReputationProfileID' = 123456
                }
                Remove-AppSecReputationProfile @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecCustomDenyAction' {
        Context 'By Pipeline' {
            BeforeEach {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
            }
            It 'completes successfully' {
                $PD.NewCustomDenyAction | Remove-AppSecCustomDenyAction @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecCustomDenyAction @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecCustomDenyAction.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'CustomDenyID'  = 123456
                }
                Remove-AppSecCustomDenyAction @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecCustomRule' {
        Context 'By Pipeline' {
            BeforeEach {
                $TestParams = @{
                    'ConfigID' = $PD.Config.id
                }
            }
            It 'completes successfully' {
                $PD.NewCustomRule | Remove-AppSecCustomRule @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecCustomRule @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecCustomRule.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID' = $PD.Config.id
                    'RuleID'   = 123456
                }
                Remove-AppSecCustomRule @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecRatePolicy' {
        Context 'By Pipeline' {
            BeforeEach {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
            }
            It 'completes successfully' {
                $PD.NewRatePolicyByBody | Remove-AppSecRatePolicy @TestParams @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecRatePolicy @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecRatePolicy.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                    'RatePolicyID'  = 123456
                }
                Remove-AppSecRatePolicy @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecURLProtectionPolicy' {
        Context 'By Pipeline' {
            It 'completes successfully' {
                $PD.GetURLProtectionPolicy | Remove-AppSecURLProtectionPolicy @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $TestParams = @{
                    'ConfigID'      = $PD.Config.id
                    'VersionNumber' = 1
                }
                $DebugOutput = & {} | Remove-AppSecURLProtectionPolicy @TestParams @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecURLProtectionPolicy.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID'              = $PD.Config.id
                    'VersionNumber'         = 1
                    'URLProtectionPolicyID' = 123456
                }
                Remove-AppSecURLProtectionPolicy @TestParams @CommonParams
            }
        }
    }

    Context 'Remove-AppSecConfiguration' {
        Context 'By Pipeline' {
            It 'completes successfully' {
                $PD.NewConfig | Remove-AppSecConfiguration @CommonParams
            }
            It 'handles empty input' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith { return 'IAR executed' }
                $DebugOutput = & {} | Remove-AppSecConfiguration @CommonParams -Debug
                $DebugOutput | Should -Not -Be 'IAR executed'
            }
        }
        Context 'By Param' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.AppSec -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecConfiguration.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'mocks removal by param successfully' {
                $TestParams = @{
                    'ConfigID' = $PD.Config.id
                }
                Remove-AppSecConfiguration @TestParams @CommonParams
            }
        }
    }
}


