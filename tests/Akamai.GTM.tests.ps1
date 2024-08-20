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
        $PD = @{}
    }

    AfterAll {

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

    #------------------ AS Maps ---------------------#

    Context 'Get-GTMASMap - All' {
        It 'returns a list' {
            $PD.ASMaps = Get-GTMASMap -DomainName $TestDomainName @CommonParams
            $PD.ASMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMASMap - Single' {
        It 'returns a list' {
            $PD.ASMap = Get-GTMASMap -DomainName $TestDomainName -MapName $PD.ASMaps[0].Name @CommonParams
            $PD.ASMap.Name | Should -Be $PD.ASMaps[0].Name
        }
    }
    
    Context 'Set-GTMASMap by pipeline' {
        It 'returns the correct data' {
            $TempASMap = $PD.ASMap.PSObject.Copy()
            $TempASMap.Name += '-temp'
            $PD.NewASMap = $TempASMap | Set-GTMASMap -DomainName $TestDomainName -MapName $TempASMap.Name @CommonParams
            $PD.NewASMap.Name | Should -Be $TempASMap.Name
        }
    }

    Context 'Set-GTMASMap by param' {
        It 'returns the correct data' {
            $PD.SetASMapByParam = Set-GTMASMap -DomainName $TestDomainName -MapName $PD.NewASMap.Name -Body $PD.NewASMap @CommonParams
            $PD.SetASMapByParam.Name | Should -Be $PD.NewASMap.Name
        }
    }

    Context 'Set-GTMASMap by json' {
        It 'returns the correct data' {
            $PD.SetASMapByJson = Set-GTMASMap -DomainName $TestDomainName -MapName $PD.NewASMap.Name -Body (ConvertTo-Json -Depth 10 $PD.NewASMap) @CommonParams
            $PD.SetASMapByJson.Name | Should -Be $PD.NewASMap.Name
        }
    }

    Context 'Remove-GTMASMap' {
        It 'deletes correctly' {
            $PD.RemoveASMap = Remove-GTMASMap -DomainName $TestDomainName -MapName $PD.NewASMap.Name @CommonParams
            $PD.RemoveASMap.status.message | Should -Not -BeNullOrEmpty
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
        It 'returns the correct data' {
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
        It 'returns the correct data' {
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

    #------------------ CIDR Map ---------------------#

    Context 'Get-GTMCIDRMap - All' {
        It 'returns a list' {
            $PD.CIDRMaps = Get-GTMCIDRMap -DomainName $TestDomainName @CommonParams
            $PD.CIDRMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMCIDRMap - Single' {
        It 'returns a list' {
            $PD.CIDRMap = Get-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.CIDRMaps[0].Name @CommonParams
            $PD.CIDRMap.Name | Should -Be $PD.CIDRMaps[0].Name
        }
    }

    Context 'Set-GTMCIDRMap by pipeline' {
        It 'returns the correct data' {
            $TempCIDRMap = $PD.CIDRMap.PSObject.Copy()
            $TempCIDRMap.Name += '-temp'
            $PD.NewCIDRMap = $TempCIDRMap | Set-GTMCIDRMap -DomainName $TestDomainName -MapName $TempCIDRMap.Name @CommonParams
            $PD.NewCIDRMap.Name | Should -Be $TempCIDRMap.Name
        }
    }

    Context 'Set-GTMCIDRMap by param' {
        It 'returns the correct data' {
            $PD.SetCIDRMapByParam = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.NewCIDRMap.Name -Body $PD.NewCIDRMap @CommonParams
            $PD.SetCIDRMapByParam.Name | Should -Be $PD.NewCIDRMap.Name
        }
    }

    Context 'Set-GTMCIDRMap by json' {
        It 'returns the correct data' {
            $PD.SetCIDRMapByJson = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.NewCIDRMap.Name -Body (ConvertTo-Json -Depth 10 $PD.NewCIDRMap) @CommonParams
            $PD.SetCIDRMapByJson.Name | Should -Be $PD.NewCIDRMap.Name
        }
    }

    Context 'Remove-GTMCIDRMap' {
        It 'deletes correctly' {
            $PD.RemoveCIDRMap = Remove-GTMCIDRMap -DomainName $TestDomainName -MapName $PD.NewCIDRMap.Name @CommonParams
            $PD.RemoveCIDRMap.status.message | Should -Not -BeNullOrEmpty
        }
    }
    
    #------------------ Geo Maps ---------------------#

    Context 'Get-GTMGeoMap - All' {
        It 'returns a list' {
            $PD.GeoMaps = Get-GTMGeoMap -DomainName $TestDomainName @CommonParams
            $PD.GeoMaps[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMGeoMap - Single' {
        It 'returns a list' {
            $PD.GeoMap = Get-GTMGeoMap -DomainName $TestDomainName -MapName $PD.GeoMaps[0].Name @CommonParams
            $PD.GeoMap.Name | Should -Be $PD.GeoMaps[0].Name
        }
    }

    Context 'Set-GTMGeoMap by pipeline' {
        It 'returns the correct data' {
            $TempGeoMap = $PD.GeoMap.PSObject.Copy()
            $TempGeoMap.Name += '-temp'
            $PD.NewGeoMap = $TempGeoMap | Set-GTMGeoMap -DomainName $TestDomainName -MapName $TempGeoMap.Name @CommonParams
            $PD.NewGeoMap.Name | Should -Be $TempGeoMap.Name
        }
    }

    Context 'Set-GTMGeoMap by param' {
        It 'returns the correct data' {
            $PD.SetGeoMapByParam = Set-GTMGeoMap -DomainName $TestDomainName -MapName $PD.NewGeoMap.Name -Body $PD.NewGeoMap @CommonParams
            $PD.SetGeoMapByParam.Name | Should -Be $PD.NewGeoMap.Name
        }
    }

    Context 'Set-GTMGeoMap by json' {
        It 'returns the correct data' {
            $PD.SetGeoMapByJson = Set-GTMGeoMap -DomainName $TestDomainName -MapName $PD.NewGeoMap.Name -Body (ConvertTo-Json -Depth 10 $PD.NewGeoMap) @CommonParams
            $PD.SetGeoMapByJson.Name | Should -Be $PD.NewGeoMap.Name
        }
    }

    Context 'Remove-GTMGeoMap' {
        It 'deletes correctly' {
            $PD.RemoveGeoMap = Remove-GTMGeoMap -DomainName $TestDomainName -MapName $PD.NewGeoMap.Name @CommonParams
            $PD.RemoveGeoMap.status.message | Should -Not -BeNullOrEmpty
        }
    }

    #------------------ Properties ---------------------#

    Context 'Get-GTMProperty - All' {
        It 'returns a list' {
            $PD.Properties = Get-GTMProperty -DomainName $TestDomainName @CommonParams
            $PD.Properties[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMProperty - Single' {
        It 'returns a list' {
            $PD.Property = Get-GTMProperty -DomainName $TestDomainName -PropertyName $PD.Properties[0].Name @CommonParams
            $PD.Property.Name | Should -Be $PD.Properties[0].Name
        }
    }

    Context 'Set-GTMProperty by pipeline' {
        It 'returns the correct data' {
            $TempProperty = $PD.Property.PSObject.Copy()
            $TempProperty.Name += '-temp'
            $PD.NewProproperty = $TempProperty | Set-GTMProperty -DomainName $TestDomainName -PropertyName $TempProperty.Name @CommonParams
            $PD.NewProproperty.Name | Should -Be $TempProperty.Name
        }
    }

    Context 'Set-GTMProperty by param' {
        It 'returns the correct data' {
            $PD.SetPropertyByParam = Set-GTMProperty -DomainName $TestDomainName -PropertyName $PD.NewProproperty.Name -Body $PD.NewProproperty @CommonParams
            $PD.SetPropertyByParam.Name | Should -Be $PD.NewProproperty.Name
        }
    }

    Context 'Set-GTMProperty by json' {
        It 'returns the correct data' {
            $PD.SetPropertyByJson = Set-GTMProperty -DomainName $TestDomainName -PropertyName $PD.NewProproperty.Name -Body (ConvertTo-Json -Depth 10 $PD.NewProproperty) @CommonParams
            $PD.SetPropertyByJson.Name | Should -Be $PD.NewProproperty.Name
        }
    }
    
    Context 'Remove-GTMProperty' {
        It 'throws no errors' {
            Remove-GTMProperty -DomainName $TestDomainName -PropertyName $PD.NewProproperty.Name @CommonParams
        }
    }

    #------------------ Resources ---------------------#

    Context 'Get-GTMResource - All' {
        It 'returns a list' {
            $PD.Resources = Get-GTMResource -DomainName $TestDomainName @CommonParams
            $PD.Resources[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMResource - Single' {
        It 'returns a list' {
            $PD.Resource = Get-GTMResource -DomainName $TestDomainName -ResourceName $PD.Resources[0].Name @CommonParams
            $PD.Resource.Name | Should -Be $PD.Resources[0].Name
        }
    }
    
    Context 'Set-GTMResource by pipeline' {
        It 'returns the correct data' {
            $TempResource = $PD.Resource.PSObject.Copy()
            $TempResource.Name += $PD.Resource.Name + '-temp'
            $PD.NewResource = $TempResource | Set-GTMResource -DomainName $TestDomainName -ResourceName $TempResource.Name @CommonParams
            $PD.NewResource.Name | Should -Be $TempResource.Name
        }
    }

    Context 'Set-GTMResource by param' {
        It 'returns the correct data' {
            $PD.SetResourceByParam = Set-GTMResource -DomainName $TestDomainName -ResourceName $PD.NewResource.Name -Body $PD.NewResource @CommonParams
            $PD.SetResourceByParam.Name | Should -Be $PD.NewResource.Name
        }
    }

    Context 'Set-GTMResource by json' {
        It 'returns the correct data' {
            $PD.SetResourceByJson = Set-GTMResource -DomainName $TestDomainName -ResourceName $PD.NewResource.Name -Body (ConvertTo-Json -Depth 10 $PD.NewResource) @CommonParams
            $PD.SetResourceByJson.Name | Should -Be $PD.NewResource.Name
        }
    }

    Context 'Remove-GTMResource' {
        It 'deletes correctly' {
            $PD.RemoveResource = Remove-GTMResource -DomainName $TestDomainName -ResourceName $PD.NewResource.Name @CommonParams
            $PD.RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
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
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMDatacenterLatency.json"
                return $Response | ConvertFrom-Json
            }
            $Latency = Get-GTMDatacenterLatency -Domain example.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $Latency.dataRows[0].latency | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMDemand' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMDemand.json"
                return $Response | ConvertFrom-Json
            }
            $Demand = Get-GTMDemand -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $Demand.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMIPAvailability' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMIPAvailability.json"
                return $Response | ConvertFrom-Json
            }
            $Availability = Get-GTMIPAvailability -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -IP 1.2.3.4
            $Availability.dataRows[0].datacenters[0].IPs[0].ip | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLivenessPerProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessPerProperty.json"
                return $Response | ConvertFrom-Json
            }
            $Liveness = Get-GTMLivenessPerProperty -Domain example.akadns.net -PropertyName www -Date '2021-05-23T01:56:13Z' -AgentIP 209.170.75.251
            $Liveness.dataRows[0].datacenters[0].errorCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLivenessTestError - All' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessTestError.json"
                return $Response | ConvertFrom-Json
            }
            $LivenessErrors = Get-GTMLivenessTestError
            $LivenessErrors[0].errorCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLivenessTestError - Specific' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLivenessTestError.json"
                return $Response | ConvertFrom-Json
            }
            $LivenessError = Get-GTMLivenessTestError -ErrorCode 3082
            $LivenessError.errorCode | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLoadFeedbackReport' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLoadFeedbackReport.json"
                return $Response | ConvertFrom-Json
            }
            $LoadFeedback = Get-GTMLoadFeedbackReport -Domain example.com.akadns.net -Resource MyResource -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $LoadFeedback.dataRows[0].datacenters[0].currentLoad | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMTrafficPerDatacenter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMTrafficPerDatacenter.json"
                return $Response | ConvertFrom-Json
            }
            $TrafficPerDatacenter = Get-GTMTrafficPerDatacenter -Domain example.com.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $TrafficPerDatacenter.dataRows[0].properties[0].name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMTrafficPerProperty' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMTrafficPerProperty.json"
                return $Response | ConvertFrom-Json
            }
            $TrafficPerProperty = Get-GTMTrafficPerProperty -Domain example.com.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z'
            $TrafficPerProperty.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GTMLoadData' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-GTMLoadData.json"
                return $Response | ConvertFrom-Json
            }
            $Load = Get-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200
            $Load.'current-load' | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Submit-GTMLoadData' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Submit-GTMLoadData.json"
                return $Response | ConvertFrom-Json
            }
            $TestLoadDataRequest | Submit-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200 
        }
    }

    Context 'New-GTMDomain' {
        It 'creates successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.GTM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-GTMDomain.json"
                return $Response | ConvertFrom-Json
            }
            $NewDomain = New-GTMDomain -ContractID 1-1AB23C -GroupID 123456 -Body @{ type = 'basic'; name = 'testdomain.akadns.net' }
            $NewDomain.name | Should -Not -BeNullOrEmpty
        }
    }
}


