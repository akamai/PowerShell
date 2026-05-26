BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.FirewallRulesNotification Tests' {
    
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.FirewallRulesNotification'
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
        $TestEmailAddress = "noreply-$Timestamp@example.com"
        $TestServiceIDs = 1, 7
        $PD = @{}
    }

    AfterAll {
        Get-FirewallRulesSubscription @CommonParams | Remove-FirewallRulesSubscription @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
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
            $TestParams = @{
                'Email' = $TestEmailAddress
            }
            $PD.NewFirewallRulesSubscription = $TestServiceIDs | New-FirewallRulesSubscription @TestParams @CommonParams
            $PD.NewFirewallRulesSubscription[0].serviceId | Should -BeIn $TestServiceIDs
            $PD.NewFirewallRulesSubscription[1].serviceId | Should -BeIn $TestServiceIDs
        }
    }

    Context 'Get-FirewallRulesSubscription' {
        It 'returns the correct data' {
            $PD.GetFirewallRulesSubscription = Get-FirewallRulesSubscription @CommonParams
            $PD.GetFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-FirewallRulesSubscription' {
        It 'updates by body' {
            $TestParams = @{
                'Body' = $PD.GetFirewallRulesSubscription
            }
            $PD.SetFirewallRulesSubscriptionByParam = Set-FirewallRulesSubscription @TestParams @CommonParams
            $PD.SetFirewallRulesSubscriptionByParam[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
        It 'updates by pipeline' {
            $PD.SetFirewallRulesSubscriptionByPipeline = $PD.GetFirewallRulesSubscription | Set-FirewallRulesSubscription @CommonParams
            $PD.SetFirewallRulesSubscriptionByPipeline[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
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
    #                    Remove               
    #------------------------------------------------

    Context 'Remove-FirewallRulesSubscription' {
        It 'returns the correct data' {
            $PD.RemoveFirewallRulesSubscription = $PD.GetFirewallRulesSubscription | Remove-FirewallRulesSubscription @CommonParams
            $PD.RemoveFirewallRulesSubscription[0].subscriptionId | Should -Not -BeNullOrEmpty
        }
    }
}