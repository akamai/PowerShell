Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.AppSec/Akamai.AppSec.psd1 -Force
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
$Script:TestConfigName = "akamaipowershell"
$Script:TestConfigDescription = "Powershell pester testing. Will be deleted shortly."
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestHostnames = $env:PesterHostname
$Script:TestNewHostname = $env:PesterHostname2
$Script:TestAPIEndpointID = $env:PesterAPIEndpointID
$Script:TestCustomRule = '{"conditions":[{"type":"pathMatch","positiveMatch":true,"value":["/test"],"valueCase":false,"valueIgnoreSegment":false,"valueNormalize":false,"valueWildcard":true}],"name":"cr1","operation":"AND","ruleActivated":false,"structured":true,"tag":["tag1"],"version":1}'
$Script:TestNotes = "Akamai PowerShell Test"
$Script:TestPolicyName = 'Example'
$Script:TestPolicyPrefix = 'EX01'
$Script:TestPolicyMode = 'ASE_MANUAL'
$Script:TestAPIMatchTargetBody = @"
{"type":"api","apis":[{"id":$TestAPIEndpointID}],"securityPolicy":{"policyId":"REPLACE_POLICY_ID"}}
"@
$Script:TestAPIMatchTarget = ConvertFrom-Json $TestAPIMatchTargetBody
$Script:TestSiteMatchTargetBody = @"
{"type":"website","hostnames": [ "$TestHostnames" ], "filePaths": [ "/*" ], "securityPolicy": { "policyId": "REPLACE_POLICY_ID" }}
"@
$Script:TestSiteMatchTarget = ConvertFrom-Json $TestSiteMatchTargetBody
$Script:TestNetworkListID = $env:PesterNetworkListID
$Script:TestCustomDenyName = 'SampleCustomDeny'
$Script:TestCustomDenyBody = @"
{"name":"$TestCustomDenyName","description": "Old Description","parameters":[{"displayName":"Hostname","name":"custom_deny_hostname","value":"deny.$TestHostnames"},{"displayName":"Path","name":"custom_deny_path","value":"/"},{"displayName":"IncludeAkamaiReferenceID","name":"include_reference_id","value":"true"},{"displayName":"IncludeTrueClientIP","name":"include_true_ip","value":"false"},{"displayName":"Preventbrowsercaching","name":"prevent_browser_cache","value":"true"},{"displayName":"Responsecontenttype","name":"response_content_type","value":"application/json"},{"displayName":"Responsestatuscode","name":"response_status_code","value":"403"}]}
"@
$Script:TestRatePolicy1Name = 'Rate Policy 1'
$Script:TestRatePolicy2Name = 'Rate Policy 2'
$Script:TestRatePolicyBody = @"
{"averageThreshold":10,"burstThreshold":50,"clientIdentifier":"ip","matchType":"path","name":"$TestRatePolicy1Name","path":{"positiveMatch":true,"values":["/*"]},"pathMatchType":"Custom","pathUriPositiveMatch":true,"requestType":"ClientRequest","sameActionOnIpv6":false,"type":"WAF","useXForwardForHeaders":false}
"@
$Script:TestRatePolicy = ConvertFrom-Json $TestRatePolicyBody
$TestRatePolicy.name = $TestRatePolicy2Name
$Script:TestSiemSettingsBody = '{"enableSiem":true,"enableForAllPolicies":true, "siemDefinitionId": 1}'
$Script:TestSiemSettings = ConvertFrom-Json $TestSiemSettingsBody
$Script:TestReputationProfile1Name = "AkamaiPowerShell Reputation Profile 1"
$Script:TestReputationProfile2Name = "AkamaiPowerShell Reputation Profile 2"
$Script:TestReputationProfileBody = '{"context":"DOSATCK","contextReadable":"DoSAttackers","enabled":true,"name":"PlaceHolder","sharedIpHandling":"BOTH","threshold":7}'.replace('PlaceHolder', $TestReputationProfile1Name)
$Script:TestReputationProfile = ConvertFrom-Json $TestReputationProfileBody
$TestReputationProfile.name = $TestReputationProfile2Name
$Script:TestPragmaSettingsBody = '{"action":"REMOVE","conditionOperator":"AND"}'
$Script:TestPragmaSettings = ConvertFrom-Json $TestPragmaSettingsBody
$Script:TestExceptionBody = '{"exception":{"specificHeaderCookieParamXmlOrJsonNames":[{"names":["ExceptMe"],"selector":"REQUEST_HEADERS","wildcard":true}]}}'
$Script:TestException = ConvertFrom-Json $TestExceptionBody
$Script:TestRuleID = 950002
$Script:TestAttackGroupID = 'CMD'
$Script:TestURLProtectionPolicyJSON = @"
{"hostnamePaths":[{"hostname":"$TestHostnames","paths":["/login"]}],"intelligentLoadShedding":false,"name":"Powershell test policy","rateThreshold":195}
"@
$Script:TestMalwarePolicyName = 'Powershell testing'
$Script:TestMalwarePolicyJSON = @"
{ "name": "$TestMalwarePolicyName", "hostnames": [], "paths": ["/*"] }
"@

