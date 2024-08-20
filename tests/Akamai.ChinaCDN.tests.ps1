
Describe 'Safe Akamai.ChinaCDN Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.ChinaCDN/Akamai.ChinaCDN.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $testHostname = $env:PesterHostname
        $TestEdgeHostname = $env:PesterHostname
        $TestDeprovisionPolicy = @{
            'unmapSharedEdgeHostname' = $true
        }
        $TestICPNumber = 123
        $TestNewHostname = @"
{
  "hostname": "www.example.com",
  "icpNumberId": 456,
  "serviceCategory": 13,
  "comments": "Testing"
}
"@ | ConvertFrom-Json
        $TestStateChange = @"
{
  "edgeHostname": "www.example.com.edgesuite.net",
  "hostname": "www.example.com",
  "targetState": "PROVISIONED"
}
"@ | ConvertFrom-Json


        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.ChinaCDN"
        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 HoldingEntities
    #------------------------------------------------

    Context 'Get-ChinaCDNHoldingEntities' {
        It 'returns a list of holding entities' {
            $PD.HoldingEntities = Get-ChinaCDNHoldingEntities @CommonParams
            $PD.HoldingEntities[0].id | Should -Not -BeNullOrEmpty
            $PD.HoldingEntities[0].legalId | Should -Not -BeNullOrEmpty
            $PD.HoldingEntities[0].name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ICPNumbers
    #------------------------------------------------

    Context 'Get-ChinaCDNICPNumbers' {
        It 'returns a list of ICP numbers' {
            $PD.ICP = Get-ChinaCDNICPNumbers @CommonParams
            $PD.ICP[0].id | Should -Not -BeNullOrEmpty
            $PD.ICP[0].icpNumber | Should -Not -BeNullOrEmpty
            $PD.ICP[0].icpHoldingEntityId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 EdgeHostnames
    #------------------------------------------------

    Context 'Get-ChinaCDNEdgeHostnames' {
        It 'returns a list of edge hostnames' {
            $PD.EHN = Get-ChinaCDNEdgeHostnames @CommonParams
            $PD.EHN[0].edgeHostname | Should -Not -BeNullOrEmpty
            $PD.EHN[0].status | Should -Not -BeNullOrEmpty
            $PD.EHN[0].unmapSharedEdgeHostname | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 DeprovisionPolicy
    #------------------------------------------------

    Context 'Get-ChinaCDNDeprovisionPolicy' {
        It 'returns the correct data' {
            $TestParams = @{
                EdgeHostname = $TestEdgeHostname
            }
            $PD.DeprovisionPolicy = Get-ChinaCDNDeprovisionPolicy @TestParams @CommonParams
            $PD.DeprovisionPolicy.unmapSharedEdgeHostname | Should -Be $false
        }
    }

    Context 'Set-ChinaCDNDeprovisionPolicy, body, by parameter' {
        It 'updates correctly' {
            $TestParams = @{
                Body         = $TestDeprovisionPolicy
                EdgeHostname = $TestEdgeHostname
            }
            $PD.SetDeprovisionPolicy = Set-ChinaCDNDeprovisionPolicy @TestParams @CommonParams
            $PD.SetDeprovisionPolicy.unmapSharedEdgeHostname | Should -Be $true
        }
    }

    Context 'Set-ChinaCDNDeprovisionPolicy, body, by pipeline' {
        It 'updates correctly' {
            $TestParams = @{
                EdgeHostname = $TestEdgeHostname
            }
            $PD.SetDeprovisionPolicyPipeline = $TestDeprovisionPolicy | Set-ChinaCDNDeprovisionPolicy @TestParams @CommonParams
            $PD.SetDeprovisionPolicyPipeline.unmapSharedEdgeHostname | Should -Be $true
        }
    }

    Context 'Set-ChinaCDNDeprovisionPolicy, attributes' {
        It 'updates correctly' {
            $TestParams = @{
                EdgeHostname            = $TestEdgeHostname
                UnmapSharedEdgeHostname = $false
            }
            $PD.SetDeprovisionPolicyPipelineAttributes = Set-ChinaCDNDeprovisionPolicy @TestParams @CommonParams
            $PD.SetDeprovisionPolicyPipelineAttributes.unmapSharedEdgeHostname | Should -Be $false
        }
    }

    #------------------------------------------------
    #                 Groups
    #------------------------------------------------

    Context 'Get-ChinaCDNGroups' {
        It 'returns a list of groups' {
            $PD.Groups = Get-ChinaCDNGroups @CommonParams
            $PD.Groups[0].groupId | Should -Not -BeNullOrEmpty
            $PD.Groups[0].groupName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ProvisionStates
    #------------------------------------------------

    Context 'Get-ChinaCDNProvisionStates' {
        It 'returns a list of provision states' {
            $PD.ProvisionStates = Get-ChinaCDNProvisionStates @CommonParams
            $PD.ProvisionStates.hostname | Should -Not -BeNullOrEmpty
            $PD.ProvisionStates.partnerStates | Should -Not -BeNullOrEmpty
            $PD.ProvisionStates.provisionState | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 PropertyHostname
    #------------------------------------------------

    Context 'Get-ChinaCDNPropertyHostname, all' {
        It 'returns a list of hostnames' {
            $PD.Hostnames = Get-ChinaCDNPropertyHostname @CommonParams
            $PD.Hostnames.count | Should -BeGreaterThan 1
            $PD.Hostnames[0].hostname | Should -Not -BeNullOrEmpty
            $PD.Hostnames[0].icpNumberId | Should -Not -BeNullOrEmpty
            $PD.Hostnames[0].serviceCategory | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-ChinaCDNPropertyHostname, single' {
        It 'returns the specific hostname' {
            $PD.Hostname = Get-ChinaCDNPropertyHostname @CommonParams
            $PD.Hostname.hostname | Should -Not -BeNullOrEmpty
            $PD.Hostname.icpNumberId | Should -Not -BeNullOrEmpty
            $PD.Hostname.serviceCategory | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-ChinaCDNPropertyHostname, by parameter' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ChinaCDNPropertyHostname.json"
                return $Response | ConvertFrom-Json
            }

            $TestParams = @{
                Comments        = 'Powershell testing'
                ICPNumberID     = $TestICPNumber
                GroupID         = $TestGroupID
                Hostname        = $testHostname
                ServiceCategory = 24
            }
            $NewHostname = New-ChinaCDNPropertyHostname @TestParams @CommonParams
            $NewHostname.Hostname | Should -Not -BeNullOrEmpty
            $NewHostname.ICPNumberID | Should -Not -BeNullOrEmpty
            $NewHostname.Comments | Should -Not -BeNullOrEmpty
            $NewHostname.ServiceCategory | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'New-ChinaCDNPropertyHostname, body' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ChinaCDNPropertyHostname.json"
                return $Response | ConvertFrom-Json
            }

            $TestParams = @{
                GroupID = 123456
            }
            $NewHostname = $TestNewHostname | New-ChinaCDNPropertyHostname @TestParams @CommonParams
            $NewHostname.Hostname | Should -Not -BeNullOrEmpty
            $NewHostname.ICPNumberID | Should -Not -BeNullOrEmpty
            $NewHostname.Comments | Should -Not -BeNullOrEmpty
            $NewHostname.ServiceCategory | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ProvisionStateChange
    #------------------------------------------------

    Context 'Get-ChinaCDNProvisionStateChange, all' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ChinaCDNProvisionStateChange_1.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                Hostname = $TestHostname
            }
            $StateChange = Get-ChinaCDNProvisionStateChange @TestParams @CommonParams
            $StateChange.count | Should -BeGreaterThan 1
            $StateChange[0].id | Should -Not -BeNullOrEmpty
            $StateChange[0].currentStatus | Should -Not -BeNullOrEmpty
            $StateChange[0].hostname | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-ChinaCDNProvisionStateChange, single' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-ChinaCDNProvisionStateChange.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                Hostname = $TestHostname
                ChangeID = 64
            }
            $StateChange = Get-ChinaCDNProvisionStateChange @TestParams @CommonParams
            $StateChange.id | Should -Not -BeNullOrEmpty
            $StateChange.currentStatus | Should -Not -BeNullOrEmpty
            $StateChange.hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-ChinaCDNProvisionStateChange by parameter' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ChinaCDNProvisionStateChange.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                Body     = $TestStateChange
                Hostname = $TestHostname
            }
            $NewStateChange = New-ChinaCDNProvisionStateChange @TestParams @CommonParams
            $NewStateChange.id | Should -Not -BeNullOrEmpty
            $NewStateChange.currentStatus | Should -Not -BeNullOrEmpty
            $NewStateChange.hostname | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-ChinaCDNProvisionStateChange by pipeline' {
        It 'updates correctly' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.ChinaCDN -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-ChinaCDNProvisionStateChange.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                Hostname = $TestHostname
            }
            $NewStateChange = $TestStateChange | New-ChinaCDNProvisionStateChange @TestParams @CommonParams
            $NewStateChange.id | Should -Not -BeNullOrEmpty
            $NewStateChange.currentStatus | Should -Not -BeNullOrEmpty
            $NewStateChange.hostname | Should -Not -BeNullOrEmpty
        }
    }
}
