Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.EdgeKV/Akamai.EdgeKV.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestGroupID = $env:PesterGroupID
$Script:TestNamespace = $env:PesterEKVNamespace
$Script:TestNamespaceObj = [PSCustomObject] @{
    name               = $TestNameSpace
    retentionInSeconds = 0
    groupId            = $TestGroupID
}
$Script:TestNamespaceBody = $Script:TestNamespaceObj | ConvertTo-Json
$Script:TestTokenName = 'akamaipowershell-testing'
$Script:Tomorrow = (Get-Date).AddDays(7)
$Script:TommorowsDate = Get-Date $Tomorrow -Format yyyy-MM-dd
$Script:NewItemID = 'pester'
$Script:NewItemContent = 'new'
$Script:NewItemObject = [PSCustomObject] @{
    'content' = 'new'
}

Describe 'Safe EdgeKV Tests' {

    BeforeDiscovery {
        
    }

    ### New-EdgeKVAccessToken
    $Script:Token = New-EdgeKVAccessToken -Name $TestTokenName -AllowOnStaging -Expiry $TommorowsDate -Namespace $TestNameSpace -Permissions r -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeKVAccessToken returns list of tokens' {
        $Token.name | Should -Be $TestTokenName
    }

    ### Get-EdgeKVGroup, all
    $Script:Groups = Get-EdgeKVGroup -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVGroup, all returns the correct data' {
        $Groups[0].groupId | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeKVGroup, single
    $Script:Group = Get-EdgeKVGroup -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVGroup, single returns the correct group' {
        $Group.groupId | Should -Be $TestGroupID
    }

    ### Get-EdgeKVInitializationStatus
    $Script:Status = Get-EdgeKVInitializationStatus -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVInitializationStatus returns status' {
        $Status.accountStatus | Should -Be "INITIALIZED"
    }

    ### Get-EdgeKVNamespace, all
    $Script:Namespaces = Get-EdgeKVNamespace -Network STAGING -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVNamespace, all returns list of namespaces' {
        $Namespaces[0].namespace | Should -Not -BeNullOrEmpty
    }

    ### Get-EdgeKVNamespace, single
    $Script:Namespace = Get-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVNamespace, single returns namespace' {
        $Namespace.namespace | Should -Be $TestNamespace
    }

    ### Set-EdgeKVNamespace with attributes
    $Script:SetNamespaceByAttr = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Name $TestNameSpace -RetentionInSeconds 0 -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeKVNamespace returns namespace' {
        $SetNamespaceByAttr.namespace | Should -Be $TestNamespace
    }

    ### Set-EdgeKVNamespace with pipeline
    $Script:SetNamespaceByObj = $TestNamespaceObj | Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeKVNamespace returns namespace' {
        $SetNamespaceByObj.namespace | Should -Be $TestNamespace
    }

    ### Set-EdgeKVNamespace with body
    $Script:SetNamespaceByBody = Set-EdgeKVNamespace -Network STAGING -NamespaceID $TestNamespace -Body $TestNamespaceBody -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-EdgeKVNamespace returns namespace' {
        $SetNamespaceByBody.namespace | Should -Be $TestNamespace
    }

    ### Move-EdgeKVNamespace
    $Script:MoveNamespace = Move-EdgeKVNamespace -NamespaceID $TestNamespace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Move-EdgeKVNamespace returns the correct group' {
        $MoveNamespace.groupId | Should -Be $TestGroupID
    }

    ### Get-EdgeKVAccessToken, all
    $Script:Tokens = Get-EdgeKVAccessToken -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVAccessToken, all returns list of tokens' {
        $Tokens.count | Should -Not -Be 0
    }

    ### Get-EdgeKVAccessToken, single
    $Script:Token = Get-EdgeKVAccessToken -TokenName $TestTokenName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVAccessToken, single returns list of tokens' {
        $Token.name | Should -Be $TestTokenName
    }

    ### New-EdgeKVItem by parameter
    $Script:NewItemByParam = New-EdgeKVItem -ItemID $NewItemID -Value $NewItemContent -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeKVItem by paremeter creates successfully' {
        $NewItemByParam | Should -Match 'Item was upserted in database'
    }
    
    ### New-EdgeKVItem by pipeline
    $Script:NewItemByPipeline = $NewItemObject | New-EdgeKVItem -ItemID $NewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-EdgeKVItem by paremeter creates successfully' {
        $NewItemByPipeline | Should -Match 'Item was upserted in database'
    }

    ### Get-EdgeKVItem, all
    $Script:Items = Get-EdgeKVItem -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVItem, all returns list of items' {
        $Items.count | Should -Not -Be 0
    }

    ### Get-EdgeKVItem, single
    $Script:Item = Get-EdgeKVItem -ItemID $NewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-EdgeKVItem, single returns item data' {
        $Item | Should -Not -BeNullOrEmpty
    }

    ### Remove-EdgeKVAccessToken
    $Script:TokenRemoval = Remove-EdgeKVAccessToken -TokenName $TestTokenName -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-EdgeKVAccessToken removes token successfully' {
        $TokenRemoval.name | Should -Be $TestTokenName
    }

    ### Remove-EdgeKVItem
    $Script:Removal = Remove-EdgeKVItem -ItemID $NewItemID -Network STAGING -NamespaceID $TestNameSpace -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-EdgeKVItem creates successfully' {
        $Removal | Should -Match 'Item was marked for deletion from database'
    }

    AfterAll {
        
    }
    
}

Describe 'Unsafe EdgeKV Tests' {
    ### Initialize-EdgeKV
    $Script:Initialize = Initialize-EdgeKV -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Initialize-EdgeKV does not throw' {
        $Initialize.accountStatus | Should -Not -BeNullOrEmpty
    }

    ### New-EdgeKVNamespace
    $Script:SafeNamespace = New-EdgeKVNamespace -Network PRODUCTION -GeoLocation US -Name $TestNamespace -RetentionInSeconds 0 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-EdgeKVNamespace creates successfully' {
        $SafeNamespace.namespace | Should -Not -BeNullOrEmpty
    }
    
    ### Set-EdgeKVDefaultAccessPolicy
    $Script:SetNamespaceAccess = Set-EdgeKVDefaultAccessPolicy -AllowNamespacePolicyOverride -RestrictDataAccess -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Set-EdgeKVDefaultAccessPolicy updates successfully' {
        $SetNamespaceAccess.dataAccessPolicy.allowNamespacePolicyOverride | Should -Not -BeNullOrEmpty
    }
    
}