Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.EdgeHostnames/Akamai.EdgeHostnames.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestEHNRecordName = $env:PesterEHNPrefix
$Script:TestEHNDNSZone = 'edgesuite.net'

Describe 'Safe Akamai.EdgeHostnames Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 EdgeHostname                  
    #------------------------------------------------

    ### Get-EdgeHostname - Parameter Set 'all'
    $Script:GetEdgeHostnameAll = Get-EdgeHostname -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeHostname (all) returns the correct data' {
        $GetEdgeHostnameAll[0].id | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeHostname - Parameter Set 'single-components'
    $Script:GetEdgeHostnameSingleComponents = Get-EdgeHostname -RecordName $TestEHNRecordName -DNSZone $TestEHNDNSZone -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeHostname (single-components) returns the correct data' {
        $GetEdgeHostnameSingleComponents.recordName | Should -Be $TestEHNRecordName
    }

    ### Get-EdgeHostname - Parameter Set 'single-id'
    $Script:GetEdgeHostnameSingleId = Get-EdgeHostname -EdgeHostnameID $GetEdgeHostnameSingleComponents.EdgeHostnameID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeHostname (single-id) returns the correct data' {
        $GetEdgeHostnameSingleId.edgeHostnameId | Should -Be $GetEdgeHostnameSingleComponents.EdgeHostnameID
    }

    ### Set-EdgeHostname - Parameter Set 'attributes'
    $Script:SetEdgeHostnameAttributes = Set-EdgeHostname -DNSZone $TestEHNDNSZone -RecordName $TestEHNRecordName -Attribute ttl -Value 60 -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeHostname (attributes) returns the correct data' {
        $SetEdgeHostnameAttributes.edgeHostnames[0].edgeHostnameId | Should -Be
    }

    #------------------------------------------------
    #                 EdgeHostnameLocalizationData                  
    #------------------------------------------------

    ### Get-EdgeHostnameLocalizationData
    $Script:GetEdgeHostnameLocalizationData = Get-EdgeHostnameLocalizationData -Language en_US -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeHostnameLocalizationData returns the correct data' {
        $GetEdgeHostnameLocalizationData.'access-denied-to-dns-zone' | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 EdgeHostnameProduct                  
    #------------------------------------------------

    ### Get-EdgeHostnameProduct
    $Script:GetEdgeHostnameProduct = Get-EdgeHostnameProduct -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeHostnameProduct returns the correct data' {
        $GetEdgeHostnameProduct[0].productId | Should -Not -BeNullOrEmpty
    }


    AfterAll {
        
    }

}


Describe 'Unsafe Akamai.EdgeHostnames Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 EdgeHostnameChangeRequest                  
    #------------------------------------------------

    ### Get-EdgeHostnameChangeRequest - Parameter Set 'single-id'
    $Script:GetEdgeHostnameChangeRequestSingleId = Get-EdgeHostnameChangeRequest -ChangeID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeHostnameChangeRequest (single-id) returns the correct data' {
        $GetEdgeHostnameChangeRequestSingleId.action | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeHostnameChangeRequest - Parameter Set 'single-components'
    $Script:GetEdgeHostnameChangeRequestSingleComponents = Get-EdgeHostnameChangeRequest -DNSZone edgekey.net -RecordName testing -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeHostnameChangeRequest (single-components) returns the correct data' {
        $GetEdgeHostnameChangeRequestSingleComponents[0].action | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeHostnameChangeRequest - Parameter Set 'all'
    $Script:GetEdgeHostnameChangeRequestAll = Get-EdgeHostnameChangeRequest -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeHostnameChangeRequest (all) returns the correct data' {
        $GetEdgeHostnameChangeRequestAll[0].action | Should -Not -BeNullOrEmpty
    }

    ### Set-EdgeHostname - Parameter Set 'postbody'
    $Script:SetEdgeHostnamePostbody = Set-EdgeHostname -Body REPLACEMEWITH_BODY -DNSZone edgekey.net -RecordName testing -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-EdgeHostname (postbody) returns the correct data' {
        $SetEdgeHostnamePostbody.changeId | Should -Be "EDIT"
    }

    ### Remove-EdgeHostname
    $Script:RemoveEdgeHostname = Remove-EdgeHostname -DNSZone edgekey.net -RecordName testing -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Remove-EdgeHostname returns the correct data' {
        $RemoveEdgeHostname.action | Should -Be "DELETE"
    }

    #------------------------------------------------
    #                 EdgeHostnameCertificate                  
    #------------------------------------------------

    ### Get-EdgeHostnameCertificate
    $Script:GetEdgeHostnameCertificate = Get-EdgeHostnameCertificate -DNSZone edgekey.net -RecordName testing -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-EdgeHostnameCertificate returns the correct data' {
        $GetEdgeHostnameCertificate.slotNumber | Should -Not -BeNullOrEmpty
    }

    AfterAll {
        
    }

}