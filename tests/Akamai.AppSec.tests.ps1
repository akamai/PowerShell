Describe 'Safe Akamai.AppSec Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.AppSec/Akamai.AppSec.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestConfigName = "akamaipowershell"
        $TestConfigDescription = "Powershell pester testing. Will be deleted shortly."
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestHostnames = $env:PesterHostname
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
{"type":"website","hostnames": [ "$TestHostnames" ], "filePaths": [ "/*" ], "securityPolicy": { "policyId": "REPLACE_POLICY_ID" }}
"@
        $TestSiteMatchTarget = ConvertFrom-Json $TestSiteMatchTargetBody
        $TestNetworkListID = $env:PesterNetworkListID
        $TestCustomDenyName = 'SampleCustomDeny'
        $TestCustomDenyBody = @"
{"name":"$TestCustomDenyName","description": "Old Description","parameters":[{"displayName":"Hostname","name":"custom_deny_hostname","value":"deny.$TestHostnames"},{"displayName":"Path","name":"custom_deny_path","value":"/"},{"displayName":"IncludeAkamaiReferenceID","name":"include_reference_id","value":"true"},{"displayName":"IncludeTrueClientIP","name":"include_true_ip","value":"false"},{"displayName":"Preventbrowsercaching","name":"prevent_browser_cache","value":"true"},{"displayName":"Responsecontenttype","name":"response_content_type","value":"application/json"},{"displayName":"Responsestatuscode","name":"response_status_code","value":"403"}]}
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
{"hostnamePaths":[{"hostname":"$TestHostnames","paths":["/login"]}],"intelligentLoadShedding":false,"name":"Powershell test policy","rateThreshold":195}
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
        $PD = @{}
    }
    
    AfterAll {
        # Cleanup, in case of error
        Get-AppSecConfiguration @CommonParams | Where-Object name -eq $TestConfigName | ForEach-Object { Remove-AppSecConfiguration -ConfigID $_.id @CommonParams }
    }


    #-------------------------------------------------
    #                 Configuration                  
    #-------------------------------------------------

    Context 'New-AppSecConfiguration' {
        It 'creates successfully' {
            $PD.NewConfig = New-AppSecConfiguration -Name $TestConfigName -Description $TestConfigDescription -GroupID $TestGroupID -ContractId $TestContract -Hostnames $TestHostnames @CommonParams
            $PD.NewConfig.name | Should -Be $TestConfigName
        }
    }

    Context 'Get-AppSecConfiguration' {
        It 'gets a list of configs' {
            $PD.Configs = Get-AppSecConfiguration @CommonParams
            $PD.Configs | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecConfiguration by Name' {
        It 'finds the config' {
            $PD.Config = Get-AppSecConfiguration -ConfigName $TestConfigName @CommonParams
            $PD.Config | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecConfiguration by ID' {
        It 'finds the config' {
            $PD.Config = Get-AppSecConfiguration -ConfigID $PD.NewConfig.configId @CommonParams
            $PD.Config | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Rename-AppSecConfiguration' {
        It 'successfully renames' {
            $PD.RenameResult = Rename-AppSecConfiguration -ConfigID $PD.NewConfig.configId -NewName $TestConfigName -Description $TestConfigDescription @CommonParams
            $PD.RenameResult.Name | Should -Be $TestConfigName
        }
    }

    #-------------------------------------------------
    #                  Custom Rules                  
    #-------------------------------------------------

    Context 'New-AppSecCustomRule' {
        It 'creates successfully' {
            $PD.NewCustomRule = New-AppSecCustomRule -ConfigID $PD.NewConfig.configId -Body $TestCustomRule @CommonParams
            $PD.NewCustomRule.id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecCustomRule' {
        It 'returns something' {
            $PD.CustomRules = Get-AppSecCustomRule -ConfigID $PD.NewConfig.configId @CommonParams
            $PD.CustomRules | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecCustomRule by ID' {
        It 'returns newly created rule' {
            $PD.CustomRule = Get-AppSecCustomRule -ConfigID $PD.NewConfig.configId -RuleID $PD.NewCustomRule.id @CommonParams
            $PD.CustomRule.id | Should -Be $PD.NewCustomRule.id
        }
    }

    Context 'Set-AppSecCustomRule by pipeline' {
        It 'completes successfully' {
            $PD.SetCustomRule = $PD.NewCustomRule | Set-AppSecCustomRule -ConfigID $PD.NewConfig.configId -RuleID $PD.NewCustomRule.id @CommonParams 
        }
    }

    Context 'Set-AppSecCustomRule by body' {
        It 'completes successfully' {
            $PD.SetCustomRule = Set-AppSecCustomRule -ConfigID $PD.NewConfig.configId -RuleID $PD.NewCustomRule.id -Body $TestCustomRule @CommonParams 
        }
    }

    #-------------------------------------------------
    #               Failover Hostnames               
    #-------------------------------------------------

    Context 'Get-AppSecFailoverHostnames' {
        It 'does not throw' {
            $PD.FailoverHostnames = Get-AppSecFailoverHostnames -ConfigID $PD.NewConfig.configId @CommonParams 
        }
    }

    #-------------------------------------------------
    #               Version Notes                    
    #-------------------------------------------------

    Context 'Set-AppSecVersionNotes' {
        It 'sets notes correctly' {
            $PD.SetNotes = Set-AppSecVersionNotes -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Notes $TestNotes @CommonParams
            $PD.SetNotes | Should -Be $TestNotes
        }
    }

    Context 'Get-AppSecVersionNotes' {
        It 'gets notes correctly' {
            $PD.GetNotes = Get-AppSecVersionNotes -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.GetNotes | Should -Be $TestNotes
        }
    }

    #-------------------------------------------------
    #                    Hostnames                   
    #-------------------------------------------------

    Context 'Get-AppSecSelectableHostname' {
        It 'gets a list' {
            $PD.SelectableHostnames = Get-AppSecSelectableHostnames -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecSelectedHostnames' {
        It 'gets a list' {
            $PD.SelectedHostnames = Get-AppSecSelectedHostnames -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.SelectedHostnames.hostnameList.hostname | Should -Be $TestHostnames
        }
    }

    Context 'Add-AppSecSelectedHostnames' {
        It 'adds a hostname successfully' {
            $PD.AddedHostnames = Add-AppSecSelectedHostnames -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestHostnamesToAdd @CommonParams
            $PD.AddedHostnames.hostnameList.hostname | Should -Contain $TestNewHostname
        }
    }
    
    Context 'Set-AppSecSelectedHostnames' {
        It 'adds a hostname successfully' {
            $PD.UpdatedHostnames = Set-AppSecSelectedHostnames -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $PD.AddedHostnames @CommonParams
            $PD.UpdatedHostnames.hostnameList.count | Should -Be 2
        }
    }

    Context 'Remove-AppSecSelectedHostnames' {
        It 'removes the correct hostname' {
            $PD.RemovedHostnames = Remove-AppSecSelectedHostnames -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestHostnamesToAdd @CommonParams
            $PD.RemovedHostnames.hostnameList.hostname | Should -Not -Contain $TestNewHostname
        }
    }

    Context 'Get-AppSecAvailableHostname' {
        It 'gets a list' {
            $PD.SelectableHostnames = Get-AppSecAvailableHostnames -ContractID $TestContract -GroupID $TestGroupID @CommonParams
            $PD.SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                    Policies                    
    #-------------------------------------------------

    Context 'New-AppSecPolicy' {
        It 'creates correctly without cloning' {
            $PD.NewPolicy = New-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyName $TestPolicyName -PolicyPrefix $TestPolicyPrefix @CommonParams
            $PD.NewPolicy.policyName | Should -Be $TestPolicyName
        }
        It 'creates correctly by cloning policy by name' {
            $PD.NewPolicyCloneName = New-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyName "$TestPolicyName-clonename" -PolicyPrefix "clo1" -CreateFromPolicyName $TestPolicyName @CommonParams
            $PD.NewPolicyCloneName.policyName | Should -Be "$TestPolicyName-clonename"
        }
        It 'creates correctly by cloning policy by ID' {
            $PD.NewPolicyCloneID = New-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyName "$TestPolicyName-cloneid" -PolicyPrefix "clo2" -CreateFromPolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.NewPolicyCloneID.policyName | Should -Be "$TestPolicyName-cloneid"
        }
    }

    Context 'Get-AppSecPolicy' {
        It 'returns a list' {
            $PD.Policies = Get-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.Policies[0].policyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicy by ID and version' {
        It 'by ID returns the correct policy' {
            $PD.PolicyByID = Get-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId  @CommonParams
            $PD.PolicyByID.policyId | Should -Be $PD.NewPolicy.policyId
        }
    }

    Context 'Get-AppSecPolicy by name and latest' {
        It 'by name returns the correct policy' {
            $PD.PolicyByName = Get-AppSecPolicy -ConfigName $TestConfigName -VersionNumber latest -PolicyID $PD.NewPolicy.policyId  @CommonParams
            $PD.PolicyByName.policyId | Should -Be $PD.NewPolicy.policyId
        }
    }

    Context 'Set-AppSecPolicy to new name' {
        It 'updates correctly' {
            $PD.RenamePolicy = Set-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -NewName "Temp" @CommonParams
            $PD.RenamePolicy.policyName | Should -Be "Temp"
        }
    }

    Context 'Set-AppSecPolicy back to old name in case we need it later' {
        It 'updates correctly' {
            $PD.SetPolicy = Set-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -NewName $TestPolicyName @CommonParams
            $PD.SetPolicy.policyName | Should -Be $TestPolicyName
        }
    }

    #-------------------------------------------------
    #                  Match Targets                 
    #-------------------------------------------------

    Context 'New-AppSecMatchTarget, API' {
        It 'creates correctly' {
            $TestAPIMatchTarget.securityPolicy.policyId = $PD.NewPolicy.policyId
            $PD.NewAPIMatchTarget = New-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestAPIMatchTarget @CommonParams
            $PD.NewAPIMatchTarget.configId | Should -Be $PD.NewConfig.configId
        }
    }
    
    Context 'New-AppSecMatchTarget, website' {
        It 'creates correctly' {
            $TestSiteMatchTarget.securityPolicy.policyId = $PD.NewPolicy.policyId
            $PD.NewWebsiteMatchTarget = New-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestSiteMatchTarget @CommonParams
            $PD.NewWebsiteMatchTarget.configId | Should -Be $PD.NewConfig.configId
        }
    }

    Context 'Get-AppSecMatchTarget' {
        It 'returns a list' {
            $PD.MatchTargets = Get-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.MatchTargets.apiTargets | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecMatchTarget by ID' {
        It 'returns the correct target' {
            $PD.MatchTarget = Get-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -TargetID $PD.NewAPIMatchTarget.targetId @CommonParams
            $PD.MatchTarget | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecMatchTarget by pipeline' {
        It 'updates successfully' {
            $PD.SetMatchTargetByPipeline = ( $PD.NewAPIMatchTarget | Set-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -TargetID $PD.NewAPIMatchTarget.targetId @CommonParams )
            $PD.SetMatchTargetByPipeline.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
        }
    }

    Context 'Set-AppSecMatchTarget by param' {
        It 'updates successfully' {
            $PD.SetMatchTargetByParam = Set-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -TargetID $PD.NewAPIMatchTarget.targetId -Body $PD.NewAPIMatchTarget @CommonParams
            $PD.SetMatchTargetByParam.targetId | Should -Be $PD.NewAPIMatchTarget.targetId
        }
    }


    #-------------------------------------------------
    #                IP/Geo Firewall                 
    #-------------------------------------------------

    Context 'Get-AppSecPolicyIPGeoFirewall' {
        It 'returns the correct data' {
            $PD.IPGeo = Get-AppSecPolicyIPGeoFirewall -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.IPGeo.block | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyIPGeoFirewall by pipeline' {
        It 'returns the correct data' {
            $PD.SetIPGeoByPipeline = ($PD.IPGeo | Set-AppSecPolicyIPGeoFirewall -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetIPGeoByPipeline.block | Should -Be $PD.IPGeo.block
        }
    }

    Context 'Set-AppSecPolicyIPGeoFirewall by param' {
        It 'returns the correct data' {
            $PD.SetIPGeoByParam = Set-AppSecPolicyIPGeoFirewall -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body $PD.IPGeo @CommonParams
            $PD.SetIPGeoByParam.block | Should -Be $PD.IPGeo.block
        }
    }

    #-------------------------------------------------
    #                  Rate Policies                 
    #-------------------------------------------------

    Context 'New-AppSecRatePolicy by body' {
        It 'creates correctly' {
            $PD.NewRatePolicyByBody = New-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestRatePolicyBody @CommonParams
            $PD.NewRatePolicyByBody.name | Should -Be $TestRatePolicy1Name
        }
    }

    Context 'New-AppSecRatePolicy by pipeline' {
        It 'creates correctly' {
            $PD.NewRatePolicyByPipeline = $TestRatePolicy | New-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.NewRatePolicyByPipeline.name | Should -Be $TestRatePolicy2Name
        }
    }

    Context 'Get-AppSecRatePolicy' {
        It 'returns a list' {
            $PD.RatePolicies = Get-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.RatePolicies.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecRatePolicy by ID' {
        It 'returns the correct policy' {
            $PD.RatePolicy = Get-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -RatePolicyID $PD.NewRatePolicyByBody.id @CommonParams
            $PD.RatePolicy.name | Should -Be $TestRatePolicy1Name
        }
    }

    Context 'Set-AppSecRatePolicy by pipeline' {
        It 'returns the correct policy' {
            $PD.SetRatePolicyByPipeline = ($PD.NewRatePolicyByBody | Set-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -RatePolicyID $PD.NewRatePolicyByBody.id @CommonParams)
            $PD.SetRatePolicyByPipeline.name | Should -Be $TestRatePolicy1Name
        }
    }

    Context 'Set-AppSecRatePolicy by param' {
        It 'returns the correct policy' {
            $PD.SetRatePolicyByParam = Set-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -RatePolicyID $PD.NewRatePolicyByBody.id -Body $PD.NewRatePolicyByBody @CommonParams
            $PD.SetRatePolicyByParam.name | Should -Be $TestRatePolicy1Name
        }
    }

    #-------------------------------------------------
    #                   Custom Deny                  
    #-------------------------------------------------

    Context 'New-AppSecCustomDenyAction' {
        It 'creates correctly' {
            $PD.NewCustomDenyAction = New-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestCustomDenyBody @CommonParams
            $PD.NewCustomDenyAction.name | Should -Be $TestCustomDenyName
        }
    }

    Context 'Get-AppSecCustomDenyAction' {
        It 'lists correctly' {
            $PD.CustomDenyActions = Get-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.CustomDenyActions[0].name | Should -Be $TestCustomDenyName
        }
    }

    Context 'Get-AppSecCustomDenyAction by ID' {
        It 'returns the correct action' {
            $PD.CustomDenyAction = Get-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 -CustomDenyID $PD.NewCustomDenyAction.id @CommonParams
            $PD.CustomDenyAction.name | Should -Be $TestCustomDenyName
        }
    }

    Context 'Set-AppSecCustomDenyAction by pipeline' {
        It 'updates correctly' {
            $PD.NewCustomDenyAction.description = "updated"
            $PD.SetCustomDenyActionByPipeline = ($PD.NewCustomDenyAction | Set-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 -CustomDenyID $PD.NewCustomDenyAction.id @CommonParams)
            $PD.SetCustomDenyActionByPipeline.description | Should -Be "updated"
        }
    }

    Context 'Set-AppSecCustomDenyAction' {
        It 'by param updates correctly' {
            $PD.SetCustomDenyActionByParam = Set-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 -CustomDenyID $PD.NewCustomDenyAction.id -Body $PD.NewCustomDenyAction @CommonParams
            $PD.NewCustomDenyAction.description = "updated"
            $PD.SetCustomDenyActionByParam.description | Should -Be "updated"
        }
    }

    #-------------------------------------------------
    #                       SIEM                     
    #-------------------------------------------------

    
    Context 'Set-AppSecSiemSettings by body' {
        It 'updates correctly' {
            $PD.SetSIEMSettings = Set-AppSecSiemSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestSiemSettingsBody @CommonParams
            $PD.SetSIEMSettings.enableForAllPolicies | Should -Be $true
        }
    }

    Context 'Set-AppSecSiemSettings by pipeline' {
        It 'updates correctly' {
            $PD.SetSIEMSettings = ($TestSiemSettings | Set-AppSecSiemSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetSIEMSettings.enableForAllPolicies | Should -Be $true
        }
    }

    Context 'Get-AppSecSiemSettings by pipeline' {
        It 'gets the right settings' {
            $PD.SIEMSettings = Get-AppSecSiemSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.SIEMSettings.enableForAllPolicies | Should -Be $true
        }
    }

    #-------------------------------------------------
    #               Reputation Profiles              
    #-------------------------------------------------

    Context 'New-AppSecReputationProfile by body' {
        It 'creates correctly' {
            $PD.NewReputationProfileByBody = New-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestReputationProfileBody @CommonParams
            $PD.NewReputationProfileByBody.name | Should -Be $TestReputationProfile1Name
        }
    }

    Context 'New-AppSecReputationProfile by pipeline' {
        It 'creates correctly' {
            $PD.NewReputationProfileByPipeline = ($TestReputationProfile | New-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.NewReputationProfileByPipeline.name | Should -Be $TestReputationProfile2Name
        }
    }

    Context 'Get-AppSecReputationProfile' {
        It 'returns a list' {
            $PD.ReputationProfiles = Get-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.ReputationProfiles.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecReputationProfile by ID' {
        It 'returns the correct profile' {
            $PD.ReputationProfile = Get-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -ReputationProfileID $PD.NewReputationProfileByBody.id @CommonParams
            $PD.ReputationProfile.id | Should -Be $PD.NewReputationProfileByBody.id
        }
    }

    Context 'Set-AppSecReputationProfile by pipeline' {
        It 'updates the correct profile' {
            $PD.SetReputationProfileByPipeline = ($PD.NewReputationProfileByBody | Set-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -ReputationProfileID $PD.NewReputationProfileByBody.id @CommonParams)
            $PD.SetReputationProfileByPipeline.id | Should -Be $PD.NewReputationProfileByBody.id
        }
    }

    Context 'Set-AppSecReputationProfile by param' {
        It 'updates the correct profile' {
            $PD.SetReputationProfileByParam = Set-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -ReputationProfileID $PD.NewReputationProfileByBody.id -Body $PD.NewReputationProfileByBody @CommonParams
            $PD.SetReputationProfileByParam.id | Should -Be $PD.NewReputationProfileByBody.id
        }
    }

    #-------------------------------------------------
    #                    Advanced                    
    #-------------------------------------------------

    Context 'Get-AppSecEvasivePathMatch' {
        It 'returns the correct data' {
            $PD.EvasivePathMatch = Get-AppSecEvasivePathMatch -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.EvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecEvasivePathMatch' {
        It 'updates correctly' {
            $PD.SetEvasivePathMatch = Set-AppSecEvasivePathMatch -ConfigID $PD.NewConfig.configId -VersionNumber 1 -EnablePathMatch $true @CommonParams
            $PD.SetEvasivePathMatch.enablePathMatch | Should -Be $true
        }
    }

    Context 'Get-AppSecLogging' {
        It 'returns the correct data' {
            $PD.Logging = Get-AppSecLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.Logging.allowSampling | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecLogging by pipeline' {
        It 'updates correctly' {
            $PD.SetLoggingByPipeline = ($PD.Logging | Set-AppSecLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetLoggingByPipeline.allowSampling | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecLogging by body' {
        It 'updates correctly' {
            $PD.SetLoggingByBody = Set-AppSecLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body (ConvertTo-Json -Depth 10 $PD.Logging) @CommonParams
            $PD.SetLoggingByBody.allowSampling | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPragmaSettings by body' {
        It 'returns the correct data' {
            $PD.SetPragmaSettingsByBody = Set-AppSecPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $TestPragmaSettingsBody @CommonParams
            $PD.SetPragmaSettingsByBody.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPragmaSettings by pipeline' {
        It 'returns the correct data' {
            $PD.SetPragmaSettingsByPipeline = ($TestPragmaSettings | Set-AppSecPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetPragmaSettingsByPipeline.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPragmaSettings' {
        It 'returns the correct data' {
            $PD.PragmaSettings = Get-AppSecPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.PragmaSettings.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPrefetch' {
        It 'returns the correct data' {
            $PD.Prefetch = Get-AppSecPrefetch -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.Prefetch.enableAppLayer | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPrefetch by pipeline' {
        It 'updates correctly' {
            $PD.SetPrefetchByPipeline = ($PD.Prefetch | Set-AppSecPrefetch -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetPrefetchByPipeline.enableAppLayer | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPrefetch by body' {
        It 'updates correctly' {
            $PD.SetPrefetchByBody = Set-AppSecPrefetch -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body (ConvertTo-Json -Depth 10 $PD.Prefetch) @CommonParams
            $PD.SetPrefetchByBody.enableAppLayer | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecRequestSizeLimit' {
        It 'returns the correct data' {
            $PD.RequestSizeLimit = Get-AppSecRequestSizeLimit -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.RequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecRequestSizeLimit' {
        It 'updates correctly' {
            $PD.SetRequestSizeLimit = Set-AppSecRequestSizeLimit -ConfigID $PD.NewConfig.configId -VersionNumber 1 -RequestSizeLimit 32 @CommonParams
            $PD.SetRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 32
        }
    }
    
    Context 'Get-AppSecAttackPayloadSettings' {
        It 'returns the correct data' {
            $PD.AttackPayloadSettings = Get-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.AttackPayloadSettings.requestBody | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecAttackPayloadSettings by Body' {
        It 'updates correctly' {
            $PD.SetAttackPayloadSettingsByBody = Set-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -Body $PD.AttackPayloadSettings @CommonParams
            $PD.SetAttackPayloadSettingsByBody.requestBody | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecAttackPayloadSettings by Pipeline' {
        It 'updates correctly' {
            $PD.SetAttackPayloadSettingsByPipeline = ($PD.AttackPayloadSettings | Set-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetAttackPayloadSettingsByPipeline.requestBody | Should -Not -BeNullOrEmpty
        }
    }
   
    Context 'Get-AppSecPIISettings' {
        It 'returns the correct data' {
            $PD.PIISettings = Get-AppSecPIISettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.PIISettings.enablePiiLearning | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPIISettings by param' {
        It 'updates correctly' {
            $PD.SetPIISettingsByParam = Set-AppSecPIISettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -EnablePIILearning @CommonParams
            $PD.SetPIISettingsByParam.enablePiiLearning | Should -Be $true
        }
    }
    
    Context 'Set-AppSecPIISettings by pipeline' {
        It 'updates correctly' {
            $PD.SetPIISettingsByPipeline = ($PD.PIISettings | Set-AppSecPIISettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams)
            $PD.SetPIISettingsByPipeline.enablePiiLearning | Should -Be $PD.PIISettings.enablePiiLearning
        }
    }

    #-------------------------------------------------
    #                   Protections                  
    #-------------------------------------------------

    Context 'Get-AppSecPolicyProtections' {
        It 'returns the correct data' {
            $PD.Protections = Get-AppSecPolicyProtections -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.Protections.applyApiConstraints | Should -Not -BeNullOrEmpty
            
            # Enable all protections for later use
            $PD.Protections.PSObject.Properties.Name | ForEach-Object {
                $PD.Protections.$_ = $true
            }
        }
    }


    Context 'Set-AppSecPolicyProtections by pipeline' {
        It 'updates correctly' {
            $PD.SetProtectionsByPipeline = ($PD.Protections | Set-AppSecPolicyProtections -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetProtectionsByPipeline.applyApiConstraints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyProtections by body' {
        It 'updates correctly' {
            $PD.SetProtectionsByBody = Set-AppSecPolicyProtections -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PD.Protections) @CommonParams
            $PD.SetProtectionsByBody.applyApiConstraints | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                   Penalty Box                  
    #-------------------------------------------------

    Context 'Get-AppSecPolicyPenaltyBox' {
        It 'returns the correct data' {
            $PD.PenaltyBox = Get-AppSecPolicyPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPenaltyBox by pipeline' {
        It 'updates correctly' {
            $PD.SetPenaltyBoxByPipeline = ($PD.PenaltyBox | Set-AppSecPolicyPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPenaltyBox by body' {
        It 'updates correctly' {
            $PD.SetPenaltyBoxByBody = Set-AppSecPolicyPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PD.PenaltyBox) @CommonParams
            $PD.SetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Rate Policy Actions              
    #-------------------------------------------------

    Context 'Set-AppSecPolicyRatePolicy' {
        It 'updates correctly' {
            $PD.SetRatePolicyAction = Set-AppSecPolicyRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RatePolicyID $PD.NewRatePolicyByBody.id -IPv4Action alert -IPv6Action alert @CommonParams
            $PD.SetRatePolicyAction.ipv4Action | Should -Be 'alert'
        }
    }

    Context 'Get-AppSecPolicyRatePolicy' {
        It 'returns the correct data' {
            $PD.RatePolicyActions = Get-AppSecPolicyRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.RatePolicyActions[0].id | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #             API Request Constraints            
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAPIRequestConstraints' {
        It 'returns a list' {
            $PD.APIRequestConstraints = Get-AppSecPolicyAPIRequestConstraints -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.APIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAPIRequestConstraints without ID' {
        It 'returns a list of actions' {
            $PD.SetAPIRequestConstraints = Set-AppSecPolicyAPIRequestConstraints -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Action "alert" @CommonParams
            $PD.SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAPIRequestConstraints with ID' {
        It 'returns the correct action' {
            $PD.SetAPIRequestConstraint = Set-AppSecPolicyAPIRequestConstraints -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -ApiID $TestAPIEndpointID -Action "alert" @CommonParams
            $PD.SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Reputation Analysis              
    #-------------------------------------------------

    Context 'Get-AppSecPolicyReputationAnalysis' {
        It 'returns the correct data' {
            $PD.ReputationAnalysis = Get-AppSecPolicyReputationAnalysis -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.ReputationAnalysis.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyReputationAnalysis by pipeline' {
        It 'updates correctly' {
            $PD.SetReputationAnalysisByPipeline = ($PD.ReputationAnalysis | Set-AppSecPolicyReputationAnalysis -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetReputationAnalysisByPipeline.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyReputationAnalysis by body' {
        It 'updates correctly' {
            $PD.SetReputationAnalysisByBody = Set-AppSecPolicyReputationAnalysis -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PD.ReputationAnalysis) @CommonParams
            $PD.SetReputationAnalysisByBody.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #            Reputation Profile Actions          
    #-------------------------------------------------

    Context 'Get-AppSecPolicyReputationProfile' {
        It 'returns a list' {
            $PD.ReputationProfileActions = Get-AppSecPolicyReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.ReputationProfileActions.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecPolicyReputationProfile by ID' {
        It 'returns a list' {
            $PD.ReputationProfileAction = Get-AppSecPolicyReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -ReputationProfileID $PD.ReputationProfileActions[0].id @CommonParams
            $PD.ReputationProfileAction.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyReputationProfile' {
        It 'updates correctly' {
            $PD.SetReputationProfileAction = Set-AppSecPolicyReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -ReputationProfileID $PD.ReputationProfileActions[0].id -Action "deny" @CommonParams
            $PD.SetReputationProfileAction.action | Should -Be "deny"
        }
    }

    #-------------------------------------------------
    #                    Slow POST                   
    #-------------------------------------------------

    Context 'Get-AppSecPolicySlowPost' {
        It 'returns the correct data' {
            $PD.SlowPost = Get-AppSecPolicySlowPost -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.ReputationProfileActions.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicySlowPost by pipeline' {
        It 'completes successfully' {
            $PD.SetSlowPostByPipeline = ($PD.SlowPost | Set-AppSecPolicySlowPost -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetSlowPostByPipeline.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicySlowPost by body' {
        It 'completes successfully' {
            $PD.SetSlowPostByBody = Set-AppSecPolicySlowPost -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -depth 10 $PD.SlowPost) @CommonParams
            $PD.SetSlowPostByBody.action | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Custom Rule Actions              
    #-------------------------------------------------

    Context 'Get-AppSecPolicyCustomRules' {
        It 'returns a list' {
            $PD.CustomRuleActions = Get-AppSecPolicyCustomRules -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.CustomRuleActions[0].action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyCustomRule' {
        It 'updates successfully' {
            $PD.SetCustomRuleAction = Set-AppSecPolicyCustomRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $PD.NewCustomRule.id -Action 'deny' @CommonParams
            $PD.SetCustomRuleAction.action | Should -Be 'deny'
        }
    }

    Context 'Set-AppSecPolicyCustomRule (undo so we can delete later)' {
        It 'updates successfully' {
            $PD.UnsetCustomRuleAction = Set-AppSecPolicyCustomRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $PD.NewCustomRule.id -Action 'none' @CommonParams
            $PD.UnsetCustomRuleAction.action | Should -Be 'none'
        }
    }

    #-------------------------------------------------
    #             Policy Advanced Settings           
    #-------------------------------------------------

    Context 'Get-AppSecPolicyEvasivePathMatch' {
        It 'returns the correct data' {
            $PD.PolicyEvasivePathMatch = Get-AppSecPolicyEvasivePathMatch -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyEvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvasivePathMatch' {
        It 'updates correctly' {
            $PD.PolicyEvasivePathMatch = Set-AppSecPolicyEvasivePathMatch -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -EnablePathMatch $true @CommonParams
            $PD.PolicyEvasivePathMatch.enablePathMatch | Should -Be $true
        }
    }

    Context 'Get-AppSecPolicyLogging' {
        It 'returns the correct data' {
            $PD.PolicyLogging = Get-AppSecPolicyLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyLogging.override | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecPolicyLogging by pipeline' {
        It 'updates correctly' {
            $PD.SetPolicyLoggingByPipeline = ($PD.PolicyLogging | Set-AppSecPolicyLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetPolicyLoggingByPipeline.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyLogging by body' {
        It 'updates correctly' {
            $PD.SetPolicyLoggingByBody = Set-AppSecPolicyLogging -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -depth 10 $PD.PolicyLogging) @CommonParams
            $PD.SetPolicyLoggingByBody.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyPragmaSettings' {
        It 'returns the correct data' {
            $PD.PolicyPragma = Get-AppSecPolicyPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyPragma.override | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPragmaSettings by pipeline' {
        It 'returns the correct data' {
            $PD.SetPolicyPragmaByPipeline = ($TestPragmaSettings | Set-AppSecPolicyPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetPolicyPragmaByPipeline.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyPragmaSettings by body' {
        It 'returns the correct data' {
            $PD.SetPolicyPragmaByBody = Set-AppSecPolicyPragmaSettings -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body $TestPragmaSettingsBody @CommonParams
            $PD.SetPolicyPragmaByBody.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRequestSizeLimit' {
        It 'returns the correct data' {
            $PD.PolicyRequestSizeLimit = Get-AppSecPolicyRequestSizeLimit -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRequestSizeLimit' {
        It 'updates correctly' {
            $PD.SetPolicyRequestSizeLimit = Set-AppSecPolicyRequestSizeLimit -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RequestSizeLimit 8 -Override @CommonParams
            $PD.SetPolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 8
            $PD.SetPolicyRequestSizeLimit.override | Should -Be $true
        }
    }

    #-------------------------------------------------
    #                      WAF                       
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAttackGroup' {
        It 'returns the correct data' {
            $PD.AttackGroups = Get-AppSecPolicyAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.AttackGroups.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecPolicyAttackGroup by ID' {
        It 'returns the correct data' {
            $PD.AttackGroup = Get-AppSecPolicyAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $PD.AttackGroups[0].group @CommonParams
            $PD.AttackGroup.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAttackGroup' {
        It 'sets correctly' {
            $PD.SetAttackGroup = Set-AppSecPolicyAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $PD.AttackGroups[0].group -Action "deny" @CommonParams
            $PD.SetAttackGroup.action | Should -Be "deny"
        }
    }

    Context 'Set-AppSecPolicyAttackGroupExceptions by pipeline' {
        It 'sets correctly' {
            $PD.SetAttackGroupExceptionsByPipeline = ($TestException | Set-AppSecPolicyAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID @CommonParams)
            $PD.SetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAttackGroupExceptions by body' {
        It 'sets correctly' {
            $PD.SetAttackGroupExceptionsByBody = Set-AppSecPolicyAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID -Body $TestExceptionBody @CommonParams
            $PD.SetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyAttackGroupExceptions' {
        It 'returns the correct data' {
            $PD.AttackGroupExceptions = Get-AppSecPolicyAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID @CommonParams
            $PD.AttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRuleExceptions by pipeline' {
        It 'sets correctly' {
            $PD.SetRuleExceptionsByPipeline = ($TestException | Set-AppSecPolicyRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams)
            $PD.SetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRuleExceptions by body' {
        It 'sets correctly' {
            $PD.SetRuleExceptionsByBody = Set-AppSecPolicyRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID -Body $TestExceptionBody @CommonParams
            $PD.SetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRuleExceptions' {
        It 'returns the correct data' {
            $PD.RuleExceptions = Get-AppSecPolicyRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams
            $PD.RuleExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyMode' {
        It 'returns the correct data' {
            $PD.PolicyMode = Get-AppSecPolicyMode -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyMode.mode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyMode' {
        It 'sets correctly' {
            $PD.SetPolicyMode = Set-AppSecPolicyMode -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Mode ASE_MANUAL @CommonParams
            $PD.SetPolicyMode.mode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRule' {
        It 'returns a list' {
            $PD.PolicyRules = Get-AppSecPolicyRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyRules.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecPolicyRule by ID' {
        It 'returns the correct data' {
            $PD.Rule = Get-AppSecPolicyRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams
            $PD.Rule.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyRule' {
        It 'updates correctly' {
            $PD.SetRule = Set-AppSecPolicyRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID -Action 'deny' @CommonParams
            $PD.SetRule.action | Should -Be 'deny'
        }
    }

    Context 'Update-AppSecKRSRuleSet' {
        It 'sets correctly' {
            $PD.KRSRuleSet = Update-AppSecKRSRuleSet -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Mode $TestPolicyMode @CommonParams
            $PD.KRSRuleSet.mode | Should -Be $TestPolicyMode
        }
    }

    Context 'Get-AppSecPolicyAdaptiveIntelligence' {
        It 'returns the correct data' {
            $PD.AdaptiveIntel = Get-AppSecPolicyAdaptiveIntelligence -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.AdaptiveIntel.threatIntel | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyAdaptiveIntelligence' {
        It 'updates correctly' {
            $PD.SetAdaptiveIntel = Set-AppSecPolicyAdaptiveIntelligence -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Action on @CommonParams
            $PD.SetAdaptiveIntel.threatIntel | Should -Be 'on'
        }
    }

    Context 'Get-AppSecPolicyUpgradeDetails' {
        It 'returns the correct data' {
            $PD.UpgradeDetails = Get-AppSecPolicyUpgradeDetails -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.UpgradeDetails.current | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                WAF Evaluation                  
    #-------------------------------------------------

    Context 'Set-AppSecPolicyEvaluationMode' {
        It 'returns the correct data' {
            $PD.EvalMode = Set-AppSecPolicyEvaluationMode -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Eval START -Mode ASE_AUTO @CommonParams
            $PD.EvalMode.eval | Should -Be 'enabled'
        }
    }

    Context 'Get-AppSecPolicyEvaluationRule' {
        It 'returns a list' {
            $PD.EvalPolicyRules = Get-AppSecPolicyEvaluationRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.EvalPolicyRules.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecPolicyEvaluationRule by ID' {
        It 'returns the correct data' {
            $PD.EvalRule = Get-AppSecPolicyEvaluationRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams
            $PD.EvalRule.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationRule' {
        It 'updates correctly' {
            $PD.EvalSetRule = Set-AppSecPolicyEvaluationRule -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID -Action 'deny' @CommonParams
            $PD.EvalSetRule.action | Should -Be 'deny'
        }
    }

    Context 'Get-AppSecPolicyEvaluationAttackGroup' {
        It 'returns the correct data' {
            $PD.EvalAttackGroups = Get-AppSecPolicyEvaluationAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.EvalAttackGroups.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecPolicyEvaluationAttackGroup by ID' {
        It 'returns the correct data' {
            $PD.EvalAttackGroup = Get-AppSecPolicyEvaluationAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $PD.AttackGroups[0].group @CommonParams
            $PD.EvalAttackGroup.action | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationAttackGroup' {
        It 'sets correctly' {
            $PD.EvalSetAttackGroup = Set-AppSecPolicyEvaluationAttackGroup -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $PD.AttackGroups[0].group -Action "deny" @CommonParams
            $PD.EvalSetAttackGroup.action | Should -Be "deny"
        }
    }

    Context 'Set-AppSecPolicyEvaluationAttackGroupExceptions by pipeline' {
        It 'sets correctly' {
            $PD.EvalSetAttackGroupExceptionsByPipeline = ($TestException | Set-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID @CommonParams)
            $PD.EvalSetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationAttackGroupExceptions by body' {
        It 'sets correctly' {
            $PD.EvalSetAttackGroupExceptionsByBody = Set-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID -Body $TestExceptionBody @CommonParams
            $PD.EvalSetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyEvaluationAttackGroupExceptions' {
        It 'returns the correct data' {
            $PD.EvalAttackGroupExceptions = Get-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -AttackGroupID $TestAttackGroupID @CommonParams
            $PD.EvalAttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationRuleExceptions by pipeline' {
        It 'sets correctly' {
            $PD.EvalSetRuleExceptionsByPipeline = ($TestException | Set-AppSecPolicyEvaluationRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams)
            $PD.EvalSetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationRuleExceptions by body' {
        It 'sets correctly' {
            $PD.EvalSetRuleExceptionsByBody = Set-AppSecPolicyEvaluationRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID -Body $TestExceptionBody @CommonParams
            $PD.EvalSetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyEvaluationRuleExceptions' {
        It 'returns the correct data' {
            $PD.EvalRuleExceptions = Get-AppSecPolicyEvaluationRuleExceptions -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -RuleID $TestRuleID @CommonParams
            $PD.EvalRuleExceptions.exception | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #               Penalty Box Evaluation           
    #-------------------------------------------------

    Context 'Get-AppSecPolicyEvaluationPenaltyBox' {
        It 'returns the correct data' {
            $PD.EvalPenaltyBox = Get-AppSecPolicyEvaluationPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.EvalPenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationPenaltyBox by pipeline' {
        It 'updates correctly' {
            $PD.EvalSetPenaltyBoxByPipeline = ($PD.PenaltyBox | Set-AppSecPolicyEvaluationPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.EvalSetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyEvaluationPenaltyBox by body' {
        It 'updates correctly' {
            $PD.EvalSetPenaltyBoxByBody = Set-AppSecPolicyEvaluationPenaltyBox -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PD.PenaltyBox) @CommonParams
            $PD.EvalSetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                     Export                     
    #-------------------------------------------------

    Context 'Export-AppSecConfiguration' {
        It 'exports correctly' {
            $PD.Export = Export-AppSecConfiguration -ConfigID $PD.NewConfig.configId -VersionNumber 1 @CommonParams
            $PD.Export.configId | Should -Be $PD.Newconfig.configId
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
    #                    Versions                    
    #-------------------------------------------------

    Context 'Get-AppSecConfigurationVersion' {
        It 'returns a list' {
            $PD.Versions = Get-AppSecConfigurationVersion -ConfigID $PD.NewConfig.configId @CommonParams
            $PD.Versions[0].configId | Should -Be $PD.NewConfig.ConfigId
        }
    }

    Context 'New-AppSecConfigurationVersion' {
        It 'creates a new version' {
            $PD.NewVersion = New-AppSecConfigurationVersion -ConfigID $PD.NewConfig.configId -CreateFromVersion 1 @CommonParams
            $PD.NewVersion.configId | Should -Be $PD.NewConfig.ConfigId
        }
    }

    Context 'Get-AppSecConfigurationVersion by ID' {
        It 'gets the right version' {
            $PD.GetVersion = Get-AppSecConfigurationVersion -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams
            $PD.GetVersion.version | Should -Be $PD.NewVersion.version
        }
    }

    Context 'Remove-AppSecConfigurationVersion' {
        It 'completes successfully' {
            $PD.RemoveVersion = Remove-AppSecConfigurationVersion -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams 
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
            $PD.NewURLProtectionPolicy = New-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -Body $TestURLProtectionPolicyJSON @CommonParams
            $PD.NewURLProtectionPolicy.configId | Should -Be $PD.NewConfig.configId
        }
    }
    
    Context 'Get-AppSecURLProtectionPolicy, all' {
        It 'returns the correct data' {
            $PD.GetURLProtectionPolicies = Get-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams
            $PD.GetURLProtectionPolicies[0].configId | Should -Be $PD.NewConfig.configId
        }
    }
    
    Context 'Get-AppSecURLProtectionPolicy, single' {
        It 'returns the correct data' {
            $PD.GetURLProtectionPolicy = Get-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -URLProtectionPolicyID $PD.NewURLProtectionPolicy.policyId @CommonParams
            $PD.GetURLProtectionPolicy.configId | Should -Be $PD.NewConfig.configId
        }
    }
    
    Context 'Set-AppSecURLProtectionPolicy by param' {
        It 'updates successfully' {
            $PD.SetURLProtectionPolicyByParam = Set-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -URLProtectionPolicyID $PD.NewURLProtectionPolicy.policyId -Body $PD.GetURLProtectionPolicy @CommonParams
            $PD.SetURLProtectionPolicyByParam.configId | Should -Be $PD.NewConfig.configId
        }
    }
    
    Context 'Set-AppSecURLProtectionPolicy by pipeline' {
        It 'updates successfully' {
            $PD.SetURLProtectionPolicyByPipeline = ($PD.GetURLProtectionPolicy | Set-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -URLProtectionPolicyID $PD.NewURLProtectionPolicy.policyId @CommonParams)
            $PD.SetURLProtectionPolicyByPipeline.configId | Should -Be $PD.NewConfig.configId
        }
    }

    Context 'Get-AppsecPolicyURLProtectionPolicy' {
        It 'returns the correct data' {
            $PD.GetPolicyURLProtectionPolicies = Get-AppsecPolicyURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.GetPolicyURLProtectionPolicies[0].policyId | Should -Be $PD.GetURLProtectionPolicy.policyId
        }
    }
    
    Context 'Set-AppsecPolicyURLProtectionPolicy' {
        It 'returns the correct data' {
            $PD.SetPolicyURLProtectionPolicy = Set-AppsecPolicyURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId -URLProtectionPolicyID $PD.GetURLProtectionPolicy.policyId -Action none @CommonParams
            $PD.SetPolicyURLProtectionPolicy.action | Should -Be 'none'
            $PD.SetPolicyURLProtectionPolicy.policyId | Should -Be $PD.GetURLProtectionPolicy.policyId
        }
    }

    #-------------------------------------------------
    #               Attack Payload Settings
    #-------------------------------------------------

    Context 'Get-AppSecAttackPayloadSettings' {
        It 'returns the correct data' {
            $PD.GetAttackPayloadSettings = Get-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams
            $PD.GetAttackPayloadSettings.enabled | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecAttackPayloadSettings by param' {
        It 'returns the correct data' {
            $PD.SetAttackPayloadSettingsByParam = Set-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -Body $PD.GetAttackPayloadSettings @CommonParams
            $PD.SetAttackPayloadSettingsByParam.enabled | Should -Be $PD.GetAttackPayloadSettings.enabled
        }
    }
    
    Context 'Set-AppSecAttackPayloadSettings by pipline' {
        It 'returns the correct data' {
            $PD.SetAttackPayloadSettingsByPipeline = ($PD.GetAttackPayloadSettings | Set-AppSecAttackPayloadSettings -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams)
            $PD.SetAttackPayloadSettingsByPipeline.enabled | Should -Be $PD.GetAttackPayloadSettings.enabled
        }
    }
    
    Context 'Get-AppSecPolicyAttackPayload' {
        It 'returns the correct data' {
            $PD.GetPolicyAttackPayload = Get-AppSecPolicyAttackPayload -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.GetPolicyAttackPayload.enabled | Should -Not -BeNullOrEmpty

            # Set enabled to false for later commands
            $PD.GetPolicyAttackPayload.enabled = $false
            $PD.GetPolicyAttackPayload.override = $true
        }
    }
    
    Context 'Set-AppSecPolicyAttackPayload by param' {
        It 'updates correctly' {
            $PD.SetPolicyAttackPayloadByParam = Set-AppSecPolicyAttackPayload -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId -Body $PD.GetPolicyAttackPayload @CommonParams
            $PD.SetPolicyAttackPayloadByParam.enabled | Should -Be $false
        }
    }
    
    Context 'Set-AppSecPolicyAttackPayload by pipeline' {
        It 'updates correctly' {
            $PD.SetPolicyAttackPayloadByPipeline = ($PD.GetPolicyAttackPayload | Set-AppSecPolicyAttackPayload -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId @CommonParams)
            $PD.SetPolicyAttackPayloadByPipeline.enabled | Should -Be $false
        }
    }

    #-------------------------------------------------
    #               Malware Policies
    #-------------------------------------------------

    Context 'New-AppSecMalwarePolicy' {
        It 'creates successfully' {
            $PD.NewMalwarePolicy = New-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -Body $TestMalwarePolicyJSON @CommonParams
            $PD.NewMalwarePolicy.name | Should -Be $TestMalwarePolicyName
        }
    }
    
    Context 'Get-AppSecMalwarePolicy, all' {
        It 'returns a list' {
            $PD.GetMalwarePolicies = Get-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version @CommonParams
            $PD.GetMalwarePolicies[0].name | Should -Be $TestMalwarePolicyName
        }
    }
    
    Context 'Get-AppSecMalwarePolicy, single' {
        It 'returns a list' {
            $PD.GetMalwarePolicy = Get-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -MalwarePolicyID $PD.NewMalwarePolicy.id @CommonParams
            $PD.GetMalwarePolicy.id | Should -Be $PD.NewMalwarePolicy.id
        }
    }

    Context 'Set-AppSecMalwarePolicy by param' {
        It 'updates correctly' {
            $PD.SetMalwarePolicyByParam = Set-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -MalwarePolicyID $PD.NewMalwarePolicy.id -Body $PD.GetMalwarePolicy @CommonParams
            $PD.SetMalwarePolicyByParam.id | Should -Be $PD.NewMalwarePolicy.id
        }
    }
    
    Context 'Set-AppSecMalwarePolicy by pipeline' {
        It 'updates correctly' {
            $PD.SetMalwarePolicyByPipeline = ($PD.GetMalwarePolicy | Set-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -MalwarePolicyID $PD.NewMalwarePolicy.id @CommonParams)
            $PD.SetMalwarePolicyByPipeline.id | Should -Be $PD.NewMalwarePolicy.id
        }
    }
    
    Context 'Set-AppSecPolicyMalwarePolicy' {
        It 'returns a list' {
            $PD.SetMalwarePolicyAction = Set-AppSecPolicyMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId -MalwarePolicyID $PD.NewMalwarePolicy.id -Action alert -UnscannedAction alert @CommonParams
            $PD.SetMalwarePolicyAction.action | Should -Be 'alert'
            $PD.SetMalwarePolicyAction.unscannedAction | Should -Be 'alert'
        }
    }

    Context 'Get-AppSecPolicyMalwarePolicy' {
        It 'returns the correct data' {
            $PD.GetMalwarePolicyActions = Get-AppSecPolicyMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.GetMalwarePolicyActions[0].id | Should -Be $PD.NewMalwarePolicy.id
        }
    }

    #-------------------------------------------------
    #               Policy API Endpoints                    
    #-------------------------------------------------

    Context 'Get-AppSecPolicyAPIEndpoints' {
        It 'returns the correct data' {
            $PD.PolicyAPIEndpoints = Get-AppSecPolicyAPIEndpoints -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId @CommonParams
            $PD.PolicyAPIEndpoints[0].id | Should -Be $TestAPIEndpointID
        }
    }
    
    
    #-------------------------------------------------
    #                    Removals                    
    #-------------------------------------------------

    Context 'Remove-AppSecMatchTarget' {
        It 'completes successfully' {
            Remove-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -TargetID $PD.NewAPIMatchTarget.targetId @CommonParams 
            Remove-AppSecMatchTarget -ConfigID $PD.NewConfig.configId -VersionNumber 1 -TargetID $PD.NewWebsiteMatchTarget.targetId @CommonParams 
        }
    }

    Context 'Remove-AppSecPolicy' {
        It 'completes successfully' {
            Remove-AppSecPolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -PolicyID $PD.NewPolicy.policyId @CommonParams 
        }
    }

    # Wait for the policy removal to really complete
    Start-Sleep -Seconds 5

    Context 'Remove-AppSecReputationProfile' {
        It 'completes successfully' {
            Remove-AppSecReputationProfile -ConfigID $PD.NewConfig.configId -VersionNumber 1 -ReputationProfileID $PD.NewReputationProfileByBody.id @CommonParams 
        }
    }

    Context 'Remove-AppSecCustomDenyAction' {
        It 'completes successfully' {
            Remove-AppSecCustomDenyAction -ConfigID $PD.NewConfig.configId -VersionNumber 1 -CustomDenyID $PD.NewCustomDenyAction.id @CommonParams 
        }
    }

    Context 'Remove-AppSecCustomRule' {
        It 'completes successfully' {
            Remove-AppSecCustomRule -ConfigID $PD.NewConfig.ConfigId -RuleID $PD.NewCustomRule.id @CommonParams 
        }
    }

    Context 'Remove-AppSecRatePolicy' {
        It 'completes successfully' {
            Remove-AppSecRatePolicy -ConfigID $PD.NewConfig.configId -VersionNumber 1 -RatePolicyID $PD.NewRatePolicyByBody.id @CommonParams 
        }
    }

    Context 'Remove-AppSecURLProtectionPolicy' {
        It 'completes successfully' {
            Remove-AppSecURLProtectionPolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -URLProtectionPolicyID $PD.GetURLProtectionPolicy.policyId @CommonParams 
        }
    }
    
    Context 'Remove-AppSecMalwarePolicy' {
        It 'completes successfully' {
            Set-AppSecPolicyMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -PolicyID $PD.NewPolicy.policyId -MalwarePolicyID $PD.NewMalwarePolicy.id -Action none -UnscannedAction none @CommonParams | Out-Null
            Remove-AppSecMalwarePolicy -ConfigID $PD.NewConfig.configId -VersionNumber $PD.NewVersion.version -MalwarePolicyID $PD.GetMalwarePolicy.id @CommonParams
        }
    }

    Context 'Remove-AppSecConfiguration' {
        It 'completes successfully' {
            Remove-AppSecConfiguration -ConfigID $PD.NewConfig.ConfigId @CommonParams 
        }
    } 
}

Describe 'Unsafe Akamai.AppSec Tests' {

    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.AppSec/Akamai.AppSec.psd1 -Force
        
        $TestHostnames = $env:PesterHostname
        $TestNewHostname = $env:PesterHostname2
        $TestPolicyHostnamesToAdd = @"
{
    "hostnameList": [
        {
            "hostname": "$TestNewHostname"
        }
    ]
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.AppSec"
        $PD = @{}
    }

    #-------------------------------------------------
    #                   Activations                  
    #-------------------------------------------------

    Context 'New-AppSecActivation' {
        It 'activates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activate = New-AppSecActivation -ConfigID 12345 -VersionNumber 1 -Network STAGING -NotificationEmails 'mail@example.com' -Note 'testing'
            $Activate.activationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecActivationHistory' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationHistory.json"
                return $Response | ConvertFrom-Json
            }
            $Activations = Get-AppSecActivationHistory -ConfigID 12345
            $Activations.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-AppSecActivationRequestStatus' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationRequestStatus.json"
                return $Response | ConvertFrom-Json
            }
            $ActivationRequest = Get-AppSecActivationRequestStatus -StatusID 'f81c92c5-b150-4c41-9b53-9cef7969150a'
            $ActivationRequest.statusId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecActivationStatus' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
            $ActivationStatus = Get-AppSecActivationStatus -ActivationID 1234
            $ActivationStatus.activationId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                  Subscriptions                 
    #-------------------------------------------------

    Context 'Get-AppSecSubscribers' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecSubscribers.json"
                return $Response | ConvertFrom-Json
            }
            $Subscribers = Get-AppSecSubscribers -ConfigID 12345 -Feature AAG_TUNING_REC
            $Subscribers.count | Should -BeGreaterThan 0
        }
    }

    Context 'New-AppSecSubscription' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-AppSecSubscription.json"
                return $Response | ConvertFrom-Json
            }
            New-AppSecSubscription -ConfigID 12345 -Feature AAG_TUNING_REC -Subscribers "email@example.com, email2@example.com" 
        }
    }

    Context 'Remove-AppSecSubscription' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecSubscription.json"
                return $Response | ConvertFrom-Json
            }
            Remove-AppSecSubscription -ConfigID 12345 -Feature AAG_TUNING_REC -Subscribers "email@example.com, email2@example.com" 
        }
    }

    #-------------------------------------------------
    #             Tuning Recommendations             
    #-------------------------------------------------
    
    Context 'Get-AppSecPolicyTuningRecommendations' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyTuningRecommendations.json"
                return $Response | ConvertFrom-Json
            }
            $Recommendations = Get-AppSecPolicyTuningRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456
            $Recommendations.ruleRecommendations | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyTuningRecommendations' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyTuningRecommendations.json"
                return $Response | ConvertFrom-Json
            }
            Set-AppSecPolicyTuningRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Action ACCEPT -SelectorID 84220 
        }
    }

    Context 'Get-AppSecPolicyAttackGroupRecommendations' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyAttackGroupRecommendations.json"
                return $Response | ConvertFrom-Json
            }
            $AttackGroupRecommendations = Get-AppSecPolicyAttackGroupRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -AttackGroupID CMD
            $AttackGroupRecommendations.group | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecPolicyRuleRecommendations' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyRuleRecommendations.json"
                return $Response | ConvertFrom-Json
            }
            $RuleRecommendations = Get-AppSecPolicyRuleRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -RuleID 12345
            $RuleRecommendations.id | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                 API Discovery             
    #-------------------------------------------------

    Context 'Get-AppSecDiscoveredAPI, all' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredAPI_1.json"
                return $Response | ConvertFrom-Json
            }
            $DiscoveredAPIs = Get-AppSecDiscoveredAPI
            $DiscoveredAPIs.basePath | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-AppSecDiscoveredAPI, single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
            $DiscoveredAPI = Get-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api
            $DiscoveredAPI.apiEndpointIds | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Hide-AppSecDiscoveredAPI' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Hide-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
            $HideDiscoveredAPI = Hide-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api -Reason NOT_ELIGIBLE
            $HideDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Show-AppSecDiscoveredAPI' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Show-AppSecDiscoveredAPI.json"
                return $Response | ConvertFrom-Json
            }
            $ShowDiscoveredAPI = Show-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api -Reason FALSE_POSITIVE
            $ShowDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-AppSecDiscoveredApiEndpoints' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecDiscoveredApiEndpoints.json"
                return $Response | ConvertFrom-Json
            }
            $DiscoveredAPIEndpoints = Get-AppSecDiscoveredApiEndpoints -Hostname www.example.com -BasePath /api
            $DiscoveredAPIEndpoints[0].apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Match Targets
    #-------------------------------------------------

    Context 'Get-AppSecHostnameMatchTargets' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecHostnameMatchTargets.json"
                return $Response | ConvertFrom-Json
            }
            $HostnameMatchTargets = Get-AppSecHostnameMatchTargets -ConfigID 12345 -VersionNumber 1 -Hostname www.example.com
            $HostnameMatchTargets.websiteTargets[0].configId | Should -Not -BeNullOrEmpty
        }
    }
 
    #-------------------------------------------------
    #                Hostname Coverage
    #  (moved to unsafe due to timeouts in test account)         
    #-------------------------------------------------

    Context 'Get-AppSecHostnameCoverage' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecHostnameCoverage.json"
                return $Response | ConvertFrom-Json
            }
            $Coverage = Get-AppSecHostnameCoverage
            $Coverage.count | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #                Bypass Network Lists
    #-------------------------------------------------

    Context 'Get-AppSecBypassNetworkLists' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $PD.BypassNL = Get-AppSecBypassNetworkLists -ConfigID 12345 -VersionNumber 1
            $PD.BypassNL[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecBypassNetworkLists' {
        It 'updates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $SetBypassNL = Set-AppSecBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -NetworkLists 123_EXAMPLE
            $SetBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
        }
    }

    Context 'Get-AppSecPolicyBypassNetworkLists' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetPolicyBypassNL = Get-AppSecPolicyBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456
            $PD.GetPolicyBypassNL[0].id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-AppSecPolicyBypassNetworkLists' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyBypassNetworkLists.json"
                return $Response | ConvertFrom-Json
            }
            $SetPolicyBypassNL = ($PD.GetPolicyBypassNL.id | Set-AppSecPolicyBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456)
            $SetPolicyBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
        }
    }

    #-------------------------------------------------
    #                Policy Selected Hostnames
    #-------------------------------------------------

    Context 'Get-AppSecPolicySelectedHostnames' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PolicySelectedHostnames = Get-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456
            $PolicySelectedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-AppSecPolicySelectedHostnames' {
        It 'adds a hostname successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Add-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PD.PolicyAddedHostnames = Add-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $TestPolicyHostnamesToAdd
            $PD.PolicyAddedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecPolicySelectedHostnames' {
        It 'adds a hostname successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PolicyUpdatedHostnames = Set-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PD.PolicyAddedHostnames
            $PolicyUpdatedHostnames.hostnameList.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-AppSecPolicySelectedHostnames' {
        It 'removes the correct hostname' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-AppSecPolicySelectedHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PolicyRemovedHostnames = Remove-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $TestPolicyHostnamesToAdd
            $PolicyRemovedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
        }
    }

    #-------------------------------------------------
    #              Evaluation Hostnames
    #-------------------------------------------------
    
    Context 'Get-AppSecEvaluationHostnames' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetEvaluationHostnames = Get-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1
            $PD.GetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $SetEvaluationHostnames = Set-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -Body $PD.GetEvaluationHostnames
            $SetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Protect-AppSecEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Protect-AppSecEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $ProtectEvaluationHostnames = Protect-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -Body $PD.GetEvaluationHostnames
            $ProtectEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-AppSecPolicyEvaluationHostnames' {
        It 'gets a list' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetPolicyEvaluationHostnames = Get-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456
            $PD.GetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-AppSecPolicyEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $SetPolicyEvaluationHostnames = Set-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PD.GetPolicyEvaluationHostnames
            $SetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Protect-AppSecPolicyEvaluationHostnames' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.AppSec -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Protect-AppSecPolicyEvaluationHostnames.json"
                return $Response | ConvertFrom-Json
            }
            $ProtectPolicyEvaluationHostnames = Protect-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PD.GetPolicyEvaluationHostnames
            $ProtectPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
        }
    }
}


