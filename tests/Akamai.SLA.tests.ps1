BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe SLA Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.SLA/Akamai.SLA.psd1 -Force

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $Start = "2024-03-26T10:23:24Z"
        $End = "2024-04-26T15:19:44Z"
        $APIStart = "2024-03-26T00:00Z"
        $AvailabilityReportID = 33002
        $PerformanceReportID = 33001
        $AvailabilityTestJSON = @"
{
  "contractId": "$TestContract",
  "agentGroupId": 5,
  "name": "temp-availability",
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
        $PerfTestJSON = @"
{
  "contractId": "$TestContract",
  "agentGroupId": 5,
  "name": "temp-performance",
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
"@
        $PerfTest = ConvertFrom-Json -InputObject $PerfTestJSON
    
        $PD = @{}
    }

    AfterAll {
        
    }

    #-------------------------------------------------
    #                  SLA Tests
    #-------------------------------------------------

    Context 'Get-SLATestConfiguration All' {
        It 'gets all test configurations' { 
            $GetAllTestConfigs = Get-SLATestConfiguration @CommonParams
            $GetAllTestConfigs[0].slaTestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-SLATestConfiguration Single' {
        It 'gets a test configuration by ID' {
            $PD.GetSingleTestConfig = Get-SLATestConfiguration -SLATestID $AvailabilityReportID @CommonParams
            $PD.GetSingleTestConfig[0].slaTestId | Should -Be $AvailabilityReportID
        }
        It 'gets a test configuration by piped ID' {
            $GetSingleTestConfig = $AvailabilityReportID | Get-SLATestConfiguration @CommonParams
            $GetSingleTestConfig[0].slaTestId | Should -Be $AvailabilityReportID
        }
        It 'gets a test configuration by piped object' {
            $GetSingleTestConfig = $PD.GetSingleTestConfig | Get-SLATestConfiguration @CommonParams
            $GetSingleTestConfig[0].slaTestId | Should -Be $PD.GetSingleTestConfig.slaTestID
        }
    }

    Context 'Get-SLAAvailabilityReport' { 
        It 'Gets an availability reporty by ID and time frame' {
            $GetAvailReport = Get-SLAAvailabilityReport -SLATestID $AvailabilityReportID -Start $Start -End $End @CommonParams
            $GetAvailReport[0].reportStart | Should -Be $APIStart 
        }
    }

    Context 'Get-SLAPerformanceReport' {
        It 'gets a performance report by ID and time frame' {
            $GetPerformReport = Get-SLAPerformanceReport -SLATestID $PerformanceReportID -Start $Start -End $End @CommonParams
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
            $GetQuotas[0].contractId | Should -Be $TestContract
        }
    }

    Context 'New-SLATestConfiguration' {
        It 'should create a new test successfully using json' {
            $PD.NewAvailTest = New-SLATestConfiguration -Body $AvailabilityTestJSON @CommonParams
            $PD.NewAvailTest.slaTestId | Should -Match '[\d]+'
        }
        It 'should create a new test successfully using the pipeline' {
            $PD.NewPerfTest = $PerfTest | New-SLATestConfiguration @CommonParams
            $PD.NewPerfTest.slaTestId | Should -Match '[\d]+'
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
            Remove-SLATestConfiguration -SLATestID $PD.NewAvailTest.slaTestId @CommonParams
        }
        It 'should remove the test successfully using the pipeline' {
            $PD.NewPerfTest | Remove-SLATestConfiguration @CommonParams
        }
    }
}