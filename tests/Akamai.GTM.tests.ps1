Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.GTM/Akamai.GTM.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestDomainName = $env:PesterGTMDomain
$Script:LoadDataRequest = @"
{"domain":"$TestDomainName","datacenterId":1,"resource":"connections","current-load":20,"target-load":25,"max-load":30,"timestamp":"2023-06-07T17:38:53.188Z"}
"@

Describe 'Safe GTM Tests' {
    BeforeDiscovery {
    }

    #------------------ Domains ---------------------#

    ### Get-GTMDomain - All
    $Script:Domains = Get-GTMDomain -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDomain returns a list' {
        $Domains[0].name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMDomain - Single
    $Script:Domain = Get-GTMDomain -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDomain returns the right config' {
        $Domain.name | Should -Be $TestDomainName
    }

    ### Set-GTMDomain by pipeline
    $Script:SetDomainByPipeline = $Domain | Set-GTMDomain -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDomain by pipeline returns the correct data' {
        $SetDomainByPipeline.Status.Message | Should -Not -BeNullOrEmpty
    }

    ### Set-GTMDomain by param
    $Script:SetDomainByParam = Set-GTMDomain -DomainName $TestDomainName -Body $Domain -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDomain by param returns the correct data' {
        $SetDomainByParam.Status.Message | Should -Not -BeNullOrEmpty
    }

    ### Set-GTMDomain by json
    $Script:SetDomainByJson = Set-GTMDomain -DomainName $TestDomainName -Body (ConvertTo-Json -Depth 10 $Domain) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDomain by json returns the correct data' {
        $SetDomainByJson.Status.Message | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMDomainStatus
    $Script:Status = Get-GTMDomainStatus -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDomainStatus returns the right data' {
        $Status.message | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMDomainHistory
    $Script:History = Get-GTMDomainHistory -DomainName $TestDomainName -PageSize 1 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDomainHistory returns the right data' {
        $History.metadata.pageSize | Should -Be 1
    }

    #------------------ AS Maps ---------------------#

    ### Get-GTMASMap - All
    $Script:ASMaps = Get-GTMASMap -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMASMap returns a list' {
        $ASMaps[0].Name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMASMap - Single
    $Script:ASMap = Get-GTMASMap -DomainName $TestDomainName -MapName $ASMaps[0].Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMASMap returns a list' {
        $ASMap.Name | Should -Be $ASMaps[0].Name
    }

    ### Set-GTMASMap by pipeline
    $Script:SetASMapByPipeline = $ASMap | Set-GTMASMap -DomainName $TestDomainName -MapName $ASMap.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMASMap by pipeline returns the correct data' {
        $SetASMapByPipeline.Name | Should -Be $ASMap.Name
    }

    ### Set-GTMASMap by param
    $Script:SetASMapByParam = Set-GTMASMap -DomainName $TestDomainName -MapName $ASMap.Name -Body $ASMap -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMASMap by param returns the correct data' {
        $SetASMapByParam.Name | Should -Be $ASMap.Name
    }

    ### Set-GTMASMap by json
    $Script:SetASMapByJson = Set-GTMASMap -DomainName $TestDomainName -MapName $ASMap.Name -Body (ConvertTo-Json -Depth 10 $ASMap) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMASMap by json returns the correct data' {
        $SetASMapByJson.Name | Should -Be $ASMap.Name
    }

    $TempASMap = $ASMap.PSObject.Copy()
    $TempASMap.Name = $ASMap.Name + '-temp'

    ### New-GTMASMap
    $Script:NewASMap = New-GTMASMap -DomainName $TestDomainName -MapName $TempASMap.Name -Body $TempASMap -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-GTMASMap creates correctly' {
        $NewASMap.Name | Should -Be $TempASMap.Name
    }

    ### Remove-GTMASMap
    $Script:RemoveASMap = Remove-GTMASMap -DomainName $TestDomainName -MapName $TempASMap.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-GTMASMap deletes correctly' {
        $RemoveASMap.status.message | Should -Not -BeNullOrEmpty
    }

    #------------------ Datacenters ---------------------#

    ### Get-GTMDatacenter - All
    $Script:Datacenters = Get-GTMDatacenter -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDatacenter returns a list' {
        $Datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMDatacenter - Single
    $Script:Datacenter = Get-GTMDatacenter -DomainName $TestDomainName -DatacenterID $Datacenters[0].datacenterId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMDatacenter returns a list' {
        $Datacenter.datacenterId | Should -Be $Datacenters[0].datacenterId
    }

    ### Set-GTMDatacenter by pipeline
    $Script:SetDatacenterByPipeline = $Datacenter | Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $Datacenter.datacenterId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDatacenter by pipeline returns the correct data' {
        $SetDatacenterByPipeline.datacenterId | Should -Be $Datacenter.datacenterId
    }

    ### Set-GTMDatacenter by param
    $Script:SetDatacenterByParam = Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $Datacenter.datacenterId -Body $Datacenter -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDatacenter by param returns the correct data' {
        $SetDatacenterByParam.datacenterId | Should -Be $Datacenter.datacenterId
    }

    ### Set-GTMDatacenter by json
    $Script:SetDatacenterByJson = Set-GTMDatacenter -DomainName $TestDomainName -DatacenterID $Datacenter.datacenterId -Body (ConvertTo-Json -Depth 10 $Datacenter) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMDatacenter by json returns the correct data' {
        $SetDatacenterByJson.datacenterId | Should -Be $Datacenter.datacenterId
    }

    $TempDatacenter = $Datacenter.PSObject.Copy()
    $TempDatacenter.NickName = $Datacenter.NickName + '-temp'

    ### New-GTMDatacenter
    $Script:NewDatacenter = New-GTMDatacenter -DomainName $TestDomainName -Body $TempDatacenter -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-GTMDatacenter creates correctly' {
        $NewDatacenter.NickName | Should -Be $TempDatacenter.NickName
    }

    ### Remove-GTMDatacenter
    $Script:RemoveDatacenter = Remove-GTMDatacenter -DomainName $TestDomainName -DatacenterID $NewDatacenter.datacenterId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-GTMDatacenter deletes correctly' {
        $RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
    }

    #------------------ CIDR Map ---------------------#

    ### Get-GTMCIDRMap - All
    $Script:CIDRMaps = Get-GTMCIDRMap -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMCIDRMap returns a list' {
        $CIDRMaps[0].Name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMCIDRMap - Single
    $Script:CIDRMap = Get-GTMCIDRMap -DomainName $TestDomainName -MapName $CIDRMaps[0].Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMCIDRMap returns a list' {
        $CIDRMap.Name | Should -Be $CIDRMaps[0].Name
    }

    ### Set-GTMCIDRMap by pipeline
    $Script:SetCIDRMapByPipeline = $CIDRMap | Set-GTMCIDRMap -DomainName $TestDomainName -MapName $CIDRMap.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMCIDRMap by pipeline returns the correct data' {
        $SetCIDRMapByPipeline.Name | Should -Be $CIDRMap.Name
    }

    ### Set-GTMCIDRMap by param
    $Script:SetCIDRMapByParam = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $CIDRMap.Name -Body $CIDRMap -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMCIDRMap by param returns the correct data' {
        $SetCIDRMapByParam.Name | Should -Be $CIDRMap.Name
    }

    ### Set-GTMCIDRMap by json
    $Script:SetCIDRMapByJson = Set-GTMCIDRMap -DomainName $TestDomainName -MapName $CIDRMap.Name -Body (ConvertTo-Json -Depth 10 $CIDRMap) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMCIDRMap by json returns the correct data' {
        $SetCIDRMapByJson.Name | Should -Be $CIDRMap.Name
    }

    $TempDatacenter = $Datacenter.PSObject.Copy()
    $TempDatacenter.NickName = $Datacenter.NickName + '-temp'

    ### New-GTMDatacenter
    $Script:NewDatacenter = New-GTMDatacenter -DomainName $TestDomainName -Body $TempDatacenter -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-GTMDatacenter creates correctly' {
        $NewDatacenter.NickName | Should -Be $TempDatacenter.NickName
    }

    ### Remove-GTMDatacenter
    $Script:RemoveDatacenter = Remove-GTMDatacenter -DomainName $TestDomainName -DatacenterID $NewDatacenter.datacenterId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-GTMDatacenter deletes correctly' {
        $RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
    }

    #------------------ Geo Maps ---------------------#

    ### Get-GTMGeoMap - All
    $Script:GeoMaps = Get-GTMGeoMap -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMGeoMap returns a list' {
        $GeoMaps[0].Name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMGeoMap - Single
    $Script:GeoMap = Get-GTMGeoMap -DomainName $TestDomainName -MapName $GeoMaps[0].Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMGeoMap returns a list' {
        $GeoMap.Name | Should -Be $GeoMaps[0].Name
    }

    ### Set-GTMGeoMap by pipeline
    $Script:SetGeoMapByPipeline = $GeoMap | Set-GTMGeoMap -DomainName $TestDomainName -MapName $GeoMap.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMGeoMap by pipeline returns the correct data' {
        $SetGeoMapByPipeline.Name | Should -Be $GeoMap.Name
    }

    ### Set-GTMGeoMap by param
    $Script:SetGeoMapByParam = Set-GTMGeoMap -DomainName $TestDomainName -MapName $GeoMap.Name -Body $GeoMap -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMGeoMap by param returns the correct data' {
        $SetGeoMapByParam.Name | Should -Be $GeoMap.Name
    }

    ### Set-GTMGeoMap by json
    $Script:SetGeoMapByJson = Set-GTMGeoMap -DomainName $TestDomainName -MapName $GeoMap.Name -Body (ConvertTo-Json -Depth 10 $GeoMap) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMGeoMap by json returns the correct data' {
        $SetGeoMapByJson.Name | Should -Be $GeoMap.Name
    }

    #------------------ Properties ---------------------#

    ### Get-GTMProperty - All
    $Script:Properties = Get-GTMProperty -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMProperty returns a list' {
        $Properties[0].Name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMProperty - Single
    $Script:Property = Get-GTMProperty -DomainName $TestDomainName -PropertyName $Properties[0].Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMProperty returns a list' {
        $Property.Name | Should -Be $Properties[0].Name
    }

    ### Set-GTMProperty by pipeline
    $Script:SetPropertyByPipeline = $Property | Set-GTMProperty -DomainName $TestDomainName -PropertyName $Property.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMProperty by pipeline returns the correct data' {
        $SetPropertyByPipeline.Name | Should -Be $Property.Name
    }

    ### Set-GTMProperty by param
    $Script:SetPropertyByParam = Set-GTMProperty -DomainName $TestDomainName -PropertyName $Property.Name -Body $Property -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMProperty by param returns the correct data' {
        $SetPropertyByParam.Name | Should -Be $Property.Name
    }

    ### Set-GTMProperty by json
    $Script:SetPropertyByJson = Set-GTMProperty -DomainName $TestDomainName -PropertyName $Property.Name -Body (ConvertTo-Json -Depth 10 $Property) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMProperty by json returns the correct data' {
        $SetPropertyByJson.Name | Should -Be $Property.Name
    }

    #------------------ Resources ---------------------#

    ### Get-GTMResource - All
    $Script:Resources = Get-GTMResource -DomainName $TestDomainName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMResource returns a list' {
        $Resources[0].Name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMResource - Single
    $Script:Resource = Get-GTMResource -DomainName $TestDomainName -ResourceName $Resources[0].Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-GTMResource returns a list' {
        $Resource.Name | Should -Be $Resources[0].Name
    }

    ### Set-GTMResource by pipeline
    $Script:SetResourceByPipeline = $Resource | Set-GTMResource -DomainName $TestDomainName -ResourceName $Resource.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMResource by pipeline returns the correct data' {
        $SetResourceByPipeline.Name | Should -Be $Resource.Name
    }

    ### Set-GTMResource by param
    $Script:SetResourceByParam = Set-GTMResource -DomainName $TestDomainName -ResourceName $Resource.Name -Body $Resource -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMResource by param returns the correct data' {
        $SetResourceByParam.Name | Should -Be $Resource.Name
    }

    ### Set-GTMResource by json
    $Script:SetResourceByJson = Set-GTMResource -DomainName $TestDomainName -ResourceName $Resource.Name -Body (ConvertTo-Json -Depth 10 $Resource) -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-GTMResource by json returns the correct data' {
        $SetResourceByJson.Name | Should -Be $Resource.Name
    }

    $TempResource = $Resource.PSObject.Copy()
    $TempResource.Name = $Resource.Name + '-temp'

    ### New-GTMResource
    $Script:NewDatacenter = New-GTMResource -DomainName $TestDomainName -ResourceName $TempResource.Name -Body $TempResource -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-GTMResource creates correctly' {
        $NewDatacenter.NickName | Should -Be $TempDatacenter.NickName
    }

    ### Remove-GTMResource
    $Script:RemoveResource = Remove-GTMResource -DomainName $TestDomainName -ResourceName $TempResource.Name -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-GTMResource deletes correctly' {
        $RemoveDatacenter.status.message | Should -Not -BeNullOrEmpty
    }


    AfterAll {
    }
    
}

