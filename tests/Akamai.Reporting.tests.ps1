Describe 'Safe Akamai.Reporting Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Reporting/Akamai.Reporting.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupName = $env:PesterGroupName
        $TestReportType = 'load-balancing-dns-traffic-by-datacenter'
        $TestReportTypeVersion = 1     
        $PD = @{}
        
    }

    Context 'Get-ReportType, all' {
        It 'Returns a list' {
            $PD.ReportTypes = Get-ReportType @CommonParams
            $PD.ReportTypes[0].name | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-ReportType, single' {
        It 'Returns a list' {
            $PD.ReportType = Get-ReportType -Name $TestReportType -Version $TestReportTypeVersion @CommonParams
            $PD.ReportType.name | Should -Be $TestReportType
        }
    }

    Context 'Get-ReportTypeVersions' {
        It 'Returns a list' {
            $PD.Versions = Get-ReportTypeVersions -Name $TestReportType @CommonParams
            $PD.Versions.count | Should -Not -Be 0
        }
    }

    AfterAll {
        
    }
}

Describe 'Unsafe Akamai.Reporting Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Reporting/Akamai.Reporting.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.Reporting"
        $PD = @{}
    }

    Context 'Get-Report' {
        It 'Gets some data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Reporting -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-Report.json"
                return $Response | ConvertFrom-Json
            }
            $GetReport = Get-Report -Name hits-by-time -Version 1 -Start 2022-12-21T00:00:00Z -End 2022-12-22T00:00:00Z -Interval HOUR -ObjectIds 123456
            $GetReport.data.count | Should -Not -Be 0
        }
    }

    Context 'New-Report' {
        It 'Gets some data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.Reporting -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-Report.json"
                return $Response | ConvertFrom-Json
            }
            $NewReport = New-Report -Name hits-by-time -Version 1 -Start 2022-12-21T00:00:00Z -End 2022-12-22T00:00:00Z -Interval HOUR -ObjectIDs 123456
            $NewReport.data.count | Should -Not -Be 0
        }
    }

}