Describe 'Safe AppSec Tests' {
    BeforeDiscovery {
    }

    #-------------------------------------------------
    #                 Configuration                  
    #-------------------------------------------------

    ### New-AppSecConfiguration
    $Script:NewConfig = New-AppSecConfiguration -Name $TestConfigName -Description $TestConfigDescription -GroupID $TestGroupID -ContractId $TestContract -Hostnames $TestHostnames @SafeCommonParams
    it 'New-AppSecConfiguration creates successfully' {
        $NewConfig.name | Should -Be $TestConfigName
    }

    ### Get-AppSecConfiguration
    $Script:Configs = Get-AppSecConfiguration @SafeCommonParams
    it 'Get-AppSecConfiguration gets a list of configs' {
        $Configs | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecConfiguration by Name
    $Script:Config = Get-AppSecConfiguration -ConfigName $TestConfigName @SafeCommonParams
    it 'Get-AppSecConfiguration by Name finds the config' {
        $Config | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecConfiguration by ID
    $Script:Config = Get-AppSecConfiguration -ConfigID $NewConfig.configId @SafeCommonParams
    it 'Get-AppSecConfiguration by ID finds the config' {
        $Config | Should -Not -BeNullOrEmpty
    }

    ### Rename-AppSecConfiguration
    $Script:RenameResult = Rename-AppSecConfiguration -ConfigID $NewConfig.configId -NewName $TestConfigName -Description $TestConfigDescription @SafeCommonParams
    it 'Rename-AppSecConfiguration successfully renames' {
        $RenameResult.Name | Should -Be $TestConfigName
    }

    #-------------------------------------------------
    #                  Custom Rules                  
    #-------------------------------------------------

    ### New-AppSecCustomRule
    $Script:NewCustomRule = New-AppSecCustomRule -ConfigID $NewConfig.configId -Body $TestCustomRule @SafeCommonParams
    it 'New-AppSecCustomRule creates successfully' {
        $NewCustomRule.id | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecCustomRule
    $Script:CustomRules = Get-AppSecCustomRule -ConfigID $NewConfig.configId @SafeCommonParams
    it 'Get-AppSecCustomRule returns something' {
        $CustomRules | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecCustomRule by ID
    $Script:CustomRule = Get-AppSecCustomRule -ConfigID $NewConfig.configId -RuleID $NewCustomRule.id @SafeCommonParams
    it 'Get-AppSecCustomRule by ID returns newly created rule' {
        $CustomRule.id | Should -Be $NewCustomRule.id
    }

    ### Set-AppSecCustomRule by pipeline
    it 'Set-AppSecCustomRule completes successfully' {
        { $Script:SetCustomRule = $NewCustomRule | Set-AppSecCustomRule -ConfigID $NewConfig.configId -RuleID $NewCustomRule.id @SafeCommonParams } | Should -Not -Throw
    }

    ### Set-AppSecCustomRule by body
    it 'Set-AppSecCustomRule completes successfully' {
        { $Script:SetCustomRule = Set-AppSecCustomRule -ConfigID $NewConfig.configId -RuleID $NewCustomRule.id -Body $TestCustomRule @SafeCommonParams } | Should -Not -Throw
    }

    #-------------------------------------------------
    #               Failover Hostnames               
    #-------------------------------------------------

    ### Get-AppSecFailoverHostnames
    it 'Get-AppSecFailoverHostnames does not throw' {
        { $Script:FailoverHostnames = Get-AppSecFailoverHostnames -ConfigID $NewConfig.configId @SafeCommonParams } | Should -Not -Throw
    }

    #-------------------------------------------------
    #               Version Notes                    
    #-------------------------------------------------

    ### Set-AppSecVersionNotes
    $Script:SetNotes = Set-AppSecVersionNotes -ConfigID $NewConfig.configId -VersionNumber 1 -Notes $TestNotes @SafeCommonParams
    it 'Set-AppSecVersionNotes sets notes correctly' {
        $SetNotes | Should -Be $TestNotes
    }

    ### Get-AppSecVersionNotes
    $Script:GetNotes = Get-AppSecVersionNotes -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecVersionNotes gets notes correctly' {
        $GetNotes | Should -Be $TestNotes
    }

    #-------------------------------------------------
    #                    Hostnames                   
    #-------------------------------------------------

    ### Get-AppSecSelectableHostname
    $Script:SelectableHostnames = Get-AppSecSelectableHostnames -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecSelectableHostname gets a list' {
        $SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecSelectedHostnames
    $Script:SelectedHostnames = Get-AppSecSelectedHostnames -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecSelectedHostname gets a list' {
        $SelectedHostnames.hostnameList.hostname | Should -Be $TestHostnames
    }

    ### Set-AppSecSelectedHostnames
    $HostnamesToAdd = @"
    {
        "hostnameList": [
            {
                "hostname": "$TestNewHostname"
            }
        ]
    }
"@
    $Script:AddedHostnames = Add-AppSecSelectedHostnames -ConfigID $NewConfig.configId -VersionNumber 1 -Body $HostnamesToAdd @SafeCommonParams
    it 'Set-AppSecSelectedHostnames adds a hostname successfully' {
        $AddedHostnames.hostnameList.hostname | Should -Contain $TestNewHostname
    }
    
    ### Set-AppSecSelectedHostnames
    $Script:UpdatedHostnames = Set-AppSecSelectedHostnames -ConfigID $NewConfig.configId -VersionNumber 1 -Body $AddedHostnames @SafeCommonParams
    it 'Set-AppSecSelectedHostnames adds a hostname successfully' {
        $UpdatedHostnames.hostnameList.count | Should -Be 2
    }

    ### Remove-AppSecSelectedHostnames
    $Script:RemovedHostnames = Remove-AppSecSelectedHostnames -ConfigID $NewConfig.configId -VersionNumber 1 -Body $HostnamesToAdd @SafeCommonParams
    it 'Remove-AppSecSelectedHostnames removes the correct hostname' {
        $RemovedHostnames.hostnameList.hostname | Should -Not -Contain $TestNewHostname
    }

    ### Get-AppSecAvailableHostname
    $Script:SelectableHostnames = Get-AppSecAvailableHostnames -ContractID $TestContract -GroupID $TestGroupID @SafeCommonParams
    it 'Get-AppSecAvailableHostname gets a list' {
        $SelectableHostnames[0].hostname | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                    Policies                    
    #-------------------------------------------------

    ### New-AppSecPolicy
    $Script:NewPolicy = New-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyName $TestPolicyName -PolicyPrefix $TestPolicyPrefix @SafeCommonParams
    it 'New-AppSecPolicy creates correctly' {
        $NewPolicy.policyName | Should -Be $TestPolicyName
    }

    ### Get-AppSecPolicy
    $Script:Policies = Get-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecPolicy returns a list' {
        $Policies[0].policyId | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicy by ID and version
    $Script:PolicyByID = Get-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId  @SafeCommonParams
    it 'Get-AppSecPolicy by ID returns the correct policy' {
        $PolicyByID.policyId | Should -Be $NewPolicy.policyId
    }

    ### Get-AppSecPolicy by name and latest
    $Script:PolicyByName = Get-AppSecPolicy -ConfigName $TestConfigName -VersionNumber latest -PolicyID $NewPolicy.policyId  @SafeCommonParams
    it 'Get-AppSecPolicy by name returns the correct policy' {
        $PolicyByName.policyId | Should -Be $NewPolicy.policyId
    }

    ### Set-AppSecPolicy to new name
    $Script:RenamePolicy = Set-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -NewName "Temp" @SafeCommonParams
    it 'Set-AppSecPolicy updates correctly' {
        $RenamePolicy.policyName | Should -Be "Temp"
    }

    ### Set-AppSecPolicy back to old name in case we need it later
    $Script:SetPolicy = Set-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -NewName $TestPolicyName @SafeCommonParams
    it 'Set-AppSecPolicy updates correctly' {
        $SetPolicy.policyName | Should -Be $TestPolicyName
    }

    #-------------------------------------------------
    #                  Match Targets                 
    #-------------------------------------------------

    $TestAPIMatchTarget.securityPolicy.policyId = $NewPolicy.policyId
    $TestSiteMatchTarget.securityPolicy.policyId = $NewPolicy.policyId
    ### New-AppSecMatchTarget, API
    $Script:NewAPIMatchTarget = New-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestAPIMatchTarget @SafeCommonParams
    it 'New-AppSecMatchTarget for API creates correctly' {
        $NewAPIMatchTarget.configId | Should -Be $NewConfig.configId
    }
    
    ### New-AppSecMatchTarget, website
    $Script:NewWebsiteMatchTarget = New-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestSiteMatchTarget @SafeCommonParams
    it 'New-AppSecMatchTarget for Website creates correctly' {
        $NewWebsiteMatchTarget.configId | Should -Be $NewConfig.configId
    }

    ### Get-AppSecMatchTarget
    $Script:MatchTargets = Get-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecMatchTarget returns a list' {
        $MatchTargets.apiTargets | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecMatchTarget by ID
    $Script:MatchTarget = Get-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -TargetID $NewAPIMatchTarget.targetId @SafeCommonParams
    it 'Get-AppSecMatchTarget by ID returns the correct target' {
        $MatchTarget | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecMatchTarget by pipeline
    $Script:SetMatchTargetByPipeline = ( $NewAPIMatchTarget | Set-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -TargetID $NewAPIMatchTarget.targetId @SafeCommonParams )
    it 'Set-AppSecMatchTarget by pipeline updates successfully' {
        $SetMatchTargetByPipeline.targetId | Should -Be $NewAPIMatchTarget.targetId
    }

    ### Set-AppSecMatchTarget by param
    $Script:SetMatchTargetByParam = Set-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -TargetID $NewAPIMatchTarget.targetId -Body $NewAPIMatchTarget @SafeCommonParams
    it 'Set-AppSecMatchTarget by param updates successfully' {
        $SetMatchTargetByParam.targetId | Should -Be $NewAPIMatchTarget.targetId
    }


    #-------------------------------------------------
    #                IP/Geo Firewall                 
    #-------------------------------------------------

    ### Get-AppSecPolicyIPGeoFirewall
    $Script:IPGeo = Get-AppSecPolicyIPGeoFirewall -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyIPGeoFirewall returns the correct data' {
        $IPGeo.block | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyIPGeoFirewall by pipeline
    $Script:SetIPGeoByPipeline = ($IPGeo | Set-AppSecPolicyIPGeoFirewall -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyIPGeoFirewall by pipeline returns the correct data' {
        $SetIPGeoByPipeline.block | Should -Be $IPGeo.block
    }

    ### Set-AppSecPolicyIPGeoFirewall by param
    $Script:SetIPGeoByParam = Set-AppSecPolicyIPGeoFirewall -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body $IPGeo @SafeCommonParams
    it 'Set-AppSecPolicyIPGeoFirewall by param returns the correct data' {
        $SetIPGeoByParam.block | Should -Be $IPGeo.block
    }

    #-------------------------------------------------
    #                  Rate Policies                 
    #-------------------------------------------------

    ### New-AppSecRatePolicy by body
    $Script:NewRatePolicyByBody = New-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestRatePolicyBody @SafeCommonParams
    it 'New-AppSecRatePolicy by body creates correctly' {
        $NewRatePolicyByBody.name | Should -Be $TestRatePolicy1Name
    }

    ### New-AppSecRatePolicy by pipeline
    $Script:NewRatePolicyByPipeline = $TestRatePolicy | New-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'New-AppSecRatePolicy by pipeline creates correctly' {
        $NewRatePolicyByPipeline.name | Should -Be $TestRatePolicy2Name
    }

    ### Get-AppSecRatePolicy
    $Script:RatePolicies = Get-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecRatePolicy returns a list' {
        $RatePolicies.count | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecRatePolicy by ID
    $Script:RatePolicy = Get-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -RatePolicyID $NewRatePolicyByBody.id @SafeCommonParams
    it 'Get-AppSecRatePolicy by ID returns the correct policy' {
        $RatePolicy.name | Should -Be $TestRatePolicy1Name
    }

    ### Set-AppSecRatePolicy by pipeline
    $Script:SetRatePolicyByPipeline = ($NewRatePolicyByBody | Set-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -RatePolicyID $NewRatePolicyByBody.id @SafeCommonParams)
    it 'Set-AppSecRatePolicy by pipeline returns the correct policy' {
        $SetRatePolicyByPipeline.name | Should -Be $TestRatePolicy1Name
    }

    ### Set-AppSecRatePolicy by param
    $Script:SetRatePolicyByParam = Set-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -RatePolicyID $NewRatePolicyByBody.id -Body $NewRatePolicyByBody @SafeCommonParams
    it 'Set-AppSecRatePolicy by param returns the correct policy' {
        $SetRatePolicyByParam.name | Should -Be $TestRatePolicy1Name
    }

    #-------------------------------------------------
    #                   Custom Deny                  
    #-------------------------------------------------

    ### New-AppSecCustomDenyAction
    $Script:NewCustomDenyAction = New-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestCustomDenyBody @SafeCommonParams
    it 'New-AppSecCustomDenyAction creates correctly' {
        $NewCustomDenyAction.name | Should -Be $TestCustomDenyName
    }

    ### Get-AppSecCustomDenyAction
    $Script:CustomDenyActions = Get-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecCustomDenyAction lists correctly' {
        $CustomDenyActions[0].name | Should -Be $TestCustomDenyName
    }

    ### Get-AppSecCustomDenyAction by ID
    $Script:CustomDenyAction = Get-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 -CustomDenyID $NewCustomDenyAction.id @SafeCommonParams
    it 'Get-AppSecCustomDenyAction by ID returns the correct action' {
        $CustomDenyAction.name | Should -Be $TestCustomDenyName
    }

    ### Set-AppSecCustomDenyAction by pipeline
    $NewCustomDenyAction.description = "updated"
    $Script:SetCustomDenyActionByPipeline = ($NewCustomDenyAction | Set-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 -CustomDenyID $NewCustomDenyAction.id @SafeCommonParams)
    it 'Set-AppSecCustomDenyAction by pipeline updates correctly' {
        $SetCustomDenyActionByPipeline.description | Should -Be "updated"
    }

    ### Set-AppSecCustomDenyAction
    $NewCustomDenyAction.description = "updated"
    $Script:SetCustomDenyActionByParam = Set-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 -CustomDenyID $NewCustomDenyAction.id -Body $NewCustomDenyAction @SafeCommonParams
    it 'Set-AppSecCustomDenyAction by param updates correctly' {
        $SetCustomDenyActionByParam.description | Should -Be "updated"
    }

    #-------------------------------------------------
    #                       SIEM                     
    #-------------------------------------------------

    
    ### Set-AppSecSiemSettings by body
    $Script:SetSIEMSettings = Set-AppSecSiemSettings -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestSiemSettingsBody @SafeCommonParams
    it 'Set-AppSecSiemSettings by body updates correctly' {
        $SetSIEMSettings.enableForAllPolicies | Should -Be $true
    }

    ### Set-AppSecSiemSettings by pipeline
    $Script:SetSIEMSettings = ($TestSiemSettings | Set-AppSecSiemSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecSiemSettings by pipeline updates correctly' {
        $SetSIEMSettings.enableForAllPolicies | Should -Be $true
    }

    ### Get-AppSecSiemSettings by pipeline
    $Script:SIEMSettings = Get-AppSecSiemSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecSiemSettings gets the right settings' {
        $SIEMSettings.enableForAllPolicies | Should -Be $true
    }

    #-------------------------------------------------
    #               Reputation Profiles              
    #-------------------------------------------------

    ### New-AppSecReputationProfile by body
    $Script:NewReputationProfileByBody = New-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestReputationProfileBody @SafeCommonParams
    it 'New-AppSecReputationProfile by body creates correctly' {
        $NewReputationProfileByBody.name | Should -Be $TestReputationProfile1Name
    }

    ### New-AppSecReputationProfile by pipeline
    $Script:NewReputationProfileByPipeline = ($TestReputationProfile | New-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'New-AppSecReputationProfile by pipeline creates correctly' {
        $NewReputationProfileByPipeline.name | Should -Be $TestReputationProfile2Name
    }

    ### Get-AppSecReputationProfile
    $Script:ReputationProfiles = Get-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecReputationProfile returns a list' {
        $ReputationProfiles.count | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecReputationProfile by ID
    $Script:ReputationProfile = Get-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -ReputationProfileID $NewReputationProfileByBody.id @SafeCommonParams
    it 'Get-AppSecReputationProfile by ID returns the correct profile' {
        $ReputationProfile.id | Should -Be $NewReputationProfileByBody.id
    }

    ### Set-AppSecReputationProfile by pipeline
    $Script:SetReputationProfileByPipeline = ($NewReputationProfileByBody | Set-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -ReputationProfileID $NewReputationProfileByBody.id @SafeCommonParams)
    it 'Set-AppSecReputationProfile by pipeline updates the correct profile' {
        $SetReputationProfileByPipeline.id | Should -Be $NewReputationProfileByBody.id
    }

    ### Set-AppSecReputationProfile by param
    $Script:SetReputationProfileByParam = Set-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -ReputationProfileID $NewReputationProfileByBody.id -Body $NewReputationProfileByBody @SafeCommonParams
    it 'Set-AppSecReputationProfile by param updates the correct profile' {
        $SetReputationProfileByParam.id | Should -Be $NewReputationProfileByBody.id
    }

    #-------------------------------------------------
    #                    Advanced                    
    #-------------------------------------------------

    ### Get-AppSecEvasivePathMatch
    $Script:EvasivePathMatch = Get-AppSecEvasivePathMatch -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecEvasivePathMatch returns the correct data' {
        $EvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecEvasivePathMatch
    $Script:SetEvasivePathMatch = Set-AppSecEvasivePathMatch -ConfigID $NewConfig.configId -VersionNumber 1 -EnablePathMatch $true @SafeCommonParams
    it 'Get-AppSecEvasivePathMatch updates correctly' {
        $SetEvasivePathMatch.enablePathMatch | Should -Be $true
    }

    ### Get-AppSecLogging
    $Script:Logging = Get-AppSecLogging -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecLogging returns the correct data' {
        $Logging.allowSampling | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecLogging by pipeline
    $Script:SetLoggingByPipeline = ($Logging | Set-AppSecLogging -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecLogging updates correctly' {
        $SetLoggingByPipeline.allowSampling | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecLogging by body
    $Script:SetLoggingByBody = Set-AppSecLogging -ConfigID $NewConfig.configId -VersionNumber 1 -Body (ConvertTo-Json -Depth 10 $Logging) @SafeCommonParams
    it 'Set-AppSecLogging updates correctly' {
        $SetLoggingByBody.allowSampling | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPragmaSettings by body
    $Script:SetPragmaSettingsByBody = Set-AppSecPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 -Body $TestPragmaSettingsBody @SafeCommonParams
    it 'Set-AppSecPragmaSettings by body returns the correct data' {
        $SetPragmaSettingsByBody.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPragmaSettings by pipeline
    $Script:SetPragmaSettingsByPipeline = ($TestPragmaSettings | Set-AppSecPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecPragmaSettings by pipeline returns the correct data' {
        $SetPragmaSettingsByPipeline.action | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPragmaSettings
    $Script:PragmaSettings = Get-AppSecPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecPragmaSettings returns the correct data' {
        $PragmaSettings.action | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPrefetch
    $Script:Prefetch = Get-AppSecPrefetch -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecPrefetch returns the correct data' {
        $Prefetch.enableAppLayer | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPrefetch by pipeline
    $Script:SetPrefetchByPipeline = ($Prefetch | Set-AppSecPrefetch -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecPrefetch by pipeline updates correctly' {
        $SetPrefetchByPipeline.enableAppLayer | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPrefetch by body
    $Script:SetPrefetchByBody = Set-AppSecPrefetch -ConfigID $NewConfig.configId -VersionNumber 1 -Body (ConvertTo-Json -Depth 10 $Prefetch) @SafeCommonParams
    it 'Set-AppSecPrefetch by body updates correctly' {
        $SetPrefetchByBody.enableAppLayer | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecRequestSizeLimit
    $Script:RequestSizeLimit = Get-AppSecRequestSizeLimit -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecRequestSizeLimit returns the correct data' {
        $RequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecRequestSizeLimit
    $Script:SetRequestSizeLimit = Set-AppSecRequestSizeLimit -ConfigID $NewConfig.configId -VersionNumber 1 -RequestSizeLimit 32 @SafeCommonParams
    it 'Set-AppSecRequestSizeLimit updates correctly' {
        $SetRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 32
    }
    
    ### Get-AppSecAttackPayloadSettings
    $Script:AttackPayloadSettings = Get-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecAttackPayloadSettings returns the correct data' {
        $AttackPayloadSettings.requestBody | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecAttackPayloadSettings by Body
    $Script:SetAttackPayloadSettingsByBody = Set-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber 1 -Body $AttackPayloadSettings @SafeCommonParams
    it 'Set-AppSecAttackPayloadSettings by body updates correctly' {
        $SetAttackPayloadSettingsByBody.requestBody | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecAttackPayloadSettings by Pipeline
    $Script:SetAttackPayloadSettingsByPipeline = ($AttackPayloadSettings | Set-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecAttackPayloadSettings by pipeline updates correctly' {
        $SetAttackPayloadSettingsByPipeline.requestBody | Should -Not -BeNullOrEmpty
    }
   
    ### Get-AppSecPIISettings
    $Script:PIISettings = Get-AppSecPIISettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Get-AppSecPIISettings returns the correct data' {
        $PIISettings.enablePiiLearning | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPIISettings by param
    $Script:SetPIISettingsByParam = Set-AppSecPIISettings -ConfigID $NewConfig.configId -VersionNumber 1 -EnablePIILearning @SafeCommonParams
    it 'Set-AppSecPIISettings by param updates correctly' {
        $SetPIISettingsByParam.enablePiiLearning | Should -Be $true
    }
    
    ### Set-AppSecPIISettings by pipeline
    $Script:SetPIISettingsByPipeline = ($PIISettings | Set-AppSecPIISettings -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams)
    it 'Set-AppSecPIISettings by param updates correctly' {
        $SetPIISettingsByPipeline.enablePiiLearning | Should -Be $PIISettings.enablePiiLearning
    }

    #-------------------------------------------------
    #                   Protections                  
    #-------------------------------------------------

    ### Get-AppSecPolicyProtections
    $Script:Protections = Get-AppSecPolicyProtections -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyProtections returns the correct data' {
        $Protections.applyApiConstraints | Should -Not -BeNullOrEmpty
    }

    # Enable all protections
    $Script:Protections.PSObject.Properties.Name | ForEach-Object {
        $Script:Protections.$_ = $true
    }

    ### Set-AppSecPolicyProtections by pipeline
    $Script:SetProtectionsByPipeline = ($Protections | Set-AppSecPolicyProtections -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyProtections by pipeline updates correctly' {
        $SetProtectionsByPipeline.applyApiConstraints | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyProtections by body
    $Script:SetProtectionsByBody = Set-AppSecPolicyProtections -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $Protections) @SafeCommonParams
    it 'Set-AppSecPolicyProtections by body updates correctly' {
        $SetProtectionsByBody.applyApiConstraints | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                   Penalty Box                  
    #-------------------------------------------------

    ### Get-AppSecPolicyPenaltyBox
    $Script:PenaltyBox = Get-AppSecPolicyPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyPenaltyBox returns the correct data' {
        $PenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyPenaltyBox by pipeline
    $Script:SetPenaltyBoxByPipeline = ($PenaltyBox | Set-AppSecPolicyPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyPenaltyBox by pipeline updates correctly' {
        $SetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyPenaltyBox by body
    $Script:SetPenaltyBoxByBody = Set-AppSecPolicyPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PenaltyBox) @SafeCommonParams
    it 'Set-AppSecPolicyPenaltyBox by body updates correctly' {
        $SetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #               Rate Policy Actions              
    #-------------------------------------------------

    ### Set-AppSecPolicyRatePolicy
    $Script:SetRatePolicyAction = Set-AppSecPolicyRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RatePolicyID $NewRatePolicyByBody.id -IPv4Action alert -IPv6Action alert @SafeCommonParams
    it 'Set-AppSecPolicyRatePolicy updates correctly' {
        $SetRatePolicyAction.ipv4Action | Should -Be 'alert'
    }

    ### Get-AppSecPolicyRatePolicy
    $Script:RatePolicyActions = Get-AppSecPolicyRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyRatePolicy returns the correct data' {
        $RatePolicyActions[0].id | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #             API Request Constraints            
    #-------------------------------------------------

    ### Get-AppSecPolicyAPIRequestConstraints
    $Script:APIRequestConstraints = Get-AppSecPolicyAPIRequestConstraints -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyAPIRequestConstraints returns a list' {
        $APIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyAPIRequestConstraints without ID
    $Script:SetAPIRequestConstraints = Set-AppSecPolicyAPIRequestConstraints -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Action "alert" @SafeCommonParams
    it 'Set-AppSecPolicyAPIRequestConstraints returns a list of actions' {
        $SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyAPIRequestConstraints with ID
    $Script:SetAPIRequestConstraint = Set-AppSecPolicyAPIRequestConstraints -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -ApiID $TestAPIEndpointID -Action "alert" @SafeCommonParams
    it 'Set-AppSecPolicyAPIRequestConstraints returns the correct action' {
        $SetAPIRequestConstraints[0].action | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #               Reputation Analysis              
    #-------------------------------------------------

    ### Get-AppSecPolicyReputationAnalysis
    $Script:ReputationAnalysis = Get-AppSecPolicyReputationAnalysis -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyReputationAnalysis returns the correct data' {
        $ReputationAnalysis.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyReputationAnalysis by pipeline
    $Script:SetReputationAnalysisByPipeline = ($ReputationAnalysis | Set-AppSecPolicyReputationAnalysis -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyReputationAnalysis by pipeline updates correctly' {
        $SetReputationAnalysisByPipeline.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyReputationAnalysis by body
    $Script:SetReputationAnalysisByBody = Set-AppSecPolicyReputationAnalysis -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $ReputationAnalysis) @SafeCommonParams
    it 'Set-AppSecPolicyReputationAnalysis by body updates correctly' {
        $SetReputationAnalysisByBody.forwardToHTTPHeader | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #            Reputation Profile Actions          
    #-------------------------------------------------

    ### Get-AppSecPolicyReputationProfile
    $Script:ReputationProfileActions = Get-AppSecPolicyReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyReputationProfile returns a list' {
        $ReputationProfileActions.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecPolicyReputationProfile by ID
    $Script:ReputationProfileAction = Get-AppSecPolicyReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -ReputationProfileID $ReputationProfileActions[0].id @SafeCommonParams
    it 'Get-AppSecPolicyReputationProfile by ID returns a list' {
        $ReputationProfileAction.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyReputationProfile
    $Script:SetReputationProfileAction = Set-AppSecPolicyReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -ReputationProfileID $ReputationProfileActions[0].id -Action "deny" @SafeCommonParams
    it 'Get-AppSecPolicyReputationProfile updates correctly' {
        $SetReputationProfileAction.action | Should -Be "deny"
    }

    #-------------------------------------------------
    #                    Slow POST                   
    #-------------------------------------------------

    ### Get-AppSecPolicySlowPost
    $Script:SlowPost = Get-AppSecPolicySlowPost -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicySlowPost returns the correct data' {
        $ReputationProfileActions.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicySlowPost by pipeline
    $Script:SetSlowPostByPipeline = ($SlowPost | Set-AppSecPolicySlowPost -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicySlowPost by pipeline completes successfully' {
        $SetSlowPostByPipeline.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicySlowPost by body
    $Script:SetSlowPostByBody = Set-AppSecPolicySlowPost -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -depth 10 $SlowPost) @SafeCommonParams
    it 'Set-AppSecPolicySlowPost by body completes successfully' {
        $SetSlowPostByBody.action | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #               Custom Rule Actions              
    #-------------------------------------------------

    ### Get-AppSecPolicyCustomRules
    $Script:CustomRuleActions = Get-AppSecPolicyCustomRules -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyCustomRules returns a list' {
        $CustomRuleActions[0].action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyCustomRule
    $Script:SetCustomRuleAction = Set-AppSecPolicyCustomRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $NewCustomRule.id -Action 'deny' @SafeCommonParams
    it 'Set-AppSecPolicyCustomRule updates successfully' {
        $SetCustomRuleAction.action | Should -Be 'deny'
    }

    ### Set-AppSecPolicyCustomRule (undo so we can delete later)
    $Script:UnsetCustomRuleAction = Set-AppSecPolicyCustomRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $NewCustomRule.id -Action 'none' @SafeCommonParams
    it 'Set-AppSecPolicyCustomRule updates successfully' {
        $UnsetCustomRuleAction.action | Should -Be 'none'
    }

    #-------------------------------------------------
    #             Policy Advanced Settings           
    #-------------------------------------------------

    ### Get-AppSecPolicyEvasivePathMatch
    $Script:PolicyEvasivePathMatch = Get-AppSecPolicyEvasivePathMatch -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyEvasivePathMatch returns the correct data' {
        $PolicyEvasivePathMatch.enablePathMatch | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvasivePathMatch
    $Script:PolicyEvasivePathMatch = Set-AppSecPolicyEvasivePathMatch -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -EnablePathMatch $true @SafeCommonParams
    it 'Set-AppSecPolicyEvasivePathMatch updates correctly' {
        $PolicyEvasivePathMatch.enablePathMatch | Should -Be $true
    }

    ### Get-AppSecPolicyLogging
    $Script:PolicyLogging = Get-AppSecPolicyLogging -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyLogging returns the correct data' {
        $PolicyLogging.override | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecPolicyLogging by pipeline
    $Script:SetPolicyLoggingByPipeline = ($PolicyLogging | Set-AppSecPolicyLogging -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyLogging by pipeline updates correctly' {
        $SetPolicyLoggingByPipeline.override | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyLogging by body
    $Script:SetPolicyLoggingByBody = Set-AppSecPolicyLogging -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -depth 10 $PolicyLogging) @SafeCommonParams
    it 'Set-AppSecPolicyLogging by body updates correctly' {
        $SetPolicyLoggingByBody.override | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyPragmaSettings
    $Script:PolicyPragma = Get-AppSecPolicyPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyPragmaSettings returns the correct data' {
        $PolicyPragma.override | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyPragmaSettings by pipeline
    $Script:SetPolicyPragmaByPipeline = ($TestPragmaSettings | Set-AppSecPolicyPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyPragmaSettings by pipeline returns the correct data' {
        $SetPolicyPragmaByPipeline.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyPragmaSettings by body
    $Script:SetPolicyPragmaByBody = Set-AppSecPolicyPragmaSettings -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body $TestPragmaSettingsBody @SafeCommonParams
    it 'Set-AppSecPolicyPragmaSettings by body returns the correct data' {
        $SetPolicyPragmaByBody.action | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyRequestSizeLimit
    $Script:PolicyRequestSizeLimit = Get-AppSecPolicyRequestSizeLimit -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyRequestSizeLimit returns the correct data' {
        $PolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyRequestSizeLimit
    $Script:SetPolicyRequestSizeLimit = Set-AppSecPolicyRequestSizeLimit -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RequestSizeLimit 32 @SafeCommonParams
    it 'Set-AppSecPolicyRequestSizeLimit updates correctly' {
        $SetPolicyRequestSizeLimit.requestBodyInspectionLimitInKB | Should -Be 32
    }

    #-------------------------------------------------
    #                      WAF                       
    #-------------------------------------------------

    ### Get-AppSecPolicyAttackGroup
    $Script:AttackGroups = Get-AppSecPolicyAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyAttackGroup returns the correct data' {
        $AttackGroups.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecPolicyAttackGroup by ID
    $Script:AttackGroup = Get-AppSecPolicyAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $AttackGroups[0].group @SafeCommonParams
    it 'Get-AppSecPolicyAttackGroup by ID returns the correct data' {
        $AttackGroup.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyAttackGroup
    $Script:SetAttackGroup = Set-AppSecPolicyAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $AttackGroups[0].group -Action "deny" @SafeCommonParams
    it 'Set-AppSecPolicyAttackGroup sets correctly' {
        $SetAttackGroup.action | Should -Be "deny"
    }

    ### Set-AppSecPolicyAttackGroupExceptions by pipeline
    $Script:SetAttackGroupExceptionsByPipeline = ($TestException | Set-AppSecPolicyAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID @SafeCommonParams)
    it 'Set-AppSecPolicyAttackGroupExceptions by pipeline sets correctly' {
        $SetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyAttackGroupExceptions by body
    $Script:SetAttackGroupExceptionsByBody = Set-AppSecPolicyAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID -Body $TestExceptionBody @SafeCommonParams
    it 'Set-AppSecPolicyAttackGroupExceptions by body sets correctly' {
        $SetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyAttackGroupExceptions
    $Script:AttackGroupExceptions = Get-AppSecPolicyAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID @SafeCommonParams
    it 'Get-AppSecPolicyAttackGroupExceptions returns the correct data' {
        $AttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyRuleExceptions by pipeline
    $Script:SetRuleExceptionsByPipeline = ($TestException | Set-AppSecPolicyRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams)
    it 'Set-AppSecPolicyRuleExceptions by pipeline sets correctly' {
        $SetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyRuleExceptions by body
    $Script:SetRuleExceptionsByBody = Set-AppSecPolicyRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID -Body $TestExceptionBody @SafeCommonParams
    it 'Set-AppSecPolicyRuleExceptions by body sets correctly' {
        $SetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyRuleExceptions
    $Script:RuleExceptions = Get-AppSecPolicyRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams
    it 'Get-AppSecPolicyRuleExceptions returns the correct data' {
        $RuleExceptions.exception | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyMode
    $Script:PolicyMode = Get-AppSecPolicyMode -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyMode returns the correct data' {
        $PolicyMode.mode | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyMode
    $Script:SetPolicyMode = Set-AppSecPolicyMode -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Mode ASE_MANUAL @SafeCommonParams
    it 'Set-AppSecPolicyMode sets correctly' {
        $SetPolicyMode.mode | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyRule
    $Script:PolicyRules = Get-AppSecPolicyRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyRule returns a list' {
        $PolicyRules.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecPolicyRule by ID
    $Script:Rule = Get-AppSecPolicyRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams
    it 'Get-AppSecPolicyRule by ID returns the correct data' {
        $Rule.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyRule
    $Script:SetRule = Set-AppSecPolicyRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID -Action 'deny' @SafeCommonParams
    it 'Set-AppSecPolicyRule updates correctly' {
        $SetRule.action | Should -Be 'deny'
    }

    ### Update-AppSecKRSRuleSet
    $Script:KRSRuleSet = Update-AppSecKRSRuleSet -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Mode $TestPolicyMode @SafeCommonParams
    it 'Update-AppSecKRSRuleSet sets correctly' {
        $KRSRuleSet.mode | Should -Be $TestPolicyMode
    }

    ### Get-AppSecPolicyAdaptiveIntelligence
    $Script:AdaptiveIntel = Get-AppSecPolicyAdaptiveIntelligence -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyAdaptiveIntelligence returns the correct data' {
        $AdaptiveIntel.threatIntel | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyAdaptiveIntelligence
    $Script:SetAdaptiveIntel = Set-AppSecPolicyAdaptiveIntelligence -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Action on @SafeCommonParams
    it 'Set-AppSecPolicyAdaptiveIntelligence updates correctly' {
        $SetAdaptiveIntel.threatIntel | Should -Be 'on'
    }

    ### Get-AppSecPolicyUpgradeDetails
    $Script:UpgradeDetails = Get-AppSecPolicyUpgradeDetails -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyUpgradeDetails returns the correct data' {
        $UpgradeDetails.current | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                WAF Evaluation                  
    #-------------------------------------------------

    ### Set-AppSecPolicyEvaluationMode
    $Script:EvalMode = Set-AppSecPolicyEvaluationMode -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Eval START -Mode ASE_AUTO @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationMode returns the correct data' {
        $EvalMode.eval | Should -Be 'enabled'
    }

    ### Get-AppSecPolicyEvaluationRule
    $Script:EvalPolicyRules = Get-AppSecPolicyEvaluationRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationRule returns a list' {
        $EvalPolicyRules.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecPolicyEvaluationRule by ID
    $Script:EvalRule = Get-AppSecPolicyEvaluationRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationRule by ID returns the correct data' {
        $EvalRule.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationRule
    $Script:EvalSetRule = Set-AppSecPolicyEvaluationRule -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID -Action 'deny' @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationRule updates correctly' {
        $EvalSetRule.action | Should -Be 'deny'
    }

    ### Get-AppSecPolicyEvaluationAttackGroup
    $Script:EvalAttackGroups = Get-AppSecPolicyEvaluationAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationAttackGroup returns the correct data' {
        $EvalAttackGroups.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecPolicyEvaluationAttackGroup by ID
    $Script:EvalAttackGroup = Get-AppSecPolicyEvaluationAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $AttackGroups[0].group @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationAttackGroup by ID returns the correct data' {
        $EvalAttackGroup.action | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationAttackGroup
    $Script:EvalSetAttackGroup = Set-AppSecPolicyEvaluationAttackGroup -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $AttackGroups[0].group -Action "deny" @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationAttackGroup sets correctly' {
        $EvalSetAttackGroup.action | Should -Be "deny"
    }

    ### Set-AppSecPolicyEvaluationAttackGroupExceptions by pipeline
    $Script:EvalSetAttackGroupExceptionsByPipeline = ($TestException | Set-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID @SafeCommonParams)
    it 'Set-AppSecPolicyEvaluationAttackGroupExceptions by pipeline sets correctly' {
        $EvalSetAttackGroupExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationAttackGroupExceptions by body
    $Script:EvalSetAttackGroupExceptionsByBody = Set-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID -Body $TestExceptionBody @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationAttackGroupExceptions by body sets correctly' {
        $EvalSetAttackGroupExceptionsByBody.exception | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyEvaluationAttackGroupExceptions
    $Script:EvalAttackGroupExceptions = Get-AppSecPolicyEvaluationAttackGroupExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -AttackGroupID $TestAttackGroupID @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationAttackGroupExceptions returns the correct data' {
        $EvalAttackGroupExceptions.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationRuleExceptions by pipeline
    $Script:EvalSetRuleExceptionsByPipeline = ($TestException | Set-AppSecPolicyEvaluationRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams)
    it 'Set-AppSecPolicyEvaluationRuleExceptions by pipeline sets correctly' {
        $EvalSetRuleExceptionsByPipeline.exception | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationRuleExceptions by body
    $Script:EvalSetRuleExceptionsByBody = Set-AppSecPolicyEvaluationRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID -Body $TestExceptionBody @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationRuleExceptions by body sets correctly' {
        $EvalSetRuleExceptionsByBody.exception | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyEvaluationRuleExceptions
    $Script:EvalRuleExceptions = Get-AppSecPolicyEvaluationRuleExceptions -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -RuleID $TestRuleID @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationRuleExceptions returns the correct data' {
        $EvalRuleExceptions.exception | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #               Penalty Box Evaluation           
    #-------------------------------------------------

    ### Get-AppSecPolicyEvaluationPenaltyBox
    $Script:EvalPenaltyBox = Get-AppSecPolicyEvaluationPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyEvaluationPenaltyBox returns the correct data' {
        $EvalPenaltyBox.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationPenaltyBox by pipeline
    $Script:EvalSetPenaltyBoxByPipeline = ($PenaltyBox | Set-AppSecPolicyEvaluationPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyEvaluationPenaltyBox by pipeline updates correctly' {
        $EvalSetPenaltyBoxByPipeline.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyEvaluationPenaltyBox by body
    $Script:EvalSetPenaltyBoxByBody = Set-AppSecPolicyEvaluationPenaltyBox -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId -Body (ConvertTo-Json -Depth 10 $PenaltyBox) @SafeCommonParams
    it 'Set-AppSecPolicyEvaluationPenaltyBox by body updates correctly' {
        $EvalSetPenaltyBoxByBody.penaltyBoxProtection | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                     Export                     
    #-------------------------------------------------

    ### Export-AppSecConfiguration
    $Script:Export = Export-AppSecConfiguration -ConfigID $NewConfig.configId -VersionNumber 1 @SafeCommonParams
    it 'Export-AppSecConfiguration exports correctly' {
        $Export.configId | Should -Be $Newconfig.configId
    }
    
    #-------------------------------------------------
    #                  SIEM Versions                 
    #-------------------------------------------------

    ### Export-AppSecConfigurationVersionDetails
    $Script:SiemVersions = Get-AppSecSiemVersions @SafeCommonParams
    it 'Get-AppSecSiemVersions returns the correct data' {
        $SiemVersions[0].id | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                    Versions                    
    #-------------------------------------------------

    ### Get-AppSecConfigurationVersion
    $Script:Versions = Get-AppSecConfigurationVersion -ConfigID $NewConfig.configId @SafeCommonParams
    it 'Get-AppSecConfigurationVersion returns a list' {
        $Versions[0].configId | Should -Be $NewConfig.ConfigId
    }

    ### New-AppSecConfigurationVersion
    $Script:NewVersion = New-AppSecConfigurationVersion -ConfigID $NewConfig.configId -CreateFromVersion 1 @SafeCommonParams
    it 'New-AppSecConfigurationVersion creates a new version' {
        $NewVersion.configId | Should -Be $NewConfig.ConfigId
    }

    ### Get-AppSecConfigurationVersion by ID
    $Script:GetVersion = Get-AppSecConfigurationVersion -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams
    it 'Get-AppSecConfigurationVersion by ID gets the right version' {
        $GetVersion.version | Should -Be $NewVersion.version
    }

    ### Remove-AppSecConfigurationVersion
    it 'Remove-AppSecConfigurationVersion completes successfully' {
        { $Script:RemoveVersion = Remove-AppSecConfigurationVersion -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams } | Should -Not -Throw
    }

    #-------------------------------------------------
    #               ContractsAndGroups                    
    #-------------------------------------------------

    ### Get-AppSecContractsAndGroups
    $Script:Groups = Get-AppSecContractsAndGroups @SafeCommonParams
    it 'Get-AppSecContractsAndGroups returns a list' {
        $Groups[0].groupId | Should -Not -BeNullOrEmpty
    }
    
    #-------------------------------------------------
    #               URL Protection Policies
    #-------------------------------------------------

    ### New-AppSecURLProtectionPolicy
    $Script:NewURLProtectionPolicy = New-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -Body $TestURLProtectionPolicyJSON @SafeCommonParams
    it 'New-AppSecURLProtectionPolicy creates successfully' {
        $NewURLProtectionPolicy.configId | Should -Be $NewConfig.configId
    }
    
    ### Get-AppSecURLProtectionPolicy, all
    $Script:GetURLProtectionPolicies = Get-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams
    it 'Get-AppSecURLProtectionPolicy, all, returns the correct data' {
        $GetURLProtectionPolicies[0].configId | Should -Be $NewConfig.configId
    }
    
    ### Get-AppSecURLProtectionPolicy, single
    $Script:GetURLProtectionPolicy = Get-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -URLProtectionPolicyID $NewURLProtectionPolicy.policyId @SafeCommonParams
    it 'Get-AppSecURLProtectionPolicy, all, returns the correct data' {
        $GetURLProtectionPolicy.configId | Should -Be $NewConfig.configId
    }
    
    ### Set-AppSecURLProtectionPolicy by param
    $Script:SetURLProtectionPolicyByParam = Set-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -URLProtectionPolicyID $NewURLProtectionPolicy.policyId -Body $GetURLProtectionPolicy @SafeCommonParams
    it 'Set-AppSecURLProtectionPolicy by param updates successfully' {
        $SetURLProtectionPolicyByParam.configId | Should -Be $NewConfig.configId
    }
    
    ### Set-AppSecURLProtectionPolicy by pipeline
    $Script:SetURLProtectionPolicyByPipeline = ($GetURLProtectionPolicy | Set-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -URLProtectionPolicyID $NewURLProtectionPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecURLProtectionPolicy by pipeline updates successfully' {
        $SetURLProtectionPolicyByPipeline.configId | Should -Be $NewConfig.configId
    }

    ### Get-AppsecPolicyURLProtectionPolicy
    $Script:GetPolicyURLProtectionPolicies = Get-AppsecPolicyURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppsecPolicyURLProtectionPolicy returns the correct data' {
        $GetPolicyURLProtectionPolicies[0].policyId | Should -Be $GetURLProtectionPolicy.policyId
    }
    
    ### Set-AppsecPolicyURLProtectionPolicy
    $Script:SetPolicyURLProtectionPolicy = Set-AppsecPolicyURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId -URLProtectionPolicyID $GetURLProtectionPolicy.policyId -Action none @SafeCommonParams
    it 'Set-AppsecPolicyURLProtectionPolicy returns the correct data' {
        $SetPolicyURLProtectionPolicy.action | Should -Be 'none'
        $SetPolicyURLProtectionPolicy.policyId | Should -Be $GetURLProtectionPolicy.policyId
    }

    #-------------------------------------------------
    #               Attack Payload Settings
    #-------------------------------------------------

    ### Get-AppSecAttackPayloadSettings
    $Script:GetAttackPayloadSettings = Get-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams
    it 'Get-AppSecAttackPayloadSettings returns the correct data' {
        $GetAttackPayloadSettings.enabled | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecAttackPayloadSettings by param
    $Script:SetAttackPayloadSettingsByParam = Set-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -Body $GetAttackPayloadSettings @SafeCommonParams
    it 'Set-AppSecAttackPayloadSettings by pipeline returns the correct data' {
        $SetAttackPayloadSettingsByParam.enabled | Should -Be $GetAttackPayloadSettings.enabled
    }
    
    ### Set-AppSecAttackPayloadSettings by pipline
    $Script:SetAttackPayloadSettingsByPipeline = ($GetAttackPayloadSettings | Set-AppSecAttackPayloadSettings -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams)
    it 'Set-AppSecAttackPayloadSettings by pipeline returns the correct data' {
        $SetAttackPayloadSettingsByPipeline.enabled | Should -Be $GetAttackPayloadSettings.enabled
    }
    
    ### Get-AppSecPolicyAttackPayload
    $Script:GetPolicyAttackPayload = Get-AppSecPolicyAttackPayload -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyAttackPayload returns the correct data' {
        $GetPolicyAttackPayload.enabled | Should -Not -BeNullOrEmpty
    }
    
    # Set enabled to false
    $Script:GetPolicyAttackPayload.enabled = $false
    $Script:GetPolicyAttackPayload.override = $true

    ### Set-AppSecPolicyAttackPayload by param
    $Script:SetPolicyAttackPayloadByParam = Set-AppSecPolicyAttackPayload -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId -Body $GetPolicyAttackPayload @SafeCommonParams
    it 'Set-AppSecPolicyAttackPayload by param updates correctly' {
        $SetPolicyAttackPayloadByParam.enabled | Should -Be $false
    }
    
    ### Set-AppSecPolicyAttackPayload by pipeline
    $Script:SetPolicyAttackPayloadByPipeline = ($GetPolicyAttackPayload | Set-AppSecPolicyAttackPayload -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId @SafeCommonParams)
    it 'Set-AppSecPolicyAttackPayload by pipeline updates correctly' {
        $SetPolicyAttackPayloadByPipeline.enabled | Should -Be $false
    }

    #-------------------------------------------------
    #               Malware Policies
    #-------------------------------------------------

    ### New-AppSecMalwarePolicy
    $Script:NewMalwarePolicy = New-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -Body $Script:TestMalwarePolicyJSON @SafeCommonParams
    it 'New-AppSecMalwarePolicy creates successfully' {
        $NewMalwarePolicy.name | Should -Be $TestMalwarePolicyName
    }
    
    ### Get-AppSecMalwarePolicy, all
    $Script:GetMalwarePolicies = Get-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version @SafeCommonParams
    it 'Get-AppSecMalwarePolicy returns a list' {
        $GetMalwarePolicies[0].name | Should -Be $TestMalwarePolicyName
    }
    
    ### Get-AppSecMalwarePolicy, single
    $Script:GetMalwarePolicy = Get-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -MalwarePolicyID $NewMalwarePolicy.id @SafeCommonParams
    it 'Get-AppSecMalwarePolicy returns a list' {
        $GetMalwarePolicy.id | Should -Be $NewMalwarePolicy.id
    }

    ### Set-AppSecMalwarePolicy by param
    $Script:SetMalwarePolicyByParam = Set-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -MalwarePolicyID $NewMalwarePolicy.id -Body $GetMalwarePolicy @SafeCommonParams
    it 'Set-AppSecMalwarePolicy by param updates correctly' {
        $SetMalwarePolicyByParam.id | Should -Be $NewMalwarePolicy.id
    }
    
    ### Set-AppSecMalwarePolicy by pipeline
    $Script:SetMalwarePolicyByPipeline = ($GetMalwarePolicy | Set-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -MalwarePolicyID $NewMalwarePolicy.id @SafeCommonParams)
    it 'Set-AppSecMalwarePolicy by pipeline updates correctly' {
        $SetMalwarePolicyByPipeline.id | Should -Be $NewMalwarePolicy.id
    }
    
    ### Set-AppSecPolicyMalwarePolicy
    $Script:SetMalwarePolicyAction = Set-AppSecPolicyMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId -MalwarePolicyID $NewMalwarePolicy.id -Action alert -UnscannedAction alert @SafeCommonParams
    it 'Set-AppSecPolicyMalwarePolicy returns a list' {
        $SetMalwarePolicyAction.action | Should -Be 'alert'
        $SetMalwarePolicyAction.unscannedAction | Should -Be 'alert'
    }

    ### Get-AppSecPolicyMalwarePolicy
    $Script:GetMalwarePolicyActions = Get-AppSecPolicyMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyMalwarePolicy returns the correct data' {
        $GetMalwarePolicyActions[0].id | Should -Be $NewMalwarePolicy.id
    }

    #-------------------------------------------------
    #               Policy API Endpoints                    
    #-------------------------------------------------

    ### Get-AppSecPolicyAPIEndpoints
    $Script:PolicyAPIEndpoints = Get-AppSecPolicyAPIEndpoints -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId @SafeCommonParams
    it 'Get-AppSecPolicyAPIEndpoints returns the correct data' {
        $PolicyAPIEndpoints[0].id | Should -Be $TestAPIEndpointID
    }
    
    
    #-------------------------------------------------
    #                    Removals                    
    #-------------------------------------------------

    ### Remove-AppSecMatchTarget
    it 'Remove-AppSecMatchTarget completes successfully' {
        { Remove-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -TargetID $NewAPIMatchTarget.targetId @SafeCommonParams } | Should -Not -Throw
        { Remove-AppSecMatchTarget -ConfigID $NewConfig.configId -VersionNumber 1 -TargetID $NewWebsiteMatchTarget.targetId @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecPolicy
    it 'Remove-AppSecPolicy completes successfully' {
        { Remove-AppSecPolicy -ConfigID $NewConfig.configId -VersionNumber 1 -PolicyID $NewPolicy.policyId @SafeCommonParams } | Should -Not -Throw
    }

    # Wait for the policy removal to really complete
    Start-Sleep -Seconds 5

    ### Remove-AppSecReputationProfile
    it 'Remove-AppSecReputationProfile completes successfully' {
        { Remove-AppSecReputationProfile -ConfigID $NewConfig.configId -VersionNumber 1 -ReputationProfileID $NewReputationProfileByBody.id @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecCustomDenyAction
    it 'Get-AppSecCustomDenyAction completes successfully' {
        { Remove-AppSecCustomDenyAction -ConfigID $NewConfig.configId -VersionNumber 1 -CustomDenyID $NewCustomDenyAction.id @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecCustomRule
    it 'Remove-AppSecCustomRule completes successfully' {
        { Remove-AppSecCustomRule -ConfigID $NewConfig.ConfigId -RuleID $NewCustomRule.id @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecRatePolicy
    it 'Remove-AppSecRatePolicy completes successfully' {
        { Remove-AppSecRatePolicy -ConfigID $NewConfig.configId -VersionNumber 1 -RatePolicyID $NewRatePolicyByBody.id @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecURLProtectionPolicy
    it 'Remove-AppSecURLProtectionPolicy completes successfully' {
        { Remove-AppSecURLProtectionPolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -URLProtectionPolicyID $GetURLProtectionPolicy.policyId @SafeCommonParams } | Should -Not -Throw
    }
    
    ### Remove-AppSecMalwarePolicy
    it 'Remove-AppSecMalwarePolicy completes successfully' {
        { 
            Set-AppSecPolicyMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -PolicyID $NewPolicy.policyId -MalwarePolicyID $NewMalwarePolicy.id -Action none -UnscannedAction none @SafeCommonParams | Out-Null
            Remove-AppSecMalwarePolicy -ConfigID $NewConfig.configId -VersionNumber $NewVersion.version -MalwarePolicyID $GetMalwarePolicy.id @SafeCommonParams 
        } | Should -Not -Throw
    }

    ### Remove-AppSecConfiguration
    it 'Remove-AppSecConfiguration completes successfully' {
        { Remove-AppSecConfiguration -ConfigID $NewConfig.ConfigId @SafeCommonParams } | Should -Not -Throw
    }

    AfterAll {
    }
    
}

Describe 'Unsafe AppSec Tests' {

    #-------------------------------------------------
    #                   Activations                  
    #-------------------------------------------------

    ### Activate-AppSecConfigurationVersion
    $Script:Activate = New-AppSecActivation -ConfigID 12345 -VersionNumber 1 -Network STAGING -NotificationEmails 'mail@example.com' -Note 'testing' @UnsafeCommonParams
    it 'Activate-AppSecConfigurationVersion activates correctly' {
        $Activate.activationId | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecActivationHistory
    $Script:Activations = Get-AppSecActivationHistory -ConfigID 12345 @UnsafeCommonParams
    it 'Get-AppSecActivationHistory returns a list' {
        $Activations.count | Should -BeGreaterThan 0
    }

    ### Get-AppSecActivationRequestStatus
    $Script:ActivationRequest = Get-AppSecActivationRequestStatus -StatusID 'f81c92c5-b150-4c41-9b53-9cef7969150a' @UnsafeCommonParams
    it 'Get-AppSecActivationRequestStatus returns the correct data' {
        $ActivationRequest.statusId | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecActivationStatus
    $Script:ActivationStatus = Get-AppSecActivationStatus -ActivationID 1234 @UnsafeCommonParams
    it 'Get-AppSecActivationStatus returns the correct data' {
        $ActivationStatus.activationId | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                  Subscriptions                 
    #-------------------------------------------------

    ### Get-AppSecSubscribers
    $Script:Subscribers = Get-AppSecSubscribers -ConfigID 12345 -Feature AAG_TUNING_REC @UnsafeCommonParams
    it 'Get-AppSecSubscribers returns a list' {
        $Subscribers.count | Should -BeGreaterThan 0
    }

    ### New-AppSecSubscription
    it 'New-AppSecSubscription completes successfully' {
        { New-AppSecSubscription -ConfigID 12345 -Feature AAG_TUNING_REC -Subscribers "email@example.com, email2@example.com" @UnsafeCommonParams } | Should -Not -Throw
    }

    ### Remove-AppSecSubscription
    it 'Remove-AppSecSubscription completes successfully' {
        { Remove-AppSecSubscription -ConfigID 12345 -Feature AAG_TUNING_REC -Subscribers "email@example.com, email2@example.com" @UnsafeCommonParams } | Should -Not -Throw
    }

    #-------------------------------------------------
    #             Tuning Recommendations             
    #-------------------------------------------------
    
    ### Get-AppSecPolicyTuningRecommendations
    $Script:Recommendations = Get-AppSecPolicyTuningRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 @UnsafeCommonParams
    it 'Get-AppSecPolicyTuningRecommendations returns a list' {
        $Recommendations.ruleRecommendations | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyTuningRecommendations
    it 'Set-AppSecPolicyTuningRecommendations completes successfully' {
        { Set-AppSecPolicyTuningRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Action ACCEPT -SelectorID 84220 @UnsafeCommonParams } | Should -Not -Throw
    }

    ### Get-AppSecPolicyAttackGroupRecommendations
    $Script:AttackGroupRecommendations = Get-AppSecPolicyAttackGroupRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -AttackGroupID CMD @UnsafeCommonParams
    it 'Get-AppSecPolicyAttackGroupRecommendations returns a list' {
        $AttackGroupRecommendations.group | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecPolicyRuleRecommendations
    $Script:RuleRecommendations = Get-AppSecPolicyRuleRecommendations -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -RuleID 12345 @UnsafeCommonParams
    it 'Get-AppSecPolicyRuleRecommendations returns a list' {
        $RuleRecommendations.id | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                 API Discovery             
    #-------------------------------------------------

    ### Get-AppSecDiscoveredAPI, all
    $Script:DiscoveredAPIs = Get-AppSecDiscoveredAPI @UnsafeCommonParams
    it 'Get-AppSecDiscoveredAPI returns a list' {
        $DiscoveredAPIs.basePath | Should -Not -BeNullOrEmpty
    }
    
    ### Get-AppSecDiscoveredAPI, single
    $Script:DiscoveredAPI = Get-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api @UnsafeCommonParams
    it 'Get-AppSecDiscoveredAPI returns the correct data' {
        $DiscoveredAPI.apiEndpointIds | Should -Not -BeNullOrEmpty
    }
    
    ### Hide-AppSecDiscoveredAPI
    $Script:HideDiscoveredAPI = Hide-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api -Reason NOT_ELIGIBLE @UnsafeCommonParams
    it 'Hide-AppSecDiscoveredAPI returns the correct data' {
        $HideDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
    }
    
    ### Show-AppSecDiscoveredAPI
    $Script:ShowDiscoveredAPI = Show-AppSecDiscoveredAPI -Hostname www.example.com -BasePath /api -Reason FALSE_POSITIVE @UnsafeCommonParams
    it 'Show-AppSecDiscoveredAPI returns the correct data' {
        $ShowDiscoveredAPI.hidden | Should -Not -BeNullOrEmpty
    }

    ### Get-AppSecDiscoveredApiEndpoints
    $Script:DiscoveredAPIEndpoints = Get-AppSecDiscoveredApiEndpoints -Hostname www.example.com -BasePath /api @UnsafeCommonParams
    it 'Get-AppSecDiscoveredApiEndpoints returns a list' {
        $DiscoveredAPIEndpoints[0].apiEndpointId | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                Match Targets
    #-------------------------------------------------

    ### Get-AppSecHostnameMatchTargets
    $Script:HostnameMatchTargets = Get-AppSecHostnameMatchTargets -ConfigID 12345 -VersionNumber 1 -Hostname $TestHostnames @UnsafeCommonParams
    it 'Get-AppSecHostnameMatchTargets returns the correct data' {
        $HostnameMatchTargets.websiteTargets[0].configId | Should -Not -BeNullOrEmpty
    }
 
    #-------------------------------------------------
    #                Hostname Coverage
    #  (moved to unsafe due to timeouts in test account)         
    #-------------------------------------------------

    ### Get-AppSecHostnameCoverage
    $Script:Coverage = Get-AppSecHostnameCoverage @UnsafeCommonParams
    it 'Get-AppSecHostnameCoverage gets a list' {
        $Coverage.count | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #                Bypass Network Lists
    #-------------------------------------------------

    ### Get-AppSecBypassNetworkLists
    $Script:BypassNL = Get-AppSecBypassNetworkLists -ConfigID 12345 -VersionNumber 1 @UnsafeCommonParams
    it 'Get-AppSecBypassNetworkLists returns a list' {
        $BypassNL[0].id | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecBypassNetworkLists
    $Script:SetBypassNL = Set-AppSecBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -NetworkLists $BypassNL.id @UnsafeCommonParams
    it 'Set-AppSecBypassNetworkLists updates successfully' {
        $SetBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
    }

    ### Get-AppSecPolicyBypassNetworkLists
    $Script:GetPolicyBypassNL = Get-AppSecPolicyBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 @UnsafeCommonParams
    it 'Get-AppSecPolicyBypassNetworkLists returns a list' {
        $GetPolicyBypassNL[0].id | Should -Not -BeNullOrEmpty
    }

    ### Set-AppSecPolicyBypassNetworkLists
    $Script:SetPolicyBypassNL = ($GetPolicyBypassNL.id | Set-AppSecPolicyBypassNetworkLists -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 @UnsafeCommonParams)
    it 'Set-AppSecPolicyBypassNetworkLists updates correctly' {
        $SetPolicyBypassNL | Should -Match '[0-9]+_[A-Z0-9]+'
    }

    #-------------------------------------------------
    #                Policy Selected Hostnames
    #-------------------------------------------------

    ### Get-AppSecPolicySelectedHostnames
    $Script:PolicySelectedHostnames = Get-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 @UnsafeCommonParams
    it 'Get-AppSecPolicySelectedHostnames gets a list' {
        $PolicySelectedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
    }

    $PolicyHostnamesToAdd = @"
    {
        "hostnameList": [
            {
                "hostname": "$TestNewHostname"
            }
        ]
    }
"@

    ### Add-AppSecPolicySelectedHostnames
    $Script:PolicyAddedHostnames = Add-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PolicyHostnamesToAdd @UnsafeCommonParams
    it 'Add-AppSecPolicySelectedHostnames adds a hostname successfully' {
        $PolicyAddedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecPolicySelectedHostnames
    $Script:PolicyUpdatedHostnames = Set-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PolicyAddedHostnames @UnsafeCommonParams
    it 'Set-AppSecPolicySelectedHostnames adds a hostname successfully' {
        $PolicyUpdatedHostnames.hostnameList.count | Should -Not -BeNullOrEmpty
    }

    ### Remove-AppSecPolicySelectedHostnames
    $Script:PolicyRemovedHostnames = Remove-AppSecPolicySelectedHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $PolicyHostnamesToAdd @UnsafeCommonParams
    it 'Remove-AppSecPolicySelectedHostnames removes the correct hostname' {
        $PolicyRemovedHostnames.hostnameList.hostname | Should -Not -BeNullOrEmpty
    }

    #-------------------------------------------------
    #              Evaluation Hostnames
    #-------------------------------------------------
    
    ### Get-AppSecEvaluationHostnames
    $Script:GetEvaluationHostnames = Get-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1 @UnsafeCommonParams
    it 'Get-AppSecEvaluationHostnames gets a list' {
        $GetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecEvaluationHostnames
    $Script:SetEvaluationHostnames = Set-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -Body $GetEvaluationHostnames @UnsafeCommonParams
    it 'Set-AppSecEvaluationHostnames updates correctly' {
        $SetEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
    
    ### Protect-AppSecEvaluationHostnames
    $Script:ProtectEvaluationHostnames = Protect-AppSecEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -Body $GetEvaluationHostnames @UnsafeCommonParams
    it 'Protect-AppSecEvaluationHostnames updates correctly' {
        $ProtectEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
    
    ### Get-AppSecPolicyEvaluationHostnames
    $Script:GetPolicyEvaluationHostnames = Get-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 @UnsafeCommonParams
    it 'Get-AppSecPolicyEvaluationHostnames gets a list' {
        $GetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
    
    ### Set-AppSecPolicyEvaluationHostnames
    $Script:SetPolicyEvaluationHostnames = Set-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $GetPolicyEvaluationHostnames @UnsafeCommonParams
    it 'Set-AppSecPolicyEvaluationHostnames updates correctly' {
        $SetPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
    
    ### Protect-AppSecPolicyEvaluationHostnames
    $Script:ProtectPolicyEvaluationHostnames = Protect-AppSecPolicyEvaluationHostnames -ConfigID 12345 -VersionNumber 1 -PolicyID EX01_123456 -Body $GetPolicyEvaluationHostnames @UnsafeCommonParams
    it 'Protect-AppSecPolicyEvaluationHostnames updates correctly' {
        $ProtectPolicyEvaluationHostnames.hostnames | Should -Not -BeNullOrEmpty
    }
}
