Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.FirewallRulesNotification/Akamai.FirewallRulesNotification.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestEmailAddress = 'noreply@example.com'
$Script:TestServiceID = 1

Describe 'Safe Akamai.FirewallRulesNotification Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 FirewallRulesCIDR                  
    #------------------------------------------------

    ### Get-FirewallRulesCIDR
    $Script:GetFirewallRulesCIDR = Get-FirewallRulesCIDR -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-FirewallRulesCIDR returns the correct data' {
        $GetFirewallRulesCIDR[0].cidrId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 FirewallRulesService                  
    #------------------------------------------------

    ### Get-FirewallRulesService
    $Script:GetFirewallRulesService = Get-FirewallRulesService -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-FirewallRulesService returns the correct data' {
        $GetFirewallRulesService[0].serviceId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 FirewallRulesSubscription                  
    #------------------------------------------------

    ### New-FirewallRulesSubscription
    $Script:NewFirewallRulesSubscription = New-FirewallRulesSubscription -Email $TestEmailAddress -ServiceID $TestServiceID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-FirewallRulesSubscription returns the correct data' {
        $NewFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
    }

    ### Get-FirewallRulesSubscription
    $Script:GetFirewallRulesSubscription = Get-FirewallRulesSubscription -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-FirewallRulesSubscription returns the correct data' {
        $GetFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
    }

    ### Set-FirewallRulesSubscription by parameter
    $Script:SetFirewallRulesSubscriptionByParam = Set-FirewallRulesSubscription -Body $GetFirewallRulesSubscription -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-FirewallRulesSubscription by param returns the correct data' {
        $SetFirewallRulesSubscriptionByParam[0].subscriptionId | Should -Not -BeNullOrEmpty
    }

    ### Set-FirewallRulesSubscription by pipeline
    $Script:SetFirewallRulesSubscriptionByPipeline = ($GetFirewallRulesSubscription | Set-FirewallRulesSubscription -EdgeRCFile $EdgeRCFile -Section $Section)
    it 'Set-FirewallRulesSubscription by pipeline returns the correct data' {
        $SetFirewallRulesSubscriptionByPipeline[0].subscriptionId | Should -Not -BeNullOrEmpty
    }

    ### Remove-FirewallRulesSubscription
    $Script:RemoveFirewallRulesSubscription = Remove-FirewallRulesSubscription -SubscriptionId $GetFirewallRulesSubscription[0].subscriptionId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-FirewallRulesSubscription returns the correct data' {
        $RemoveFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}