Describe 'Unsafe GTM Tests' {
    ### Get-GTMDatacenterLatency
    $Script:Latency = Get-GTMDatacenterLatency -Domain example.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMDatacenterLatency returns the correct data' {
        $Latency.dataRows[0].latency | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMDemand
    $Script:Demand = Get-GTMDemand -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMDemand returns the correct data' {
        $Demand.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMIPAvailability
    $Script:Availability = Get-GTMIPAvailability -Domain example.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -IP 1.2.3.4 -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMIPAvailability returns the correct data' {
        $Availability.dataRows[0].datacenters[0].IPs[0].ip | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMLivenessPerProperty
    $Script:Liveness = Get-GTMLivenessPerProperty -Domain example.akadns.net -PropertyName www -Date '2021-05-23T01:56:13Z' -AgentIP 209.170.75.251 -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMLivenessPerProperty returns the correct data' {
        $Liveness.dataRows[0].datacenters[0].errorCode | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMLivenessTestError - All
    $Script:LivenessErrors = Get-GTMLivenessTestError -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMLivenessTestError returns the correct data' {
        $LivenessErrors[0].errorCode | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMLivenessTestError - Specific
    $Script:LivenessError = Get-GTMLivenessTestError -ErrorCode 3082 -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMLivenessTestError with specific code returns the correct data' {
        $LivenessError.errorCode | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMLoadFeedbackReport
    $Script:LoadFeedback = Get-GTMLoadFeedbackReport -Domain example.com.akadns.net -Resource MyResource -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMLoadFeedbackReport returns the correct data' {
        $LoadFeedback.dataRows[0].datacenters[0].currentLoad | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMTrafficPerDatacenter
    $Script:TrafficPerDatacenter = Get-GTMTrafficPerDatacenter -Domain example.com.akadns.net -DatacenterID 3200 -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMTrafficPerDatacenter returns the correct data' {
        $TrafficPerDatacenter.dataRows[0].properties[0].name | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMTrafficPerProperty
    $Script:TrafficPerProperty = Get-GTMTrafficPerProperty -Domain example.com.akadns.net -PropertyName www -Start '2021-05-23T01:56:13Z' -End '2021-05-24T01:56:13Z' -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMTrafficPerProperty returns the correct data' {
        $TrafficPerProperty.dataRows[0].datacenters[0].datacenterId | Should -Not -BeNullOrEmpty
    }

    ### Get-GTMLoadData
    $Script:Load = Get-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200 -EdgeRCFile $SafeEdgeRcFile -Section $Section
    it 'Get-GTMLoadData returns the correct data' {
        $Load.'current-load' | Should -Not -BeNullOrEmpty
    }

    ### Set-GTMLoadData
    it 'Set-GTMLoadData returns the correct data' {
        { $LoadDataRequest | Set-GTMLoadData -Domain example.com.akadns.net -Resource MyResource -DatacenterID 3200 -EdgeRCFile $SafeEdgeRcFile -Section $Section } | Should -Not -Throw
    }
}
