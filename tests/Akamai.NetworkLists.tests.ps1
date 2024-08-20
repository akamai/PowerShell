Describe 'Safe Akamai.NetworkLists Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.NetworkLists/Akamai.NetworkLists.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestGroupID = $env:PesterGroupID
        $TestContract = $env:PesterContractID
        $TestListName = 'akamaipowershell-testing'
        $TestElement = '1.1.1.1'
        $TestNewElements = '2.2.2.2, 3.3.3.3'
        $PD = @{}
    }

    AfterAll {
        Get-NetworkList @CommonParams | Where-Object name -eq $TestListName | ForEach-Object { Remove-NetworkList -NetworkListID $_.uniqueId @CommonParams }
    }

    Context 'New-NetworkList' {
        It 'creates a list successfully' {
            $PD.NewList = New-NetworkList -Name $TestListName -Type IP -Description "testing" -ContractId $TestContract -GroupID $TestGroupID @CommonParams
            $PD.NewList.name | Should -Be $TestListName
        }
    }

    Context 'Add-NetworkListElement' {
        It 'adds element' {
            $PD.Add = Add-NetworkListElement -NetworkListID $PD.NewList.uniqueId -Element $TestElement @CommonParams
            $PD.Add.list | Should -Contain $TestElement
        }
    }

    Context 'Get-NetworkList, all' {
        It 'returns a list of lists' {
            $PD.NetworkLists = Get-NetworkList -Extended -IncludeElements @CommonParams
            $PD.NetworkLists.count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-NetworkList, single' {
        It 'Get-NetworkList returns specific list' {
            $PD.List = Get-NetworkList -NetworkListID $PD.NewList.uniqueId @CommonParams
            $PD.List.name | Should -Be $TestListName
        }
    }

    Context 'Set-NetworkList by pipeline' {
        It 'Set-NetworkList returns successfully' {
            $PD.SetListByPipeline = $PD.List | Set-NetworkList -NetworkListID $PD.NewList.uniqueId @CommonParams
            $PD.SetListByPipeline.name | Should -Be $TestListName
        }
    }

    Context 'Set-NetworkList by body' {
        It 'Set-NetworkList returns successfully' {
            $PD.SetListByBody = Set-NetworkList -NetworkListID $PD.NewList.uniqueId -Body $PD.List @CommonParams
            $PD.SetListByBody.name | Should -Be $TestListName
        }
    }

    Context 'Remove-NetworkListElement' {
        It 'removes element' {
            $PD.Remove = Remove-NetworkListElement -NetworkListID $PD.NewList.uniqueId -Element $TestElement @CommonParams
            $PD.Remove.list | Should -Not -Contain $TestElement
        }
    }

    Context 'New-NetworkListSubscription' {
        It 'throws no errors' {
            New-NetworkListSubscription -Recipients mail@example.com -UniquedIDs $PD.NewList.uniqueId @CommonParams 
        }
    }

    Context 'Remove-NetworkListSubscription' {
        It 'throws no errors' {
            Remove-NetworkListSubscription -Recipients mail@example.com -UniquedIDs $PD.NewList.uniqueId @CommonParams 
        }
    }

    Context 'Remove-NetworkList' {
        It 'removes given list' {
            $PD.Removal = Remove-NetworkList -NetworkListID $PD.NewList.uniqueId @CommonParams
            $PD.Removal.status | Should -Be 200
            $PD.Removal.uniqueId | Should -Be $PD.NewList.uniqueId
        }
    }
}

Describe 'Unsafe Akamai.NetworkLists Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.NetworkLists/Akamai.NetworkLists.psd1 -Force
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.NetworkLists"
        $PD = @{}
    }
    
    Context 'New-NetworkListActivation' {
        It 'activates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-NetworkListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activate = New-NetworkListActivation -NetworkListID 123_EXAMPLE -Environment STAGING -Comments "Activating" -NotificationRecipients 'email@example.com'
            $Activate.activationStatus | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetworkListActivationStatus' {
        It 'returns status' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetworkListActivationStatus.json"
                return $Response | ConvertFrom-Json
            }
            $Status = Get-NetworkListActivationStatus -NetworkListID 123_EXAMPLE -Environment STAGING
            $Status.activationStatus | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-NetworkListActivation' {
        It 'returns the correct info' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.NetworkLists -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-NetworkListActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Activation = Get-NetworkListActivation -ActivationID 123456
            $Activation.activationId | Should -Not -BeNullOrEmpty
        }
    }
}

