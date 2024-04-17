Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.NetworkLists/Akamai.NetworkLists.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestGroupID = $env:PesterGroupID
$Script:TestContract = $env:PesterContractID
$Script:TestListName = 'akamaipowershell-testing'
$Script:TestElement = '1.1.1.1'
$Script:NewTestElements = '2.2.2.2, 3.3.3.3'

Describe 'Safe Network Lists Tests' {

    BeforeDiscovery {
    }

    ### New-NetworkList
    $Script:NewList = New-NetworkList -Name $TestListName -Type IP -Description "testing" -ContractId $TestContract -GroupID $TestGroupID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-NetworkList creates a list successfully' {
        $NewList.name | Should -Be $TestListName
    }

    ### Add-NetworkListElement
    $Script:Add = Add-NetworkListElement -NetworkListID $NewList.uniqueId -Element $TestElement -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Add-NetworkListElement adds element' {
        $Add.list | Should -Contain $TestElement
    }

    ### Get-NetworkList, all
    $Script:NetworkLists = Get-NetworkList -Extended -IncludeElements -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetworkList, all, returns a list of lists' {
        $NetworkLists.count | Should -BeGreaterThan 0
    }

    ### Get-NetworkList, single
    $Script:List = Get-NetworkList -NetworkListID $NewList.uniqueId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-NetworkList returns specific list' {
        $List.name | Should -Be $TestListName
    }

    ### Set-NetworkList by pipeline
    $Script:SetListByPipeline = $Script:List | Set-NetworkList -NetworkListID $NewList.uniqueId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-NetworkList returns successfully' {
        $SetListByPipeline.name | Should -Be $TestListName
    }

    ### Set-NetworkList by body
    $Script:SetListBody = $Script:List | ConvertTo-Json -Depth 100
    $Script:SetListByBody = Set-NetworkList -NetworkListID $NewList.uniqueId -Body $SetListBody -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Set-NetworkList returns successfully' {
        $SetListByBody.name | Should -Be $TestListName
    }

    ### Remove-NetworkListElement
    $Script:Remove = Remove-NetworkListElement -NetworkListID $NewList.uniqueId -Element $TestElement -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-NetworkListElement removes element' {
        $Remove.list | Should -Not -Contain $TestElement
    }

    ### New-NetworkListSubscription
    it 'New-NetworkListSubscription throws no errors' {
        { New-NetworkListSubscription -Recipients mail@example.com -UniquedIDs $NewList.uniqueId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Remove-NetworkListSubscription
    it 'Remove-NetworkListSubscription throws no errors' {
        { Remove-NetworkListSubscription -Recipients mail@example.com -UniquedIDs $NewList.uniqueId -EdgeRCFile $EdgeRCFile -Section $Section } | Should -Not -Throw
    }

    ### Remove-NetworkList
    $Script:Removal = Remove-NetworkList -NetworkListID $NewList.uniqueId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Remove-NetworkList removes given list' {
        $Removal.status | Should -Be 200
        $Removal.uniqueId | Should -Be $NewList.uniqueId
    }
    
    

    AfterAll {
        
    }
    
}

Describe 'Unsafe Network Lists Tests' {
    ### New-NetworkListActivation
    $Script:Activate = New-NetworkListActivation -NetworkListID $NewList.uniqueId -Environment STAGING -Comments "Activating" -NotificationRecipients 'email@example.com' -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-NetworkListActivation activates correctly' {
        $Activate.activationStatus | Should -Not -BeNullOrEmpty
    }

    ### Get-NetworkListActivationStatus
    $Script:Status = Get-NetworkListActivationStatus -NetworkListID $NewList.uniqueId -Environment STAGING -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-NetworkListActivationStatus returns status' {
        $Status.activationStatus | Should -Not -BeNullOrEmpty
    }
    
    ### Get-NetworkListActivation
    $Script:Activation = Get-NetworkListActivation -ActivationID 123456 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-NetworkListActivation returns the correct info' {
        $Status.activationId | Should -Not -BeNullOrEmpty
    }
}