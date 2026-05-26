BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.GTM Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.GTM'
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
        $TestDomainName = $env:PesterGTMDomain
        $TestLoadDataRequest = @"
{"domain":"$TestDomainName","datacenterId":1,"resource":"connections","current-load":20,"target-load":25,"max-load":30,"timestamp":"2023-06-07T17:38:53.188Z"}
"@
        $TestPropertyName = "property1-$Timestamp"
        $TestProperty = @"
{
  "name": "$TestPropertyName",
  "trafficTargets": [
    {
      "datacenterId": 1,
      "enabled": true,
      "weight": 1.0,
      "precedence": 0,
      "handoutCName": "dc1.akamaipowershell.net",
      "name": null,
      "servers": []
    },
    {
      "datacenterId": 2,
      "enabled": true,
      "weight": 0.0,
      "precedence": 0,
      "handoutCName": "dc2.akamaipowershell.net",
      "name": null,
      "servers": []
    }
  ],
  "livenessTests": [],
  "staticRRSets": [],
  "mapName": "",
  "handoutMode": "normal",
  "handoutLimit": 0,
  "scoreAggregationType": "worst",
  "dynamicTTL": 60,
  "type": "weighted-round-robin",
  "ipv6": false,
  "backupCName": null
}
"@ | ConvertFrom-Json
        $TestASMapName = "ASMap1-$Timestamp"
        $TestASMap = @"
{
  "name": "$TestASMapName",
  "assignments": [
    {
      "datacenterId": 1,
      "asNumbers": [
        12345
      ],
      "nickname": "aszone1"
    }
  ],
  "defaultDatacenter": {
    "datacenterId": 5400,
    "nickname": "Default (all others)"
  }
}
"@ | ConvertFrom-Json
        $TestGeoMapName = "GeoMap1-$Timestamp"
        $TestGeoMap = @"
{
  "name": "$TestGeoMapName",
  "assignments": [
    {
      "datacenterId": 1,
      "nickname": "GeoZone1",
      "countries": [
        "GB/SC"
      ]
    }
  ],
  "defaultDatacenter": {
    "datacenterId": 5400,
    "nickname": "Default Mapping"
  }
}
"@ | ConvertFrom-Json
        $TestCIDRMapName = "CIDMap1-$Timestamp"
        $TestCIDRMap = @"
{
  "name": "$TestCIDRMapName",
  "assignments": [
    {
      "datacenterId": 1,
      "blocks": [
        "1.2.3.0/24"
      ],
      "nickname": "CIDRZone1"
    }
  ],
  "defaultDatacenter": {
    "datacenterId": 5400,
    "nickname": "All Other CIDR Blocks"
  }
}
"@ | ConvertFrom-Json

        $TestResourceName = "resource1-$Timestamp"
        $TestResource = @"
{
  "aggregationType": "sum",
  "constrainedProperty": null,
  "decayRate": null,
  "description": "Testing",
  "hostHeader": "akamaipowershell.net",
  "leaderString": "leader",
  "leastSquaresDecay": null,
  "loadImbalancePercentage": null,
  "maxUMultiplicativeIncrement": null,
  "name": "$TestResourceName",
  "resourceInstances": [
    {
      "loadObject": null,
      "loadObjectPort": 9999,
      "loadServers": [
        "0.0.0.1"
      ],
      "datacenterId": 1,
      "useDefaultLoadObject": false
    },
    {
      "loadObject": null,
      "loadObjectPort": 9999,
      "loadServers": [
        "0.0.0.2"
      ],
      "datacenterId": 2,
      "useDefaultLoadObject": false
    }
  ],
  "type": "Non-XML load object via HTTP",
  "upperBound": 0
}
"@ | ConvertFrom-Json

        $TestLoadDataRequest = @"
{
        "domain": "$TestDomainName",
        "datacenterId": 1,
        "resource": "connections",
        "current-load": 20,
        "target-load": 25,
        "max-load": 30,
        "timestamp": "2023-06-07T17:38:53.188Z"
}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.GTM"

        $PD = @{}
    }

    AfterAll {
        Get-GTMProperty -DomainName $TestDomainName @CommonParams | Where-Object type -ne 'static' | Remove-GTMProperty -DomainName $TestDomainName @CommonParams
        Get-GTMDatacenter -DomainName $TestDomainName @CommonParams | Where-Object datacenterId -notin 1, 2 | Remove-GTMDatacenter -DomainName $TestDomainName @CommonParams
        Get-GTMASMap -DomainName $TestDomainName @CommonParams | Remove-GTMASMap -DomainName $TestDomainName @CommonParams
        Get-GTMCIDRMap -DomainName $TestDomainName @CommonParams | Remove-GTMCIDRMap -DomainName $TestDomainName @CommonParams
        Get-GTMGeoMap -DomainName $TestDomainName @CommonParams | Remove-GTMGeoMap -DomainName $TestDomainName @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------ Identity ---------------------#

    Context 'Get-GTMIdentity' {
        It 'returns the correct data' {
            $PD.GetGTMIdentity = Get-GTMIdentity @CommonParams
            $PD.GetGTMIdentity | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Contract ---------------------#

    Context 'Get-GTMContract' {
        It 'returns the correct data' {
            $PD.GetGTMContract = Get-GTMContract @CommonParams
            $PD.GetGTMContract[0].contractId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Group ---------------------#

    Context 'Get-GTMGroup' {
        It 'returns the correct data' {
            $PD.GetGTMGroup = Get-GTMGroup @CommonParams
            $PD.GetGTMGroup[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Domains ---------------------#

    Context 'Get-GTMDomain' {
        It 'returns a list' {
            $PD.Domains = Get-GTMDomain @CommonParams
            $PD.Domains[0].name | Should -Not -BeNullOrEmpty
        }
        It 'returns the right config by domain name' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.Domain = Get-GTMDomain @TestParams @CommonParams
            $PD.Domain.name | Should -Be $TestDomainName
        }
    }

    Context 'Set-GTMDomain' {
        It 'updates successfully by pipeline' {
            $PD.SetDomainByPipeline = $PD.Domain | Set-GTMDomain @CommonParams
            $PD.SetDomainByPipeline.Status.Message | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'Body'       = $PD.Domain
            }
            $PD.SetDomainByParam = Set-GTMDomain @TestParams @CommonParams
            $PD.SetDomainByParam.Status.Message | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'Body'       = (ConvertTo-Json -Depth 10 $PD.Domain)
            }
            $PD.SetDomainByJson = Set-GTMDomain @TestParams @CommonParams
            $PD.SetDomainByJson.Status.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDomainStatus' {
        It 'returns the right data' {
            $PD.Status = $PD.Domain | Get-GTMDomainStatus @CommonParams
            $PD.Status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMDomainStatus @CommonParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMDomainHistory' {
        It 'returns the right data' {
            $PD.History = $PD.Domain | Get-GTMDomainHistory -PageSize 1 @CommonParams
            $PD.History.metadata.pageSize | Should -Be 1
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMDomainHistory
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMDomainAuthority' {
        It 'returns the correct data' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.GetGTMDomainAuthority = Get-GTMDomainAuthority @TestParams @CommonParams
            $PD.GetGTMDomainAuthority.domainName | Should -Be $TestDomainName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMDomainAuthority
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMDomainList' {
        It 'returns the correct data' {
            $PD.GetGTMDomainList = Get-GTMDomainList @CommonParams
            $PD.GetGTMDomainList | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDomainSummary' {
        It 'returns the correct data' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.GetGTMDomainSummary = Get-GTMDomainSummary @TestParams @CommonParams
            $PD.GetGTMDomainSummary.name | Should -Be $TestDomainName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMDomainSummary
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------ Datacenters ---------------------#

    Context 'Get-GTMDatacenter - All' {
        It 'returns a list' {
            $PD.Datacenters = $PD.Domain | Get-GTMDatacenter @CommonParams
            $PD.Datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMDatacenter
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMDatacenter - Single' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'DatacenterID' = $PD.Datacenters[0].datacenterId
            }
            $PD.Datacenter = Get-GTMDatacenter @TestParams @CommonParams
            $PD.Datacenter.datacenterId | Should -Be $PD.Datacenters[0].datacenterId
            $PD.TempDatacenter = $PD.Datacenter.PSObject.Copy()
            $PD.TempDatacenter.NickName = $PD.Datacenter.NickName + '-temp'
        }
    }

    Context 'Set-GTMDatacenter' {
        It 'updates successfully by pipeline' {
            $PD.SetDatacenterByPipeline = $PD.Datacenter | Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.Datacenter.datacenterId @CommonParams
            $PD.SetDatacenterByPipeline.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'DatacenterID' = $PD.Datacenter.datacenterId
                'Body'         = $PD.Datacenter
            }
            $PD.SetDatacenterByParam = Set-GTMDatacenter @TestParams @CommonParams
            $PD.SetDatacenterByParam.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'DatacenterID' = $PD.Datacenter.datacenterId
                'Body'         = (ConvertTo-Json -Depth 10 $PD.Datacenter)
            }
            $PD.SetDatacenterByJson = Set-GTMDatacenter @TestParams @CommonParams
            $PD.SetDatacenterByJson.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
    }

    Context 'New-GTMDatacenter' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'Body'       = $PD.TempDatacenter
            }
            $PD.NewDatacenter = New-GTMDatacenter @TestParams @CommonParams
            $PD.NewDatacenter.NickName | Should -Be $PD.TempDatacenter.NickName
        }
    }

    Context 'New-GTMDefaultDatacenter' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.NewDefaultDC = New-GTMDefaultDatacenter @TestParams @CommonParams
            $PD.NewDefaultDC.NickName | Should -Be "Default Datacenter"
            $PD.NewDefaultDC.DatacenterId | Should -Be 5400
        }
    }

    Context 'New-GTMDefaultDatacenterForIP' {
        It 'creates IPv4' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'IPVersion'  = 'IPv4'
            }
            $PD.NewDefaultDCIPv4 = New-GTMDefaultDatacenterForIP @TestParams @CommonParams
            $PD.NewDefaultDCIPv4.NickName | Should -Be "Target for A records"
            $PD.NewDefaultDCIPv4.DatacenterId | Should -Be 5401
        }
        It 'creates IPv6' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'IPVersion'  = 'IPv6'
            }
            $PD.NewDefaultDCIPv6 = New-GTMDefaultDatacenterForIP @TestParams @CommonParams
            $PD.NewDefaultDCIPv6.NickName | Should -Be "Target for AAAA records"
            $PD.NewDefaultDCIPv6.DatacenterId | Should -Be 5402
        }
    }

    Context 'Remove-GTMDatacenter' {
        It 'deletes correctly by pipeline' {
            $RemoveSetDatacenter = $PD.NewDefaultDCIPv4, $PD.NewDefaultDCIPv6 | Remove-GTMDatacenter -DomainName $TestDomainName @CommonParams
            $RemoveSetDatacenter.status.message | Should -Not -BeNullOrEmpty
        }
        It 'deletes correctly by parameter' {
            $PD.RemoveDatacenter = $PD.NewDatacenter | Remove-GTMDatacenter -DomainName $TestDomainName @CommonParams
            $PD.RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $Result = & {} | Remove-GTMDatacenter @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------ AS Maps ---------------------#

    Context 'New-GTMASMap' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $TestASMapName
                'Body'       = $TestASMap
            }
            $PD.NewASMap = New-GTMASMap @TestParams @CommonParams
            $PD.NewASMap.Name | Should -Be $TestASMapName
        }
    }

    Context 'Get-GTMASMap' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.ASMaps = Get-GTMASMap @TestParams @CommonParams
            $PD.ASMaps[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct object by name' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $TestASMapName
            }
            $PD.ASMap = Get-GTMASMap @TestParams @CommonParams
            $PD.ASMap.Name | Should -Be $TestASMapName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMASMap
            $Result | Should -Not -Be 'IAR executed'
        }
    }
    
    Context 'Set-GTMASMap' {
        It 'updates successfully by pipeline' {
            $TempASMap = $PD.ASMap.PSObject.Copy()
            $TempASMap.Name += '-temp'
            $PD.SetASMap = $TempASMap | Set-GTMASMap -DomainName $TestDomainName -MapName $TempASMap.Name @CommonParams
            $PD.SetASMap.Name | Should -Be $TempASMap.Name
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetASMap.Name
                'Body'       = $PD.SetASMap
            }
            $PD.SetASMapByParam = Set-GTMASMap @TestParams @CommonParams
            $PD.SetASMapByParam.Name | Should -Be $PD.SetASMap.Name
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetASMap.Name
                'Body'       = (ConvertTo-Json -Depth 10 $PD.SetASMap)
            }
            $PD.SetASMapByJson = Set-GTMASMap @TestParams @CommonParams
            $PD.SetASMapByJson.Name | Should -Be $PD.SetASMap.Name
        }
    }

    Context 'Remove-GTMASMap' {
        It 'deletes correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetASMap.Name
            }
            $PD.RemoveSetASMap = Remove-GTMASMap @TestParams @CommonParams
            $PD.RemoveSetASMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewASMap = $PD.NewASMap | Remove-GTMASMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewASMap.status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = 'madeupdomain.com'
            }
            $Result = & {} | Remove-GTMASMap @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------ CIDR Map ---------------------#

    Context 'New-GTMCIDRMap' {
        It 'creates correctly' {
            $PD.NewCIDRMap = $TestCIDRMap | New-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.NewCIDRMap.Name | Should -Be $TestCIDRMapName
        }
    }

    Context 'Get-GTMCIDRMap' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.CIDRMaps = Get-GTMCIDRMap @TestParams @CommonParams
            $PD.CIDRMaps[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct object by name' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $TestCIDRMapName
            }
            $PD.CIDRMap = Get-GTMCIDRMap @TestParams @CommonParams
            $PD.CIDRMap.Name | Should -Be $TestCIDRMapName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMCIDRMap
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-GTMCIDRMap' {
        It 'updates successfully by pipeline' {
            $TempCIDRMap = $PD.CIDRMap.PSObject.Copy()
            $TempCIDRMap.Name += '-temp'
            $PD.SetCIDRMap = $TempCIDRMap | Set-GTMCIDRMap -DomainName $TestDomainName -MapName $TempCIDRMap.Name @CommonParams
            $PD.SetCIDRMap.Name | Should -Be $TempCIDRMap.Name
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetCIDRMap.Name
                'Body'       = $PD.SetCIDRMap
            }
            $PD.SetCIDRMapByParam = Set-GTMCIDRMap @TestParams @CommonParams
            $PD.SetCIDRMapByParam.Name | Should -Be $PD.SetCIDRMap.Name
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetCIDRMap.Name
                'Body'       = (ConvertTo-Json -Depth 10 $PD.SetCIDRMap)
            }
            $PD.SetCIDRMapByJson = Set-GTMCIDRMap @TestParams @CommonParams
            $PD.SetCIDRMapByJson.Name | Should -Be $PD.SetCIDRMap.Name
        }
    }

    Context 'Remove-GTMCIDRMap' {
        It 'deletes correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetCIDRMap.Name
            }
            $PD.RemoveSetCIDRMap = Remove-GTMCIDRMap @TestParams @CommonParams
            $PD.RemoveSetCIDRMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewCIDRMap = $PD.NewCIDRMap | Remove-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewCIDRMap.status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = 'madeupdomain.com'
            }
            $Result = & {} | Remove-GTMCIDRMap @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }
    
    #------------------ Geo Maps ---------------------#

    Context 'New-GTMGeoMap' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $TestGeoMapName
                'Body'       = $TestGeoMap
            }
            $PD.NewGeoMap = New-GTMGeoMap @TestParams @CommonParams
            $PD.NewGeoMap.Name | Should -Be $TestGeoMapName
        }
    }

    Context 'Get-GTMGeoMap' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.GeoMaps = Get-GTMGeoMap @TestParams @CommonParams
            $PD.GeoMaps[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct object by name' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $TestGeoMapName
            }
            $PD.GeoMap = Get-GTMGeoMap @TestParams @CommonParams
            $PD.GeoMap.Name | Should -Be $TestGeoMapName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMGeoMap
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-GTMGeoMap by pipeline' {
        It 'updates successfully by pipeline' {
            $TempGeoMap = $PD.GeoMap.PSObject.Copy()
            $TempGeoMap.Name += '-temp'
            $PD.SetGeoMap = $TempGeoMap | Set-GTMGeoMap -DomainName $TestDomainName -MapName $TempGeoMap.Name @CommonParams
            $PD.SetGeoMap.Name | Should -Be $TempGeoMap.Name
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetGeoMap.Name
                'Body'       = $PD.SetGeoMap
            }
            $PD.SetGeoMapByParam = Set-GTMGeoMap @TestParams @CommonParams
            $PD.SetGeoMapByParam.Name | Should -Be $PD.SetGeoMap.Name
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetGeoMap.Name
                'Body'       = (ConvertTo-Json -Depth 10 $PD.SetGeoMap)
            }
            $PD.SetGeoMapByJson = Set-GTMGeoMap @TestParams @CommonParams
            $PD.SetGeoMapByJson.Name | Should -Be $PD.SetGeoMap.Name
        }
    }

    Context 'Remove-GTMGeoMap' {
        It 'deletes correctly' {
            $TestParams = @{
                'DomainName' = $TestDomainName
                'MapName'    = $PD.SetGeoMap.Name
            }
            $PD.RemoveSetGeoMap = Remove-GTMGeoMap @TestParams @CommonParams
            $PD.RemoveSetGeoMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewGeoMap = $PD.NewGeoMap | Remove-GTMGeoMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewGeoMap.status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = 'madeupdomain.com'
            }
            $Result = & {} | Remove-GTMGeoMap @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------ Resources ---------------------#

    Context 'New-GTMResource' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'ResourceName' = $TestResourceName
                'Body'         = $TestResource
            }
            $PD.NewResource = New-GTMResource @TestParams @CommonParams
            $PD.NewResource.Name | Should -Be $TestResourceName
        }
    }

    Context 'Get-GTMResource' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.Resources = Get-GTMResource @TestParams @CommonParams
            $PD.Resources[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct object by name' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'ResourceName' = $TestResourceName
            }
            $PD.Resource = Get-GTMResource @TestParams @CommonParams
            $PD.Resource.Name | Should -Be $TestResourceName
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMResource
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-GTMResource by pipeline' {
        It 'updates successfully by pipeline' {
            $TempResource = $PD.Resource.PSObject.Copy()
            $TempResource.Name += $PD.Resource.Name + '-temp'
            $PD.SetResource = $TempResource | Set-GTMResource -DomainName $TestDomainName -ResourceName $TempResource.Name @CommonParams
            $PD.SetResource.Name | Should -Be $TempResource.Name
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'ResourceName' = $PD.SetResource.Name
                'Body'         = $PD.SetResource
            }
            $PD.SetResourceByParam = Set-GTMResource @TestParams @CommonParams
            $PD.SetResourceByParam.Name | Should -Be $PD.SetResource.Name
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'ResourceName' = $PD.SetResource.Name
                'Body'         = (ConvertTo-Json -Depth 10 $PD.SetResource)
            }
            $PD.SetResourceByJson = Set-GTMResource @TestParams @CommonParams
            $PD.SetResourceByJson.Name | Should -Be $PD.SetResource.Name
        }
    }

    Context 'Remove-GTMResource' {
        It 'deletes correctly' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'ResourceName' = $PD.SetResource.Name
            }
            $PD.RemoveSetResource = Remove-GTMResource @TestParams @CommonParams
            $PD.RemoveSetResource.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewResource = $PD.NewResource | Remove-GTMResource -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewResource.status.message | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = 'madeupdomain.com'
            }
            $Result = & {} | Remove-GTMResource @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------ Properties ---------------------#

    Context 'New-GTMProperty' {
        It 'creates correctly' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'PropertyName' = $TestPropertyName
                'Body'         = $TestProperty
            }
            $PD.NewProperty = New-GTMProperty @TestParams @CommonParams
            $PD.NewProperty.Name | Should -Be $TestPropertyName
        }
    }

    Context 'Get-GTMProperty - All' {
        It 'returns a list' {
            $TestParams = @{
                'DomainName' = $TestDomainName
            }
            $PD.Properties = Get-GTMProperty @TestParams @CommonParams
            $PD.Properties[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct object' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'PropertyName' = $TestPropertyName
            }
            $PD.Property = Get-GTMProperty @TestParams @CommonParams
            $PD.Property.Name | Should -Be $TestPropertyName
            $PD.Property.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.Property.Type | Should -Be $PD.NewProperty.Type
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Get-GTMProperty
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Set-GTMProperty' {
        It 'updates successfully by pipeline' {
            $PD.SetProperty = $PD.NewProperty | Set-GTMProperty -DomainName $TestDomainName @CommonParams
            $PD.SetProperty.Name | Should -Be $TestPropertyName
            $PD.SetProperty.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetProperty.Type | Should -Be $PD.NewProperty.Type
        }
        It 'updates successfully by param' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'PropertyName' = $PD.NewProperty.Name
                'Body'         = $PD.NewProperty
            }
            $PD.SetPropertyByParam = Set-GTMProperty @TestParams @CommonParams
            $PD.SetPropertyByParam.Name | Should -Be $PD.NewProperty.Name
            $PD.SetPropertyByParam.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetPropertyByParam.Type | Should -Be $PD.NewProperty.Type
        }
        It 'updates successfully by json' {
            $TestParams = @{
                'DomainName'   = $TestDomainName
                'PropertyName' = $PD.NewProperty.Name
                'Body'         = (ConvertTo-Json -Depth 10 $PD.NewProperty)
            }
            $PD.SetPropertyByJson = Set-GTMProperty @TestParams @CommonParams
            $PD.SetPropertyByJson.Name | Should -Be $PD.NewProperty.Name
            $PD.SetPropertyByJson.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetPropertyByJson.Type | Should -Be $PD.NewProperty.Type
        }
    }
    
    Context 'Remove-GTMProperty' {
        It 'throws no errors' {
            $PD.NewProperty | Remove-GTMProperty -DomainName $TestDomainName @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DomainName' = 'madeupdomain.com'
            }
            $Result = & {} | Remove-GTMProperty @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMDatacenterLatency' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMDatacenterLatency.json"
                return $Response | ConvertFrom-Json
            }
            $Latency = Get-GTMDatacenterLatency -Domain example.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $Latency.dataRows[0].latency | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDemand' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMDemand.json"
                return $Response | ConvertFrom-Json
            }
            $Demand = Get-GTMDemand -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $Demand.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'PropertyName' = 'www'
                'Start'        = '2021-05-23T01:56:13Z'
                'End'          = '2021-05-24T01:56:13Z'
            }
            $Result = & {} | Get-GTMDemand @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMIPAvailability' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMIPAvailability.json"
                return $Response | ConvertFrom-Json
            }
            $Availability = Get-GTMIPAvailability -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -IP 1.2.3.4
            $Availability.dataRows[0].datacenters[0].IPs[0].ip | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'PropertyName' = 'www'
                'Start'        = '2021-05-23T01:56:13Z'
                'End'          = '2021-05-24T01:56:13Z'
                'IP'           = '1.2.3.4'
            }
            $Result = & {} | Get-GTMIPAvailability @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMLivenessPerProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessPerProperty.json"
                return $Response | ConvertFrom-Json
            }
            $Liveness = Get-GTMLivenessPerProperty -Domain example.akadns.net -PropertyName www -Date '2021-05-23T01:56:13Z' -AgentIP 209.170.75.251
            $Liveness.dataRows[0].datacenters[0].errorCode | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'PropertyName' = 'www'
                'Date'         = '2021-05-23T01:56:13Z'
                'AgentIP'      = '209.170.75.251'
            }
            $Result = & {} | Get-GTMLivenessPerProperty @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMLivenessTestError' {
        It 'returns a list of errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessTestError.json"
                return $Response | ConvertFrom-Json
            }
            $LivenessErrors = Get-GTMLivenessTestError
            $LivenessErrors[0].errorCode | Should -Not -BeNullOrEmpty
        }
        It 'returns a specific error' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessTestError.json"
                return $Response | ConvertFrom-Json
            }
            $LivenessError = Get-GTMLivenessTestError -ErrorCode 3082
            $LivenessError.errorCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLoadFeedbackReport' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLoadFeedbackReport.json"
                return $Response | ConvertFrom-Json
            }
            $LoadFeedback = Get-GTMLoadFeedbackReport -Domain example.com.akadns.net -Resource MyResource -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $LoadFeedback.dataRows[0].datacenters[0].currentLoad | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'Resource' = 'MyResource'
                'Start'    = '2021-05-23T01:56:13Z'
                'End'      = '2021-05-24T01:56:13Z'
            }
            $Result = & {} | Get-GTMLoadFeedbackReport @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMTrafficPerDatacenter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMTrafficPerDatacenter.json"
                return $Response | ConvertFrom-Json
            }
            $TrafficPerDatacenter = Get-GTMTrafficPerDatacenter -Domain example.com.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $TrafficPerDatacenter.dataRows[0].properties[0].name | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'DatacenterID' = 3200
                'Start'        = '2021-05-23T01:56:13Z'
                'End'          = '2021-05-24T01:56:13Z'
            }
            $Result = & {} | Get-GTMTrafficPerDatacenter @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMTrafficPerProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMTrafficPerProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TrafficPerProperty = Get-GTMTrafficPerProperty -Domain example.com.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $TrafficPerProperty.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'PropertyName' = 'www'
                'Start'        = '2021-05-23T01:56:13Z'
                'End'          = '2021-05-24T01:56:13Z'
            }
            $Result = & {} | Get-GTMTrafficPerProperty @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-GTMLoadData' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLoadData.json"
                return $Response | ConvertFrom-Json
            }
            $Load = Get-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200
            $Load.'current-load' | Should -Not -BeNullOrEmpty
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                return 'IAR executed'
            }
            $TestParams = @{
                'Resource'     = 'MyResource'
                'DatacenterID' = 3200
            }
            $Result = & {} | Get-GTMLoadData @TestParams
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Submit-GTMLoadData' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Submit-GTMLoadData.json"
                return $Response | ConvertFrom-Json
            }
            $TestLoadDataRequest | Submit-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200 
        }
    }

    Context 'New-GTMDomain' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-GTMDomain.json"
                return $Response | ConvertFrom-Json
            }
            $NewDomain = New-GTMDomain -ContractID 1-1AB23C -GroupID 123456 -Body @{ type = 'basic'; name = 'testdomain.akadns.net' }
            $NewDomain.name | Should -Not -BeNullOrEmpty
        }
    }
}


