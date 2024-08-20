Describe 'Safe Akamai.FirewallRulesNotification Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.FirewallRulesNotification/Akamai.FirewallRulesNotification.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestEmailAddress = 'noreply@example.com'
        $TestServiceID = 1
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 FirewallRulesCIDR                  
    #------------------------------------------------

    Context 'Get-FirewallRulesCIDR' {
        It 'returns the correct data' {
            $PD.GetFirewallRulesCIDR = Get-FirewallRulesCIDR @CommonParams
            $PD.GetFirewallRulesCIDR[0].cidrId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 FirewallRulesService                  
    #------------------------------------------------

    Context 'Get-FirewallRulesService' {
        It 'returns the correct data' {
            $PD.GetFirewallRulesService = Get-FirewallRulesService @CommonParams
            $PD.GetFirewallRulesService[0].serviceId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 FirewallRulesSubscription                  
    #------------------------------------------------

    Context 'New-FirewallRulesSubscription' {
        It 'returns the correct data' {
            $PD.NewFirewallRulesSubscription = New-FirewallRulesSubscription -Email $TestEmailAddress -ServiceID $TestServiceID @CommonParams
            $PD.NewFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-FirewallRulesSubscription' {
        It 'returns the correct data' {
            $PD.GetFirewallRulesSubscription = Get-FirewallRulesSubscription @CommonParams
            $PD.GetFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-FirewallRulesSubscription by parameter' {
        It 'Set-FirewallRulesSubscription by param returns the correct data' {
            $PD.SetFirewallRulesSubscriptionByParam = Set-FirewallRulesSubscription -Body $PD.GetFirewallRulesSubscription @CommonParams
            $PD.SetFirewallRulesSubscriptionByParam[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-FirewallRulesSubscription by pipeline' {
        It 'returns the correct data' {
            $PD.SetFirewallRulesSubscriptionByPipeline = ($PD.GetFirewallRulesSubscription | Set-FirewallRulesSubscription @CommonParams)
            $PD.SetFirewallRulesSubscriptionByPipeline[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-FirewallRulesSubscription' {
        It 'returns the correct data' {
            $PD.RemoveFirewallRulesSubscription = Remove-FirewallRulesSubscription -SubscriptionId $PD.GetFirewallRulesSubscription[0].subscriptionId @CommonParams
            $PD.RemoveFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }
}