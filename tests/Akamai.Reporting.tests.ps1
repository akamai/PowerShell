BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Reporting Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Reporting'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestGroupName = $env:PesterGroupName

        $Today = (Get-Date).Date
        $TestToday = $Today.ToString("yyyy-MM-ddTHH:mm:ssZ")
        $Yesterday = $Today.AddDays(-1)
        $TestYesterday = $Yesterday.ToString("yyyy-MM-ddTHH:mm:ssZ")
        $1WeekAgo = $Today.AddDays(-7)
        $Test1WeekAgo = $1WeekAgo.ToString("yyyy-MM-ddTHH:mm:ssZ")

        $TestCPCode1 = $env:PesterCPCode
        $TestCPCode2 = $env:PesterCPCode2
        $TestRequestv1 = @"
{
  "objectIds": [
    "$TestCPCode1",
    "$TestCPCode2"
  ],
  "filters": {
    "url_contain": [
      "/"
    ],
    "delivery_type": [
      "non_secure"
    ]
  },
  "metrics": [
    "allEdgeBitsPerSecond",
    "allEdgeBytesTotal"
  ]
}
"@ | ConvertFrom-Json
        $TestRequestv2 = @"
{
  "dimensions": [
    "hostname",
    "responseCode"
  ],
  "filters": [
    {
      "dimensionName": "cpcode",
      "expressions": [
        "$TestCPCode1",
        "$TestCPCode2"
      ],
      "operator": "IN_LIST"
    }
  ],
  "metrics": [
    "edgeBytesSum",
    "edgeHitsSum"
  ],
  "sortBys": [
    {
      "name": "hostname",
      "sortOrder": "ASCENDING"
    },
    {
      "name": "edgeHitsSum",
      "sortOrder": "DESCENDING"
    }
  ],
  "limit": 1000
}
"@ | ConvertFrom-Json
        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #-------------------------------------------------
    #                v1 (legacy)
    #-------------------------------------------------

    # Get all types
    Context 'Get-LegacyReportType' -Tag 'legacy' {
        It 'Returns a list v1' {
            $PD.ReportTypes = Get-LegacyReportType @CommonParams
            $PD.ReportTypes[0].name | Should -Not -BeNullOrEmpty
        }
        It 'Returns single type v1 by parameter' {
            $TestParams = @{
                'Name'    = 'urlbytes-by-time'
                'Version' = 1
            }
            $PD.ReportType = Get-LegacyReportType @TestParams @CommonParams
            $PD.ReportType.name | Should -Be 'urlbytes-by-time'
        }
        It 'Returns single type v1 by pipeline' {
            $ReportType = $PD.ReportType | Get-LegacyReportType @CommonParams
            $ReportType.name | Should -Be 'urlbytes-by-time'
        }
    }

    # Get all versions for a given type
    Context 'Get-LegacyReportTypeVersions' -Tag 'legacy' {
        It 'Returns a list by param' {
            $TestParams = @{
                'Name' = 'urlbytes-by-time'
            }
            $PD.Versions = Get-LegacyReportTypeVersions @TestParams @CommonParams
            $PD.Versions.count | Should -Not -Be 0
        }
        It 'Returns a list by pipeline' {
            $Versions = $PD.ReportType | Get-LegacyReportTypeVersions @CommonParams
            $Versions.count | Should -Not -Be 0
        }
    }

    # Get a cached report
    Context 'Get-LegacyReport' -Tag 'legacy' {
        # Get report for all object IDs
        It 'Gets some data v1 all IDs by param' {
            $TestParams = @{
                'Name'         = 'urlbytes-by-time'
                'Version'      = 1
                'Start'        = $Test1WeekAgo
                'End'          = $TestYesterday
                'Interval'     = 'DAY'
                'AllObjectIDs' = $true
            }
            $GetReport = Get-LegacyReport @TestParams @CommonParams
            # Start-Sleep -Seconds 15
            $GetReport.metadata.objectIds.count | Should -Not -BeNullOrEmpty
        }
        
        It 'Gets some data v1 all IDs by pipeline' {
            $TestParams = @{
                'Start'        = $Test1WeekAgo
                'End'          = $TestYesterday
                'Interval'     = 'DAY'
                'AllObjectIDs' = $true
            }
            $GetReport = $PD.ReportType | Get-LegacyReport @TestParams @CommonParams
            # Start-Sleep -Seconds 15
            $GetReport.metadata.objectIds.count | Should -Not -BeNullOrEmpty
        }

        # Gets data by a set of IDs, checks formatting for multiple values
        It 'Gets some data v1 by IDs' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIds' = $TestCPCode1, $TestCPCode2
            }
            $GetReport = Get-LegacyReport @TestParams @CommonParams
            $GetReport.data.count | Should -Not -Be 0
        }

        # Gets data by a IDs and metrics, checks formatting for multiple values
        It 'Gets some data v1 by IDs and metrics' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIds' = $TestCPCode1, $TestCPCode2
                'Metrics'   = 'allEdgeBitsPerSecond', 'allEdgeBytesTotal'
            }
            $GetReport = Get-LegacyReport @TestParams @CommonParams
            $GetReport.data.count | Should -Not -Be 0
        }

        # Gets data by a IDs and filters, checks formatting for multiple values
        It 'Gets some data v1 by IDs and filters' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIds' = $TestCPCode1, $TestCPCode2
                'Filters'   = "url_contain=/,delivery_type=non_secure"
            }
            $GetReport = Get-LegacyReport @TestParams @CommonParams
            $GetReport.data.count | Should -Not -Be 0
        }

        # Gets data by a IDs and filters, checks formatting for ill-formed values
        It 'Gets some data v1 by IDs and ill-formed filters' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIds' = $TestCPCode1, $TestCPCode2
                'Filters'   = "url_contain /,delivery_type=non_secure"
            }
            { Get-LegacyReport @TestParams @CommonParams } | Should -throw
            $Error[0].exception.data.title | Should -Be "Validation failed"
        }

        # Gets data by a IDs, metrics, and filters, checks formatting for multiple values
        It 'Gets some data v1 by IDs, metrics, and filters' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIds' = $TestCPCode1, $TestCPCode2
                'Metrics'   = 'allEdgeBitsPerSecond', 'allEdgeBytesTotal'
                'Filters'   = "url_contain=/,delivery_type=non_secure"
            }
            $GetReport = Get-LegacyReport @TestParams @CommonParams
            $GetReport.data.count | Should -Not -Be 0
        }
    }

    # Create new report
    Context 'New-LegacyReport' -Tag 'legacy' {
        # New report, metrics
        It 'Generates a report v1, attributes' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIDs' = $TestCPCode1, $TestCPCode2
                'Metrics'   = 'allEdgeBitsPerSecond', 'allEdgeBytesTotal'
            }
            $NewReport = New-LegacyReport @TestParams @CommonParams
            $NewReport.data.count | Should -Not -Be 0
        }

        # New report, filters
        It 'Generates a report v1, attributes' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIDs' = $TestCPCode1, $TestCPCode2
                'Filters'   = 'url_contain=/', 'delivery_type=non_secure'
            }
            $NewReport = New-LegacyReport @TestParams @CommonParams
            $NewReport.data.count | Should -Not -Be 0
        }

        # New report, metrics and filters
        It 'Generates a report v1, attributes' {
            $TestParams = @{
                'Name'      = 'urlbytes-by-time'
                'Version'   = 1
                'Start'     = $Test1WeekAgo
                'End'       = $TestYesterday
                'Interval'  = 'DAY'
                'ObjectIDs' = $TestCPCode1, $TestCPCode2
                'Metrics'   = 'allEdgeBitsPerSecond', 'allEdgeBytesTotal'
                'Filters'   = 'url_contain=/', 'delivery_type=non_secure'
            }
            $NewReport = New-LegacyReport @TestParams @CommonParams
            $NewReport.data.count | Should -Not -Be 0
        }

        # New report, body, metrics and filters
        It 'Generates a report v1, body' {
            $TestParams = @{
                'Name'     = 'urlbytes-by-time'
                'Version'  = 1
                'Start'    = $Test1WeekAgo
                'End'      = $TestYesterday
                'Interval' = 'DAY'
                'Body'     = $TestRequestv1
            }
            $NewReport = New-LegacyReport @TestParams @CommonParams
            $NewReport.data.count | Should -Not -Be 0
        }
    }

    #-------------------------------------------------
    #                v2
    #-------------------------------------------------

    Context 'Get-ReportType' -Tag 'v2' {
        # Gets a list of all available reports v2
        It 'Returns a list v2' {
            $GetReport = Get-ReportType @CommonParams
            $GetReport.reports.count | Should -Not -Be 0
        }
        It 'Returns list by product family' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
            }
            $GetReport = Get-ReportType @TestParams @CommonParams
            $GetReport.reports.count | Should -Not -Be 0
        }
        It 'Returns list by reporting area' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
            }
            $GetReport = Get-ReportType @TestParams @CommonParams
            $GetReport.reports.count | Should -Not -Be 0
        }
        It 'throws an error if ReportingArea is present, but ProductFamily is not' {
            $TestParams = @{
                'ReportingArea' = 'traffic'
            }
            { Get-ReportType @TestParams @CommonParams } | Should -Throw "ReportingArea parameter requires ProductFamily parameter."
        }
        It 'Returns a single type v2' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
            }
            $GetReport = Get-ReportType @TestParams @CommonParams
            $GetReport.metrics.count | Should -Not -Be 0
        }
        It 'throws an error if Report is present, but ProductFamily and ReportingArea are not' {
            { Get-ReportType -Report 'current' @CommonParams } | Should -Throw "Report parameter requires ProductFamily and ReportingArea parameters."
            { Get-ReportType -Report 'current' -ProductFamily 'delivery' @CommonParams } | Should -Throw "Report parameter requires ProductFamily and ReportingArea parameters."
            { Get-ReportType -Report 'current' -ReportingArea 'traffic' @CommonParams } | Should -Throw "Report parameter requires ProductFamily and ReportingArea parameters."
        }
    }
    
    Context 'Get-ReportProductFamily' -Tag 'v2' {
        It 'Returns list of product families' {
            $GetReport = Get-ReportProductFamily @CommonParams
            $GetReport | Should -Not -Be 0
        }
    }
    
    Context 'Get-ReportingArea' -Tag 'v2' {
        It 'Returns list of reporting areas' {
            $GetReport = Get-ReportingArea @CommonParams
            $GetReport | Should -Not -Be 0
        }
    }

    Context 'New report' -Tag 'v2' {
        It 'Generates v2 report only by time' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'TimeRange'     = 'LAST_1_DAY'
            }
            $NewReport = New-Report @TestParams @CommonParams
            Should -ActualValue $NewReport.data -Not -Be $null
            $NewReport.metadata.name | Should -Not -BeNullOrEmpty
            $NewReport.metadata.start | Should -Not -BeNullOrEmpty
            $NewReport.metadata.end | Should -Not -BeNullOrEmpty
        }

        It 'Generates v2 report only by time, body' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'TimeRange'     = 'LAST_1_DAY'
                'Body'          = $TestRequestv2
            }
            $NewReport = New-Report @TestParams @CommonParams
            Should -ActualValue $NewReport.data -Not -Be $null
            $NewReport.metadata.name | Should -Not -BeNullOrEmpty
            $NewReport.metadata.start | Should -Not -BeNullOrEmpty
            $NewReport.metadata.end | Should -Not -BeNullOrEmpty
        }

        It 'Generates v2 report only by date' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'Start'         = $Test1WeekAgo
                'End'           = $TestYesterday
            }
            $NewReport = New-Report @TestParams @CommonParams
            Should -ActualValue $NewReport.data -Not -Be $null
            $NewReport.metadata.name | Should -Not -BeNullOrEmpty
            $NewReport.metadata.start | Should -Not -BeNullOrEmpty
            $NewReport.metadata.end | Should -Not -BeNullOrEmpty

        }

        It 'Generates v2 report only by date, body' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'Start'         = $Test1WeekAgo
                'End'           = $TestYesterday
                'Body'          = $TestRequestv2
            }
            $NewReport = New-Report @TestParams @CommonParams
            Should -ActualValue $NewReport.data -Not -Be $null
            $NewReport.metadata.name | Should -Not -BeNullOrEmpty
            $NewReport.metadata.start | Should -Not -BeNullOrEmpty
            $NewReport.metadata.end | Should -Not -BeNullOrEmpty

        }

        It 'Generates v2 async report by date by param' {
            $TestParams = @{
                'Report'        = 'current'
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Start'         = $Test1WeekAgo
                'End'           = $TestYesterday
                'Async'         = $true
            }
            $PD.AsyncReport1 = New-Report @TestParams @CommonParams
            $PD.AsyncReport1.QueryID | Should -Not -BeNullOrEmpty
            $PD.AsyncReport1.ProductFamily | Should -Not -BeNullOrEmpty
            $PD.AsyncReport1.ReportingArea | Should -Not -BeNullOrEmpty
            $PD.AsyncReport1.Report | Should -Not -BeNullOrEmpty
        }

        It 'Generates v2 async report by time' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'TimeRange'     = 'LAST_1_DAY'
                'Async'         = $true
            }
            $PD.AsyncReport2 = New-Report @TestParams @CommonParams
            $PD.AsyncReport2.QueryID | Should -Not -BeNullOrEmpty
            $PD.AsyncReport2.ProductFamily | Should -Not -BeNullOrEmpty
            $PD.AsyncReport2.ReportingArea | Should -Not -BeNullOrEmpty
            $PD.AsyncReport2.Report | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-Report' -Tag 'v2' {
        It 'Waits for 60s for tests to complete' {
            while ($true) {
                try {
                    $Report = $PD.AsyncReport2 | Get-Report @CommonParams
                    if ($null -ne $Report) {
                        break
                    }
                }
                catch { }
                Start-Sleep -Seconds 30
            }
        }

        It 'Gets existing v2 report by param' {
            $TestParams = @{
                'ProductFamily' = 'delivery'
                'ReportingArea' = 'traffic'
                'Report'        = 'current'
                'QueryID'       = $PD.AsyncReport1.QueryID
            }
            $GetReport = Get-Report @TestParams @CommonParams
            Should -ActualValue $GetReport.data -Not -Be $null
            $GetReport.metadata.name | Should -Not -BeNullOrEmpty
        }
        It 'Gets existing v2 report by pipeline' {
            $GetReport = $PD.AsyncReport2 | Get-Report @CommonParams
            Should -ActualValue $GetReport.data -Not -Be $null
            $GetReport.metadata.name | Should -Not -BeNullOrEmpty
        }
    }
}