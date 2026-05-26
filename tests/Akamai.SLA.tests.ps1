BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'SLA Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.SLA'
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
        $Start = "2024-03-26T10:23:24Z"
        $End = "2024-04-26T15:19:44Z"
        $APIStart = "2024-03-26T00:00Z"
        $TestAvailabilityName = "temp-availability-$Timestamp"
        $TestPerformanceName = "temp-performance-$Timestamp"
        $AvailabilityTest = @"
{
  "contractId": "$TestContractID",
  "agentGroupId": 5,
  "name": "$TestAvailabilityName",
  "type": "AVAILABILITY",
  "testDetails": {
    "originUrl": "https://origin.example.com/",
    "akamaiUrl": "https://www.example.com/",
    "originDnsHostnameOverride": null
  },
  "performanceSlaTarget": null,
  "availabilityFrequency": 360,
  "groupId": "$TestGroupID"
}
"@
        $PerfTest = @"
{
  "contractId": "$TestContractID",
  "agentGroupId": 5,
  "name": "$TestPerformanceName",
  "type": "PERFORMANCE",
  "testDetails": {
    "originUrl": "https://origin.example.com/",
    "akamaiUrl": "https://www.example.com/",
    "originDnsHostnameOverride": null
  },
  "performanceSlaTarget": 1.9,
  "availabilityFrequency": 360,
  "groupId": "$TestGroupID"
}
"@ | ConvertFrom-Json    
        $PD = @{}
    }

    AfterAll {
        Get-SLATestConfiguration @CommonParams | Where-Object name -in $TestPerformanceName, $TestAvailabilityName | Remove-SLATestConfiguration @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #-------------------------------------------------
    #                  SLA Tests
    #-------------------------------------------------

    Context 'New-SLATestConfiguration' {
        It 'should create a new test successfully using json' {
            $TestParams = @{
                'Body' = $AvailabilityTest
            }
            $PD.NewAvailTest = New-SLATestConfiguration @TestParams @CommonParams
            $PD.NewAvailTest.slaTestId | Should -Match '[\d]+'
        }
        It 'should create a new test successfully using the pipeline' {
            $PD.NewPerfTest = $PerfTest | New-SLATestConfiguration @CommonParams
            $PD.NewPerfTest.slaTestId | Should -Match '[\d]+'
        }
    }

    Context 'Get-SLATestConfiguration All' {
        It 'gets all test configurations' { 
            $GetAllTestConfigs = Get-SLATestConfiguration @CommonParams
            $GetAllTestConfigs[0].slaTestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-SLATestConfiguration' {
        It 'gets a test configuration by ID' {
            $TestParams = @{
                'SLATestID' = $PD.NewAvailTest.slaTestId
            }
            $PD.GetSingleTestConfig = Get-SLATestConfiguration @TestParams @CommonParams
            $PD.GetSingleTestConfig[0].slaTestId | Should -Be $PD.NewAvailTest.slaTestId
        }
        It 'gets a test configuration by piped ID' {
            $GetSingleTestConfig = $PD.NewAvailTest.slaTestId | Get-SLATestConfiguration @CommonParams
            $GetSingleTestConfig[0].slaTestId | Should -Be $PD.NewAvailTest.slaTestId
        }
        It 'gets a test configuration by piped object' {
            $GetSingleTestConfig = $PD.GetSingleTestConfig | Get-SLATestConfiguration @CommonParams
            $GetSingleTestConfig[0].slaTestId | Should -Be $PD.GetSingleTestConfig.slaTestID
        }
    }

    Context 'Get-SLAAvailabilityReport' { 
        It 'Gets an availability reporty by ID and time frame' {
            $TestParams = @{
                'End'       = $End
                'SLATestID' = $PD.NewAvailTest.slaTestId
                'Start'     = $Start
            }
            $GetAvailReport = Get-SLAAvailabilityReport @TestParams @CommonParams
            $GetAvailReport[0].reportStart | Should -Be $APIStart 
        }
    }

    Context 'Get-SLAPerformanceReport' {
        It 'gets a performance report by ID and time frame' {
            $TestParams = @{
                'End'       = $End
                'SLATestID' = $PD.NewPerfTest.slaTestId
                'Start'     = $Start
            }
            $GetPerformReport = Get-SLAPerformanceReport @TestParams @CommonParams
            $GetPerformReport[0].reportStart | Should -Be $APIStart 
        }
    }

    Context 'Get-SLATestAgentGroup' { 
        It 'gets a list of agent groups' {
            $GetAgentGroups = Get-SLATestAgentGroup @CommonParams
            $GetAgentGroups[0].agentGroupId  | Should -Not -BeNullOrEmpty 
        }
    }

    Context 'Get-SLATestConfigurationQuota' {
        It 'gets a list of config quotas' {
            $GetQuotas = Get-SLATestConfigurationQuota @CommonParams
            $GetQuotas[0].contractId | Should -Be $TestContractID
        }
    }

    Context 'Set-SLATestConfiguration' {
        It 'should update an availability test successfully' {
            $Test = $PD.NewAvailTest | Get-SLATestConfiguration @CommonParams
            $Test | Set-SLATestConfiguration @CommonParams
        }
        It 'should update a perf test successfully' {
            $Test = $PD.NewPerfTest | Get-SLATestConfiguration @CommonParams
            $Test | Set-SLATestConfiguration @CommonParams
        }
    }

    Context 'Remove-SLATestConfiguration' {
        It 'should remove the test successfully using parameters' {
            $TestParams = @{
                'SLATestID' = $PD.NewAvailTest.slaTestId
            }
            Remove-SLATestConfiguration @TestParams @CommonParams
        }
        It 'should remove the test successfully using the pipeline' {
            $PD.NewPerfTest | Remove-SLATestConfiguration @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.SLA -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-SLATestConfiguration
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}
