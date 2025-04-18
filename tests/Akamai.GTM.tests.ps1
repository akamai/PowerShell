BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.GTM Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.GTM/Akamai.GTM.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestDomainName = $env:PesterGTMDomain
        $TestLoadDataRequest = @"
{"domain":"$TestDomainName","datacenterId":1,"resource":"connections","current-load":20,"target-load":25,"max-load":30,"timestamp":"2023-06-07T17:38:53.188Z"}
"@
        $TestPropertyName = "property1"
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
        $TestASMapName = 'asmap1'
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
        $TestGeoMapName = 'GeoMap1'
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
        $TestCIDRMapName = 'CIDMap1'
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

        $TestResourceName = 'resource1'
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
        $PD = @{}
    }

    AfterAll {
        Get-GTMProperty -DomainName $TestDomainName @CommonParams | Remove-GTMProperty -DomainName $TestDomainName @CommonParams
        Get-GTMASMap -DomainName $TestDomainName @CommonParams | Remove-GTMASMap -DomainName $TestDomainName @CommonParams
        Get-GTMCIDRMap -DomainName $TestDomainName @CommonParams | Remove-GTMCIDRMap -DomainName $TestDomainName @CommonParams
        Get-GTMGeoMap -DomainName $TestDomainName @CommonParams | Remove-GTMGeoMap -DomainName $TestDomainName @CommonParams
    }

    #------------------ Domains ---------------------#

    Context 'Get-GTMDomain - All' {
        It 'returns a list' {
            $PD.Domains = Get-GTMDomain @CommonParams
            $PD.Domains[0].name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDomain - Single' {
        It 'returns the right config' {
            $PD.Domain = Get-GTMDomain -DomainName $TestDomainName @CommonParams
            $PD.Domain.name | Should -Be $TestDomainName
        }
    }

    Context 'Set-GTMDomain by pipeline' {
        It 'returns the correct data' {
            $PD.SetDomainByPipeline = $PD.Domain | Set-GTMDomain -DomainName $TestDomainName @CommonParams
            $PD.SetDomainByPipeline.Status.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-GTMDomain by param' {
        It 'returns the correct data' {
            $PD.SetDomainByParam = Set-GTMDomain -DomainName $TestDomainName -Body $PD.Domain @CommonParams
            $PD.SetDomainByParam.Status.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-GTMDomain by json' {
        It 'returns the correct data' {
            $PD.SetDomainByJson = Set-GTMDomain -DomainName $TestDomainName -Body (ConvertTo-Json -Depth 10 $PD.Domain) @CommonParams
            $PD.SetDomainByJson.Status.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDomainStatus' {
        It 'returns the right data' {
            $PD.Status = Get-GTMDomainStatus -DomainName $TestDomainName @CommonParams
            $PD.Status.message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDomainHistory' {
        It 'returns the right data' {
            $PD.History = Get-GTMDomainHistory -DomainName $TestDomainName -PageSize 1 @CommonParams
            $PD.History.metadata.pageSize | Should -Be 1
        }
    }

    #------------------ Datacenters ---------------------#

    Context 'Get-GTMDatacenter - All' {
        It 'returns a list' {
            $PD.Datacenters = Get-GTMDatacenter -DomainName $TestDomainName @CommonParams
            $PD.Datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDatacenter - Single' {
        It 'returns a list' {
            $PD.Datacenter = Get-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.Datacenters[0].datacenterId @CommonParams
            $PD.Datacenter.datacenterId | Should -Be $PD.Datacenters[0].datacenterId
            $PD.TempDatacenter = $PD.Datacenter.PSObject.Copy()
            $PD.TempDatacenter.NickName = $PD.Datacenter.NickName + '-temp'
        }
    }

    Context 'Set-GTMDatacenter by pipeline' {
        It 'updates correctly' {
            $PD.SetDatacenterByPipeline = $PD.Datacenter | Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.Datacenter.datacenterId @CommonParams
            $PD.SetDatacenterByPipeline.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
    }

    Context 'Set-GTMDatacenter by param' {
        It 'returns the correct data' {
            $PD.SetDatacenterByParam = Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.Datacenter.datacenterId -Body $PD.Datacenter @CommonParams
            $PD.SetDatacenterByParam.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
    }

    Context 'Set-GTMDatacenter by json' {
        It 'updates correctly' {
            $PD.SetDatacenterByJson = Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.Datacenter.datacenterId -Body (ConvertTo-Json -Depth 10 $PD.Datacenter) @CommonParams
            $PD.SetDatacenterByJson.datacenterId | Should -Be $PD.Datacenter.datacenterId
        }
    }

    Context 'New-GTMDatacenter' {
        It 'creates correctly' {
            $PD.NewDatacenter = New-GTMDatacenter -DomainName $TestDomainName -Body $PD.TempDatacenter @CommonParams
            $PD.NewDatacenter.NickName | Should -Be $PD.TempDatacenter.NickName
        }
    }

    Context 'Remove-GTMDatacenter' {
        It 'deletes correctly' {
            $PD.RemoveDatacenter = Remove-GTMDatacenter -DomainName $TestDomainName -DatacenterID $PD.NewDatacenter.datacenterId @CommonParams
            $PD.RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ AS Maps ---------------------#

    Context 'New-GTMASMap' {
        It 'creates correctly' {
            $TestParams = @{
                DomainName = $TestDomainName
                MapName    = $TestASMapName
                Body       = $TestASMap
            }
            $PD.NewASMap = New-GTMASMap @TestParams @CommonParams
            $PD.NewASMap.Name | Should -Be $TestASMapName
        }
    }

    Context 'Get-GTMASMap - All' {
        It 'returns a list' {
            $PD.ASMaps = Get-GTMASMap -DomainName $TestDomainName @CommonParams
            $PD.ASMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMASMap - Single' {
        It 'returns the correct object' {
            $PD.ASMap = Get-GTMASMap -DomainName $TestDomainName -MapName $TestASMapName @CommonParams
            $PD.ASMap.Name | Should -Be $TestASMapName
        }
    }
    
    Context 'Set-GTMASMap by pipeline' {
        It 'updates correctly' {
            $TempASMap = $PD.ASMap.PSObject.Copy()
            $TempASMap.Name += '-temp'
            $PD.SetASMap = $TempASMap | Set-GTMASMap -DomainName $TestDomainName -MapName $TempASMap.Name @CommonParams
            $PD.SetASMap.Name | Should -Be $TempASMap.Name
        }
    }

    Context 'Set-GTMASMap by param' {
        It 'updates correctly' {
            $PD.SetASMapByParam = Set-GTMASMap -DomainName $TestDomainName -MapName $PD.SetASMap.Name -Body $PD.SetASMap @CommonParams
            $PD.SetASMapByParam.Name | Should -Be $PD.SetASMap.Name
        }
    }

    Context 'Set-GTMASMap by json' {
        It 'updates correctly' {
            $PD.SetASMapByJson = Set-GTMASMap -DomainName $TestDomainName -MapName $PD.SetASMap.Name -Body (ConvertTo-Json -Depth 10 $PD.SetASMap) @CommonParams
            $PD.SetASMapByJson.Name | Should -Be $PD.SetASMap.Name
        }
    }

    Context 'Remove-GTMASMap' {
        It 'deletes correctly' {
            $PD.RemoveSetASMap = Remove-GTMASMap -DomainName $TestDomainName -MapName $PD.SetASMap.Name @CommonParams
            $PD.RemoveSetASMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewASMap = $PD.NewASMap | Remove-GTMASMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewASMap.status.message | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ CIDR Map ---------------------#

    Context 'New-GTMCIDRMap' {
        It 'creates correctly' {
            $PD.NewCIDRMap = $TestCIDRMap | New-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.NewCIDRMap.Name | Should -Be $TestCIDRMapName
        }
    }

    Context 'Get-GTMCIDRMap - All' {
        It 'returns a list' {
            $PD.CIDRMaps = Get-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.CIDRMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMCIDRMap - Single' {
        It 'returns the correct object' {
            $PD.CIDRMap = Get-GTMCIDRMap -DomainName $TestDomainName -MapName $TestCIDRMapName @CommonParams
            $PD.CIDRMap.Name | Should -Be $TestCIDRMapName
        }
    }

    Context 'Set-GTMCIDRMap by pipeline' {
        It 'updates correctly' {
            $TempCIDRMap = $PD.CIDRMap.PSObject.Copy()
            $TempCIDRMap.Name += '-temp'
            $PD.SetCIDRMap = $TempCIDRMap | Set-GTMCIDRMap -DomainName $TestDomainName -MapName $TempCIDRMap.Name @CommonParams
            $PD.SetCIDRMap.Name | Should -Be $TempCIDRMap.Name
        }
    }

    Context 'Set-GTMCIDRMap by param' {
        It 'updates correctly' {
            $PD.SetCIDRMapByParam = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.SetCIDRMap.Name -Body $PD.SetCIDRMap @CommonParams
            $PD.SetCIDRMapByParam.Name | Should -Be $PD.SetCIDRMap.Name
        }
    }

    Context 'Set-GTMCIDRMap by json' {
        It 'updates correctly' {
            $PD.SetCIDRMapByJson = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.SetCIDRMap.Name -Body (ConvertTo-Json -Depth 10 $PD.SetCIDRMap) @CommonParams
            $PD.SetCIDRMapByJson.Name | Should -Be $PD.SetCIDRMap.Name
        }
    }

    Context 'Remove-GTMCIDRMap' {
        It 'deletes correctly' {
            $PD.RemoveSetCIDRMap = Remove-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.SetCIDRMap.Name @CommonParams
            $PD.RemoveSetCIDRMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewCIDRMap = $PD.NewCIDRMap | Remove-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewCIDRMap.status.message | Should -Not -BeNullOrEmpty
        }
    }
    
    #------------------ Geo Maps ---------------------#

    Context 'New-GTMGeoMap' {
        It 'creates correctly' {
            $TestParams = @{
                DomainName = $TestDomainName
                MapName    = $TestGeoMapName
                Body       = $TestGeoMap
            }
            $PD.NewGeoMap = New-GTMGeoMap @TestParams @CommonParams
            $PD.NewGeoMap.Name | Should -Be $TestGeoMapName
        }
    }

    Context 'Get-GTMGeoMap - All' {
        It 'returns a list' {
            $PD.GeoMaps = Get-GTMGeoMap -DomainName $TestDomainName @CommonParams
            $PD.GeoMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMGeoMap - Single' {
        It 'returns the correct object' {
            $PD.GeoMap = Get-GTMGeoMap -DomainName $TestDomainName -MapName $TestGeoMapName @CommonParams
            $PD.GeoMap.Name | Should -Be $TestGeoMapName
        }
    }

    Context 'Set-GTMGeoMap by pipeline' {
        It 'updates correctly' {
            $TempGeoMap = $PD.GeoMap.PSObject.Copy()
            $TempGeoMap.Name += '-temp'
            $PD.SetGeoMap = $TempGeoMap | Set-GTMGeoMap -DomainName $TestDomainName -MapName $TempGeoMap.Name @CommonParams
            $PD.SetGeoMap.Name | Should -Be $TempGeoMap.Name
        }
    }

    Context 'Set-GTMGeoMap by param' {
        It 'updates correctly' {
            $PD.SetGeoMapByParam = Set-GTMGeoMap -DomainName $TestDomainName -MapName $PD.SetGeoMap.Name -Body $PD.SetGeoMap @CommonParams
            $PD.SetGeoMapByParam.Name | Should -Be $PD.SetGeoMap.Name
        }
    }

    Context 'Set-GTMGeoMap by json' {
        It 'updates correctly' {
            $PD.SetGeoMapByJson = Set-GTMGeoMap -DomainName $TestDomainName -MapName $PD.SetGeoMap.Name -Body (ConvertTo-Json -Depth 10 $PD.SetGeoMap) @CommonParams
            $PD.SetGeoMapByJson.Name | Should -Be $PD.SetGeoMap.Name
        }
    }

    Context 'Remove-GTMGeoMap' {
        It 'deletes correctly' {
            $PD.RemoveSetGeoMap = Remove-GTMGeoMap -DomainName $TestDomainName -MapName $PD.SetGeoMap.Name @CommonParams
            $PD.RemoveSetGeoMap.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewGeoMap = $PD.NewGeoMap | Remove-GTMGeoMap -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewGeoMap.status.message | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Resources ---------------------#

    Context 'New-GTMResource' {
        It 'creates correctly' {
            $TestParams = @{
                DomainName   = $TestDomainName
                ResourceName = $TestResourceName
                Body         = $TestResource
            }
            $PD.NewResource = New-GTMResource @TestParams @CommonParams
            $PD.NewResource.Name | Should -Be $TestResourceName
        }
    }

    Context 'Get-GTMResource - All' {
        It 'returns a list' {
            $PD.Resources = Get-GTMResource -DomainName $TestDomainName @CommonParams
            $PD.Resources[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMResource - Single' {
        It 'returns the correct object' {
            $PD.Resource = Get-GTMResource -DomainName $TestDomainName -ResourceName $TestResourceName @CommonParams
            $PD.Resource.Name | Should -Be $TestResourceName
        }
    }
    
    Context 'Set-GTMResource by pipeline' {
        It 'updates correctly' {
            $TempResource = $PD.Resource.PSObject.Copy()
            $TempResource.Name += $PD.Resource.Name + '-temp'
            $PD.SetResource = $TempResource | Set-GTMResource -DomainName $TestDomainName -ResourceName $TempResource.Name @CommonParams
            $PD.SetResource.Name | Should -Be $TempResource.Name
        }
    }

    Context 'Set-GTMResource by param' {
        It 'updates correctly' {
            $PD.SetResourceByParam = Set-GTMResource -DomainName $TestDomainName -ResourceName $PD.SetResource.Name -Body $PD.SetResource @CommonParams
            $PD.SetResourceByParam.Name | Should -Be $PD.SetResource.Name
        }
    }

    Context 'Set-GTMResource by json' {
        It 'updates correctly' {
            $PD.SetResourceByJson = Set-GTMResource -DomainName $TestDomainName -ResourceName $PD.SetResource.Name -Body (ConvertTo-Json -Depth 10 $PD.SetResource) @CommonParams
            $PD.SetResourceByJson.Name | Should -Be $PD.SetResource.Name
        }
    }

    Context 'Remove-GTMResource' {
        It 'deletes correctly' {
            $PD.RemoveSetResource = Remove-GTMResource -DomainName $TestDomainName -ResourceName $PD.SetResource.Name @CommonParams
            $PD.RemoveSetResource.status.message | Should -Not -BeNullOrEmpty
            $PD.RemoveNewResource = $PD.NewResource | Remove-GTMResource -DomainName $TestDomainName @CommonParams
            $PD.RemoveNewResource.status.message | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Properties ---------------------#

    Context 'New-GTMProperty' {
        It 'creates correctly' {
            $TestParams = @{
                DomainName   = $TestDomainName
                PropertyName = $TestPropertyName
                Body         = $TestProperty
            }
            $PD.NewProperty = New-GTMProperty @TestParams @CommonParams
            $PD.NewProperty.Name | Should -Be $TestPropertyName
        }
    }

    Context 'Get-GTMProperty - All' {
        It 'returns a list' {
            $PD.Properties = Get-GTMProperty -DomainName $TestDomainName @CommonParams
            $PD.Properties[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMProperty - Single' {
        It 'returns the correct object' {
            $PD.Property = Get-GTMProperty -DomainName $TestDomainName -PropertyName $TestPropertyName @CommonParams
            $PD.Property.Name | Should -Be $TestPropertyName
            $PD.Property.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.Property.Type | Should -Be $PD.NewProperty.Type
        }
    }

    Context 'Set-GTMProperty by pipeline' {
        It 'updates correctly' {
            $PD.SetProperty = $PD.NewProperty | Set-GTMProperty -DomainName $TestDomainName @CommonParams
            $PD.SetProperty.Name | Should -Be $TestPropertyName
            $PD.SetProperty.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetProperty.Type | Should -Be $PD.NewProperty.Type
        }
    }

    Context 'Set-GTMProperty by param' {
        It 'updates correctly' {
            $PD.SetPropertyByParam = Set-GTMProperty -DomainName $TestDomainName -PropertyName $PD.NewProperty.Name -Body $PD.NewProperty @CommonParams
            $PD.SetPropertyByParam.Name | Should -Be $PD.NewProperty.Name
            $PD.SetPropertyByParam.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetPropertyByParam.Type | Should -Be $PD.NewProperty.Type
        }
    }

    Context 'Set-GTMProperty by json' {
        It 'updates correctly' {
            $PD.SetPropertyByJson = Set-GTMProperty -DomainName $TestDomainName -PropertyName $PD.NewProperty.Name -Body (ConvertTo-Json -Depth 10 $PD.NewProperty) @CommonParams
            $PD.SetPropertyByJson.Name | Should -Be $PD.NewProperty.Name
            $PD.SetPropertyByJson.DynamicTTL | Should -Be $PD.NewProperty.DynamicTTL
            $PD.SetPropertyByJson.Type | Should -Be $PD.NewProperty.Type
        }
    }
    
    Context 'Remove-GTMProperty' {
        It 'throws no errors' {
            $PD.NewProperty | Remove-GTMProperty -DomainName $TestDomainName @CommonParams
        }
    }
}

Describe 'Unsafe Akamai.GTM Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.GTM/Akamai.GTM.psd1 -Force
        
        $TestLoadDataRequest = @"
{"domain":"$TestDomainName","datacenterId":1,"resource":"connections","current-load":20,"target-load":25,"max-load":30,"timestamp":"2023-06-07T17:38:53.188Z"}
"@
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.GTM"
        $PD = @{}
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
    }

    Context 'Get-GTMLivenessTestError - All' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessTestError.json"
                return $Response | ConvertFrom-Json
            }
            $LivenessErrors = Get-GTMLivenessTestError
            $LivenessErrors[0].errorCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLivenessTestError - Specific' {
        It 'returns the correct data' {
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


