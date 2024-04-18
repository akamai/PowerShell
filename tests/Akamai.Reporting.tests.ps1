Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Reporting/Akamai.Reporting.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupName = $env:PesterGroupName
$Script:TestReportType = 'load-balancing-dns-traffic-by-datacenter'
$Script:TestReportTypeVersion = 1

Describe 'Safe Reporting Tests' {
    BeforeDiscovery {
        
    }

    ### Get-ReportType, all
    $Script:ReportTypes = Get-ReportType -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-ReportType returns a list' {
        $ReportTypes[0].name | Should -Not -BeNullOrEmpty
    }
    
    ### Get-ReportType, single
    $Script:ReportType = Get-ReportType -Name $TestReportType -Version $TestReportTypeVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-ReportType returns a list' {
        $ReportType.name | Should -Be $TestReportType
    }

    ### Get-ReportTypeVersions
    $Script:Versions = Get-ReportTypeVersions -Name $TestReportType -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-ReportTypeVersions returns a list' {
        $Versions.count | Should -Not -Be 0
    }

    AfterAll {
        
    }
}

Describe 'Unsafe Reporting Tests' {
    ### Get-Report
    $Script:GetReport = Get-Report -Name hits-by-time -Version 1 -Start 2022-12-21T00:00:00Z -End 2022-12-22T00:00:00Z -Interval HOUR -ObjectIds 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-Report gets some data' {
        $GetReport.data.count | Should -Not -Be 0
    }

    ### New-Report
    $Script:NewReport = New-Report -Name hits-by-time -Version 1 -Start 2022-12-21T00:00:00Z -End 2022-12-22T00:00:00Z -Interval HOUR -ObjectIDs 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-Report gets some data' {
        $NewReport.data.count | Should -Not -Be 0
    }

}
