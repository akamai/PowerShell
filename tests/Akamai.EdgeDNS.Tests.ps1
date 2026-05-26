BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'EdgeDNS Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.EdgeDNS'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
    
        function ConvertTo-Base64 {
            [CmdletBinding()]
            Param(
                [Parameter(Mandatory)]
                [string]
                $UnencodedString
            )
    
            Write-Debug "Encoding '$UnencodedString'"
            try {
                $DecodedString = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($UnencodedString))
                return $DecodedString
            }
            catch {
                Write-Debug "Error encoding '$UnencodedString'"
                Write-Debug $_
                return $UnencodedString
            }
        }
    
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
    
        $TestContractId = $env:PesterContractID
        $TestGroupId = $env:PesterGroupID
        $TestProxyName = 'pester'
        $TestProxyID = $env:PesterDNSProxyID
        $TestProxyZoneName = 'pester-proxy.net'
    
        $ExistingZonePrimary = 'primary.pwsh.test'
        $ExistingZoneSecondary = 'secondary.pwsh.test'
    
        $NewZonePrimary = "params-primary-$Timestamp.pwsh.test"
        $NewZoneSecondary = "params-secondary-$Timestamp.pwsh.test"
        $NewZoneAlias = "params-alias-$Timestamp.pwsh.test"
        $NewZoneAlias2 = "params-alias2-$Timestamp.pwsh.test"
        $NewZoneJSON = "json-body-primary-$Timestamp.pwsh.test"
        $NewZoneObject = "object-body-primary-$Timestamp.pwsh.test"
        $NewZonePipelineJSON = "json-pipeline-primary-$Timestamp.pwsh.test"
        $NewZonePipelineObject = "object-pipeline-primary-$Timestamp.pwsh.test"
    
        $SingleRecordName = "newrecord-param-$Timestamp"
        $SingleRecordPipeline = "newrecord-pipeline-$Timestamp"
        $MultiRecordName = "newrecord-body-$Timestamp"
    
        $ConvertZone1 = "convert1-$Timestamp.pwsh.test"
        $ConvertZone2 = "convert2-$Timestamp.pwsh.test"
        $ConvertZone3 = "convert3-$Timestamp.pwsh.test"
        $ConvertZone4 = "convert4-$Timestamp.pwsh.test"
        $ConvertZone5 = "convert5-$Timestamp.pwsh.test"
        $ConvertZone6 = "convert6-$Timestamp.pwsh.test"

        $SecondaryTsig1 = "secondary-tsig-1-$Timestamp.pwsh.test"
        $SecondaryTsig2 = "secondary-tsig-2-$Timestamp.pwsh.test"
    
        $BodyPrimaryObject = [PSCustomObject]@{
            'zone'                  = $NewZonePrimary
            'type'                  = "PRIMARY"
            'endCustomerId'         = "1234567"
            'comment'               = "PWSH Pester Test"
            'signAndServe'          = $true
            'signAndServeAlgorithm' = "ECDSA_P256_SHA256"
        }
    
        $BodySecondaryObject = [PSCustomObject]@{
            'zone'          = $NewZoneSecondary
            'type'          = "SECONDARY"
            'endCustomerId' = "1234567"
            'comment'       = "PWSH Pester Test"
            'masters'       = @(
                "104.237.137.10",
                "45.79.109.10",
                "74.207.225.10",
                "207.192.70.10",
                "109.74.194.10",
                "2600:3c00::a",
                "2600:3c01::a",
                "2600:3c02::a",
                "2600:3c03::a",
                "2a01:7e00::a"
            )
            'tsigKey'       = @{
                'algorithm' = "hmac-md5"
                'name'      = "pwshtest"
                'secret'    = "cHdzaHRlc3Q="
            }
            'signAndServe'  = $false
        }
    
        $BodyAliasObject = [PSCustomObject]@{
            'zone'          = $NewZoneAlias2
            'type'          = "ALIAS"
            'endCustomerID' = 1234567
            'comment'       = "PWSH Pester Test"
            'target'        = $ExistingZonePrimary
        }
    
        $PD = @{}
    }
    
    AfterAll {
        # Remove zones
        Get-EDNSZone @CommonParams | Where-Object { $_.zone.EndsWith("-$Timestamp.pwsh.test") } | Remove-EdnsZone @CommonParams
    
        # Remove proxy zones
        $TestParams = @{
            'ProxyID' = $TestProxyID
        }
        $ProxyZones = Get-EDNSProxyZone @TestParams @CommonParams
        ForEach ($ProxyZone in $ProxyZones) {
            if ($ProxyZone.filterMode -eq 'MANUAL') {
                $TestParams = @{
                    'ProxyID' = $TestProxyID
                    'Name'    = $ProxyZone.Name
                }
                Get-EDNSProxyZoneManualFilterReport @TestParams @CommonParams | Remove-EDNSProxyZoneManualFilterName @TestParams @CommonParams
            }
            $TestParams = @{
                'ProxyID'            = $TestProxyID
                'BypassSafetyChecks' = $true
                'Comment'            = 'cleanup'
            }
            $ProxyZone | Remove-EDNSProxyZone @TestParams @CommonParams
        }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }
    
    Context "Zones" -Tag "Done" {
        Context "New-EDNSZone" {
            It "creates new PRIMARY zone (parameters)" {
                $TestParams = @{
                    'Zone'          = $NewZonePrimary
                    'Type'          = "PRIMARY"
                    'ContractID'    = $TestContractId
                    'GroupID'       = $TestGroupId
                    'Comment'       = "PWSH Pester Test"
                    'EndCustomerID' = 1234567
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZonePrimary
            }
            It "creates new SECONDARY zone (parameters)" {
                $TestParams = @{
                    'Zone'             = $NewZoneSecondary
                    'Type'             = "SECONDARY"
                    'ContractID'       = $TestContractId
                    'GroupID'          = $TestGroupId
                    'Comment'          = "PWSH Pester Test"
                    'EndCustomerID'    = 1234567
                    'Masters'          = @("192.168.10.10", "192.168.10.11")
                    'TSIGKeyAlgorithm' = "hmac-md5"
                    'TSIGKeyName'      = "pwshtest"
                    'TSIGKeySecret'    = "cHdzaHRlc3Q="
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZoneSecondary
            }
            It "Creates new PRIMARY zone from JSON Body (parameters)" {
                $BodyPrimaryObject.Zone = $NewZoneJSON
                $Body = $BodyPrimaryObject | ConvertTo-Json -Depth 5
                $TestParams = @{
                    'ContractID' = $TestContractId
                    'GroupID'    = $TestGroupId
                    'Body'       = $Body
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZoneJSON
            }
            It "Creates new PRIMARY zone from PSObject (parameters)" {
                $BodyPrimaryObject.Zone = $NewZoneObject
                $TestParams = @{
                    'ContractID' = $TestContractId
                    'GroupID'    = $TestGroupId
                    'Body'       = $BodyPrimaryObject
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZoneObject
            }
            It "Creates new PRIMARY zone from JSON (pipeline)" {
                $BodyPrimaryObject.Zone = $NewZonePipelineJSON
                $TestParams = @{
                    'ContractID' = $TestContractId
                    'GroupID'    = $TestGroupId
                }
                $Result = $BodyPrimaryObject | ConvertTo-Json -Depth 5 | New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZonePipelineJSON
            }
            It "Creates new PRIMARY zone from PSObject (pipeline)" {
                $BodyPrimaryObject.Zone = $NewZonePipelineObject
                $TestParams = @{
                    'ContractID' = $TestContractId
                    'GroupID'    = $TestGroupId
                }
                $Result = $BodyPrimaryObject | New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZonePipelineObject
            }
            It "Creates new ALIAS zone (parameters)" {
                $TestParams = @{
                    'Zone'          = $NewZoneAlias
                    'Type'          = "ALIAS"
                    'ContractID'    = $TestContractId
                    'GroupID'       = $TestGroupId
                    'Comment'       = "PWSH Pester Test"
                    'EndCustomerID' = 1234567
                    'Target'        = $ExistingZonePrimary
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZoneAlias
            }
            It 'creates new ALIAS zone (body)' {
                $TestParams = @{
                    'ContractID' = $TestContractId
                    'GroupID'    = $TestGroupId
                    'Body'       = $BodyAliasObject
                }
                $Result = New-EDNSZone @TestParams @CommonParams
                $Result.zone | Should -Be $NewZoneAlias2
            }
            It 'Waits 30s for zones to propagate before running tests' {
                Start-Sleep -Seconds 30
            }
        }
        Context "Get-EDNSZone" {
            It "returns details for all zones (no parameters)" {
                $PD.Zones = Get-EDNSZone @CommonParams
                $PD.Zones.zone | Should -Contain $NewZonePrimary
            }
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $PD.Zone = Get-EDNSZone @TestParams @CommonParams
                $PD.Zone.zone | Should -Be $NewZonePrimary
            }
            It "returns details for specified zone (pipeline)" {
                $Zone = $PD.Zone | Get-EDNSZone @CommonParams
                $Zone.zone | Should -Be $PD.Zone.zone
            }
        }
        Context "Get-EDNSZoneContract" {
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSZoneContract @TestParams @CommonParams
                $Result.contractId | Should -Contain $TestContractId
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSZoneContract @CommonParams
                $Result.contractId | Should -Contain $TestContractId
            }
        }
        Context "Get-EDNSZoneAlias" {
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $ExistingZonePrimary
                }
                $Result = Get-EDNSZoneAlias @TestParams @CommonParams
                $Result | Should -Contain $NewZoneAlias
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $ExistingZonePrimary | Get-EDNSZoneAlias @CommonParams
                $Result | Should -Contain $NewZoneAlias
            }
        }
        Context "Get-EDNSZoneTransferStatus" {
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $ExistingZoneSecondary
                }
                $Result = Get-EDNSZoneTransferStatus @TestParams @CommonParams
                $Result.zone | Should -Be $ExistingZoneSecondary
                $Result.masters | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $ExistingZoneSecondary | Get-EDNSZoneTransferStatus @CommonParams
                $Result.zone | Should -Be $ExistingZoneSecondary
                $Result.masters | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Get-EDNSSecondarySOA' {
            It 'returns the correct SOA (parameter)' {
                $TestParams = @{
                    'Zone' = $ExistingZoneSecondary
                }
                $PD.SecondarySOA = Get-EDNSSecondarySOA @TestParams @CommonParams
                $PD.SecondarySOA[0].name | Should -Be $ExistingZoneSecondary
                $PD.SecondarySOA[0].soaSerialLock | Should -Match '^[0-9]+$'
            }
            It 'returns the correct SOA (pipeline)' {
                $PD.SecondarySOA = $ExistingZoneSecondary | Get-EDNSSecondarySOA @CommonParams
                $PD.SecondarySOA[0].name | Should -Be $ExistingZoneSecondary
                $PD.SecondarySOA[0].soaSerialLock | Should -Match '^[0-9]+$'
            }
        }
        Context "Get-EDNSZoneDNSSECStatus" {
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $ExistingZonePrimary
                }
                $Result = Get-EDNSZoneDNSSECStatus @TestParams @CommonParams
                $Result.zone | Should -Be $ExistingZonePrimary
                $Result.currentRecords | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $ExistingZonePrimary | Get-EDNSZoneDNSSECStatus @CommonParams
                $Result.zone | Should -Be $ExistingZonePrimary
                $Result.currentRecords | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-EDNSZoneDNSKEY' {
            It 'returns the key data as expected' {
                $TestParams = @{
                    'Zone' = $ExistingZonePrimary
                }
                $Result = Get-EDNSZoneDNSKEY @TestParams @CommonParams
                $Result.name | Should -Be $ExistingZonePrimary
                $Result.type | Should -Be 'DNSKEY'
            }
        }

        Context "Set-EDNSZone" {
            BeforeAll {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Zone = Get-EDNSZone @TestParams @CommonParams
            }
            It "updates settings for specified zone (parameter)" {
                $Zone.endCustomerId = 12321
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Body' = $Zone
                }
                $Result = Set-EDNSZone @TestParams @CommonParams
                $Result.endCustomerId | Should -Be 12321
            }
            It "updates settings for specified zone (pipeline)" {
                $Zone.endCustomerId = 34543
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = $Zone | Set-EDNSZone @TestParams @CommonParams
                $Result.endCustomerId | Should -Be 34543
            }
        }

        Context 'Remove-EdnsZone' {
            It 'deletes a zone by parameter' {
                $TestParams = @{
                    'Zone' = $NewZoneSecondary
                }
                Remove-EDNSZone @TestParams @CommonParams
            }
            It 'deletes a zone by pipeline' {
                $NewZoneJSON | Remove-EDNSZone @CommonParams
            }
            It 'deteles multiple zones by pipeline' {
                $NewZoneAlias, $NewZoneAlias2 | Remove-EDNSZone @CommonParams
            }
        }
    
        Context 'Zone Conversion' -Tag 'Zone Conversion' {
            BeforeAll {
                Write-Host -ForegroundColor Yellow "Creating conversion zones"
                # Create 3 zones: 2 primary, 1 secondary
                $SharedConversionParams = @{
                    'ContractID'    = $TestContractId
                    'GroupID'       = $TestGroupId
                    'Comment'       = "PWSH Pester Test"
                    'EndCustomerID' = 1234567
                }

                $ConvertZone1Params = @{
                    'Zone' = $ConvertZone1
                    'Type' = "PRIMARY"
                }
                New-EDNSZone @ConvertZone1Params @SharedConversionParams @CommonParams
    
                $ConvertZone2Params = @{
                    'Zone' = $ConvertZone2
                    'Type' = "PRIMARY"
                }
                New-EDNSZone @ConvertZone2Params @SharedConversionParams @CommonParams
    
                $ConvertZone3Params = @{
                    'Zone'   = $ConvertZone3
                    'Type'   = "ALIAS"
                    'Target' = $ExistingZonePrimary
                }
                New-EDNSZone @ConvertZone3Params @SharedConversionParams @CommonParams
                
                $ConvertZone1Params = @{
                    'Zone' = $ConvertZone4
                    'Type' = "PRIMARY"
                }
                New-EDNSZone @ConvertZone1Params @SharedConversionParams @CommonParams
    
                $ConvertZone2Params = @{
                    'Zone' = $ConvertZone5
                    'Type' = "PRIMARY"
                }
                New-EDNSZone @ConvertZone2Params @SharedConversionParams @CommonParams
    
                $ConvertZone3Params = @{
                    'Zone'   = $ConvertZone6
                    'Type'   = "ALIAS"
                    'Target' = $ExistingZonePrimary
                }
                New-EDNSZone @ConvertZone3Params @SharedConversionParams @CommonParams
    
                # Create SOA and NS records
                $ConvertZone1 | New-EDNSChangeList @CommonParams
                $ConvertZone2 | New-EDNSChangeList @CommonParams
                $ConvertZone4 | New-EDNSChangeList @CommonParams
                $ConvertZone5 | New-EDNSChangeList @CommonParams
                
                $ConvertZone1 | Submit-EDNSChangeList @CommonParams
                $ConvertZone2 | Submit-EDNSChangeList @CommonParams
                $ConvertZone4 | Submit-EDNSChangeList @CommonParams
                $ConvertZone5 | Submit-EDNSChangeList @CommonParams
    
                $ConvertZone1Status = $ConvertZone1 | Get-EDNSZone @CommonParams
                $ConvertZone2Status = $ConvertZone2 | Get-EDNSZone @CommonParams
                $ConvertZone3Status = $ConvertZone3 | Get-EDNSZone @CommonParams
                $ConvertZone4Status = $ConvertZone4 | Get-EDNSZone @CommonParams
                $ConvertZone5Status = $ConvertZone5 | Get-EDNSZone @CommonParams
                $ConvertZone6Status = $ConvertZone6 | Get-EDNSZone @CommonParams
    
                $Wait = $true
                while ($Wait) {
                    $ConvertZone1Status = $ConvertZone1 | Get-EDNSZone @CommonParams
                    $ConvertZone2Status = $ConvertZone2 | Get-EDNSZone @CommonParams
                    $ConvertZone3Status = $ConvertZone3 | Get-EDNSZone @CommonParams
                    $ConvertZone4Status = $ConvertZone4 | Get-EDNSZone @CommonParams
                    $ConvertZone5Status = $ConvertZone5 | Get-EDNSZone @CommonParams
                    $ConvertZone6Status = $ConvertZone6 | Get-EDNSZone @CommonParams
    
                    if ($ConvertZone1Status.activationState -eq 'ACTIVE' -and $ConvertZone2Status.activationState -eq 'ACTIVE' -and $ConvertZone3Status.activationState -eq 'ACTIVE' -and $ConvertZone4Status.activationState -eq 'ACTIVE' -and $ConvertZone5Status.activationState -eq 'ACTIVE' -and $ConvertZone6Status.activationState -eq 'ACTIVE') {
                        $Wait = $false
                    }
                    else {
                        Write-Host -ForegroundColor Yellow "Waiting 30s for zone creation to complete"
                        Start-Sleep -s 30
                    }
                }
            }
    
            It 'converts to secondary successfully (parameter)' {
                $TestParams = @{
                    'Zone'             = $ConvertZone1
                    'Masters'          = '1.2.3.4'
                    'Comment'          = 'Converted by Pester'
                    'TSIGKeyAlgorithm' = 'hmac-sha256'
                    'TSIGKeyName'      = "convert-tsig-$Timestamp"
                    'TSIGKeySecret'    = ConvertTo-Base64 -UnencodedString 'Better to burn out, than to fade away'
                }
                $PD.ConvertToSecondary = Convert-EDNSZoneToSecondary @TestParams @CommonParams
                $PD.ConvertToSecondary.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToSecondary.expirationDate | Should -Not -BeNullOrEmpty
            }
            
            It 'converts to secondary successfully (pipeline)' {
                $TestParams = @{
                    'Masters'          = '1.2.3.4'
                    'Comment'          = 'Converted by Pester'
                    'TSIGKeyAlgorithm' = 'hmac-sha256'
                    'TSIGKeyName'      = "convert-tsig-$Timestamp"
                    'TSIGKeySecret'    = ConvertTo-Base64 -UnencodedString 'Better to burn out, than to fade away'
                }
                $PD.ConvertToSecondaryPipeline = $ConvertZone4 | Convert-EDNSZoneToSecondary @TestParams @CommonParams
                $PD.ConvertToSecondaryPipeline.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToSecondaryPipeline.expirationDate | Should -Not -BeNullOrEmpty
            }
    
            It 'converts to alias successfully (parameter)' {
                $TestParams = @{
                    'Zone'           = $ConvertZone2
                    'Comment'        = 'Converted by Pester'
                    'TargetZoneName' = $ExistingZonePrimary
                }
                $PD.ConvertToAlias = Convert-EDNSZoneToAlias @TestParams @CommonParams
                $PD.ConvertToAlias.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToAlias.expirationDate | Should -Not -BeNullOrEmpty
            }
            
            It 'converts to alias successfully (pipeline)' {
                $TestParams = @{
                    'Comment'        = 'Converted by Pester'
                    'TargetZoneName' = $ExistingZonePrimary
                }
                $PD.ConvertToAliasPipeline = $ConvertZone5 | Convert-EDNSZoneToAlias @TestParams @CommonParams
                $PD.ConvertToAliasPipeline.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToAliasPipeline.expirationDate | Should -Not -BeNullOrEmpty
            }
    
            It 'converts to primary successfully (parameter)' {
                $TestParams = @{
                    'Zone'    = $ConvertZone3
                    'Comment' = 'Converted by Pester'
                }
                $PD.ConvertToPrimary = Convert-EDNSZoneToPrimary @TestParams @CommonParams
                $PD.ConvertToPrimary.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToPrimary.expirationDate | Should -Not -BeNullOrEmpty
            }
            
            It 'converts to primary successfully (pipeline)' {
                $TestParams = @{
                    'Comment' = 'Converted by Pester'
                }
                $PD.ConvertToPrimaryPipeline = $ConvertZone6 | Convert-EDNSZoneToPrimary @TestParams @CommonParams
                $PD.ConvertToPrimaryPipeline.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToPrimaryPipeline.expirationDate | Should -Not -BeNullOrEmpty
            }
    
            Context 'Get-EDNSConvertStatus' {
                It 'returns conversion status' {
                    $Wait = $true
                    while ($Wait) {
                        $PD.ZoneConvert1Status = $PD.ConvertToSecondary | Get-EDNSConvertStatus @CommonParams
                        $PD.ZoneConvert2Status = $PD.ConvertToAlias | Get-EDNSConvertStatus @CommonParams
                        $PD.ZoneConvert3Status = $PD.ConvertToPrimary | Get-EDNSConvertStatus @CommonParams
                        $PD.ZoneConvert4Status = $PD.ConvertToSecondaryPipeline | Get-EDNSConvertStatus @CommonParams
                        $PD.ZoneConvert5Status = $PD.ConvertToAliasPipeline | Get-EDNSConvertStatus @CommonParams
                        $PD.ZoneConvert6Status = $PD.ConvertToPrimaryPipeline | Get-EDNSConvertStatus @CommonParams
    
                        if ($PD.ZoneConvert1Status.isComplete -and $PD.ZoneConvert2Status.isComplete -and $PD.ZoneConvert3Status.isComplete -and $PD.ZoneConvert4Status.isComplete -and $PD.ZoneConvert5Status.isComplete -and $PD.ZoneConvert6Status.isComplete) {
                            $Wait = $false
                        }
                        else {
                            Write-Debug "Waiting 30s for zone conversion to complete"
                            Start-Sleep -Seconds 30
                        }
                    }
    
                    $PD.ZoneConvert1Status.requestId | Should -Be $PD.ConvertToSecondary.requestId
                    $PD.ZoneConvert1Status.isComplete | Should -Be $true
                    $PD.ZoneConvert2Status.requestId | Should -Be $PD.ConvertToAlias.requestId
                    $PD.ZoneConvert2Status.isComplete | Should -Be $true
                    $PD.ZoneConvert3Status.requestId | Should -Be $PD.ConvertToPrimary.requestId
                    $PD.ZoneConvert3Status.isComplete | Should -Be $true
                    $PD.ZoneConvert4Status.requestId | Should -Be $PD.ConvertToSecondaryPipeline.requestId
                    $PD.ZoneConvert4Status.isComplete | Should -Be $true
                    $PD.ZoneConvert5Status.requestId | Should -Be $PD.ConvertToAliasPipeline.requestId
                    $PD.ZoneConvert5Status.isComplete | Should -Be $true
                    $PD.ZoneConvert6Status.requestId | Should -Be $PD.ConvertToPrimaryPipeline.requestId
                    $PD.ZoneConvert6Status.isComplete | Should -Be $true
                }
            }
    
            Context 'Get-EDNSConvertResult for secondary' {
                It 'returns conversion result (parameter)' {
                    $TestParams = @{
                        'RequestID' = $PD.ConvertToSecondary.requestId
                    }
                    $PD.ZoneConvertSecondaryResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertSecondaryResult.requestId | Should -Be $PD.ConvertToSecondary.requestId
                    $PD.ZoneConvertSecondaryResult.successfullyConvertedZones | Should -Contain $ConvertZone1
                }
                It 'returns conversion result (pipeline)' {
                    $ZoneConvertSecondaryResult = $PD.ConvertToSecondary | Get-EDNSConvertResult @CommonParams
                    $ZoneConvertSecondaryResult.requestId | Should -Be $PD.ConvertToSecondary.requestId
                    $ZoneConvertSecondaryResult.successfullyConvertedZones | Should -Contain $ConvertZone1
                }
            }
    
            Context 'Get-EDNSConvertResult for alias' {
                It 'returns conversion result (parameter)' {
                    $TestParams = @{
                        'RequestID' = $PD.ConvertToAlias.requestId
                    }
                    $PD.ZoneConvertAliasResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertAliasResult.requestId | Should -Be $PD.ConvertToAlias.requestId
                    $PD.ZoneConvertAliasResult.successfullyConvertedZones | Should -Contain $ConvertZone2
                }
                It 'returns conversion result (pipeline)' {
                    $ZoneConvertAliasResult = $PD.ConvertToAlias | Get-EDNSConvertResult @CommonParams
                    $ZoneConvertAliasResult.requestId | Should -Be $PD.ConvertToAlias.requestId
                    $ZoneConvertAliasResult.successfullyConvertedZones | Should -Contain $ConvertZone2
                }
            }
    
            Context 'Get-EDNSConvertResult for primary' {
                It 'returns conversion result (parameter)' {
                    $TestParams = @{
                        'RequestID' = $PD.ConvertToPrimary.requestId
                    }
                    $PD.ZoneConvertPrimaryResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertPrimaryResult.requestId | Should -Be $PD.ConvertToPrimary.requestId
                    $PD.ZoneConvertPrimaryResult.successfullyConvertedZones | Should -Contain $ConvertZone3
                }
                It 'returns conversion result (pipeline)' {
                    $ZoneConvertPrimaryResult = $PD.ConvertToPrimary | Get-EDNSConvertResult @CommonParams
                    $ZoneConvertPrimaryResult.requestId | Should -Be $PD.ConvertToPrimary.requestId
                    $ZoneConvertPrimaryResult.successfullyConvertedZones | Should -Contain $ConvertZone3
                }
            }
    
            AfterAll {
                $TestParams = @{
                    'BypassSafetyChecks' = $true
                }
                $ConvertZone1, $ConvertZone2, $ConvertZone3, $ConvertZone4, $ConvertZone5, $ConvertZone6 | Remove-EDNSZone @TestParams @CommonParams
            }
        }
    }
    
    Context "Change Lists" -Tag "Done" {
        Context "New-EDNSChangeList" {
            It "creates a new changelist (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = New-EDNSChangeList @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeList" {
            It "returns details for all changelists" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeList @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeList @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSChangeList @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListSettings" {
            It "returns changelist details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeListSettings @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSChangeListSettings @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSChangeListSettings" {
            It "updates changelist with specified zone settings (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Settings = Get-EDNSChangeListSettings @TestParams @CommonParams
                $Settings.endCustomerID = 77777
                $Result = $Settings | Set-EDNSChangeListSettings @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSet" {
            It "returns all changelist record sets for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeListRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all changelist record sets for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSChangeListRecordSet @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record sets of selected type for specified zone (parameter)" {
                $TestParams = @{
                    'Zone'  = $NewZonePrimary
                    'Types' = 'NS', 'SOA'
                }
                $Result = Get-EDNSChangeListRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record sets of selected type for specified zone (pipeline)" {
                $TestParams = @{
                    'Types' = 'NS', 'SOA'
                }
                $Result = $PD.Zone | Get-EDNSChangeListRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSetNames" {
            It "returns changelist record set names for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeListRecordSetNames @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record set names for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSChangeListRecordSetNames @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSetTypes" {
            It "returns changelist record set types for specified zone and record name (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = $NewZonePrimary
                }
                $Result = Get-EDNSChangeListRecordSetTypes @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record set types for specified zone and record name (pipeline)" {
                $TestParams = @{
                    'Name' = $NewZonePrimary
                }
                $Result = $PD.Zone | Get-EDNSChangeListRecordSetTypes @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSChangeListRecordSet" {
            It "modifies record set for a changelist (parameter)" {
                $RecordSetName = "changelist.$NewZonePrimary"
                $Result = Set-EDNSChangeListRecordSet @CommonParams -Zone $NewZonePrimary -Name $RecordSetName -Type TXT -Op ADD -TTL 60 -RData "Pester testing @ $Timestamp"
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListDiff" {
            It "shows changes between current changelist and active record set" {
                $Result = Get-EDNSChangeListDiff @CommonParams -Zone $NewZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Find-EDNSChangeList' {
            It 'returns the correct change list' {
                $PD.FindChangeList = Find-EDNSChangeList -Zone $NewZonePrimary @CommonParams
                $PD.FindChangeList[0].zone | Should -Be $NewZonePrimary
                $PD.FindChangeList[0].zoneVersionId | Should -Not -BeNullOrEmpty
            }
        }
        Context "Submit-EDNSChangeList" {
            It "submits changelist (paramter)" {
                $Result = Submit-EDNSChangeList @CommonParams -Zone $NewZonePrimary
                $Result | Should -BeNullOrEmpty
                Start-Sleep -Seconds 2
            }
        }
        Context "Set-EDNSChangeListMasterFile" {
            BeforeAll {
                New-EDNSChangeList @CommonParams -Zone $NewZonePrimary
            }
            It "uploads master zone file to changelist (paramter)" {
                $ZoneFile = Get-EDNSMasterFile @CommonParams -Zone $NewZonePrimary
                $Result = Set-EDNSChangeListMasterFile @CommonParams -Zone $NewZonePrimary -Body $ZoneFile
                $Result | Should -BeNullOrEmpty
            }
            It "uploads master zone file to changelist (pipeline)" {
                $ZoneFile = Get-EDNSMasterFile @CommonParams -Zone $NewZonePrimary
                $Result = $ZoneFile | Set-EDNSChangeListMasterFile @CommonParams -Zone $NewZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Remove-EDNSChangeList" {
            It "removes an existing changelist (parameter)" {
                $Result = Remove-EDNSChangeList @CommonParams -Zone $NewZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
    }
    
    Context "Record Sets" {
        Context "Get-EDNSRecordSetTypes" {
            It "returns all types for specified record set in a zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSRecordSetTypes @TestParams @CommonParams
                $Result | Should -Contain 'A'
                $Result | Should -Contain 'CNAME'
            }
            It "returns all types for specified record set in a zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSRecordSetTypes @CommonParams
                $Result | Should -Contain 'A'
                $Result | Should -Contain 'CNAME'
            }
        }
        Context "New-EDNSRecordSet" {
            It "creates a record set in the specified zone (parameter)" {
                $TestParams = @{
                    'Zone'  = $NewZonePrimary
                    'Name'  = "$SingleRecordName.$NewZonePrimary"
                    'Type'  = 'A'
                    'TTL'   = 60
                    'RData' = '1.1.1.1'
                }
                New-EDNSRecordSet @TestParams @CommonParams
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = "$SingleRecordName.$NewZonePrimary"
                    'Type' = 'A'
                }
                $PD.NewRecord = Get-EDNSRecordSet @TestParams @CommonParams
                $PD.NewRecord.name | Should -Be "$SingleRecordName.$NewZonePrimary"
                $PD.NewRecord.ttl | Should -Be 60
                $PD.NewRecord.Type | Should -Be 'A'
                $PD.NewRecord.rdata | Should -Be @('1.1.1.1')
            }
            It "creates a record set in the specified zone (pipeline)" {
                $NewRecord = [PSCustomObject] @{
                    'name'  = "$SingleRecordPipeline.$NewZonePrimary"
                    'type'  = 'A'
                    'ttl'   = 60
                    'rdata' = @('2.2.2.2')
                }
                $NewRecord | New-EDNSRecordSet -Zone $NewZonePrimary @CommonParams
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = "$SingleRecordPipeline.$NewZonePrimary"
                    'Type' = 'A'
                }
                $PD.NewRecordPipeline = Get-EDNSRecordSet @TestParams @CommonParams
                $PD.NewRecordPipeline.name | Should -Be "$SingleRecordPipeline.$NewZonePrimary"
                $PD.NewRecordPipeline.ttl | Should -Be 60
                $PD.NewRecordPipeline.Type | Should -Be 'A'
                $PD.NewRecordPipeline.rdata | Should -Be @('2.2.2.2')
            }
            It "creates a record set in the specified zone (body)" {
                $Body = @{
                    'recordsets' = @(
                        @{
                            'name'  = "$MultiRecordName.$NewZonePrimary"
                            'rdata' = @('3.3.3.3')
                            'ttl'   = 60
                            'type'  = 'A'
                        }
                        @{
                            'name'  = "$MultiRecordName.$NewZonePrimary"
                            'rdata' = @('AkamaiPowershell')
                            'ttl'   = 60
                            'type'  = 'TXT'
                        }
                    )
                }
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Body' = $Body
                }
                New-EDNSRecordSet @TestParams @CommonParams
                $TestParams = @{
                    'Search' = "$MultiRecordName.$NewZonePrimary"
                    'Zone'   = $NewZonePrimary
                }
                $PD.NewRecords = Get-EDNSRecordSet @TestParams @CommonParams | Sort-Object -Property Type
                $PD.NewRecords[0].name | Should -Be "$MultiRecordName.$NewZonePrimary"
                $PD.NewRecords[0].ttl | Should -Be 60
                $PD.NewRecords[0].Type | Should -Be 'A'
                $PD.NewRecords[0].rdata | Should -Be @('3.3.3.3')
                $PD.NewRecords[1].name | Should -Be "$MultiRecordName.$NewZonePrimary"
                $PD.NewRecords[1].ttl | Should -Be 60
                $PD.NewRecords[1].Type | Should -Be 'TXT'
                $PD.NewRecords[1].rdata | Should -Be @('"AkamaiPowershell"')
            }
            AfterAll {
                Write-Host -ForegroundColor Yellow "Waiting for 30s for record creation to complete..."
                Start-Sleep -Seconds 30
            }
        }
        Context "Get-EDNSRecordSet" {
            It "returns all record sets in a zone (parameter)" {
                $TestParams = @{
                    'zone' = $NewZonePrimary
                }
                $Result = Get-EDNSRecordSet @TestParams @CommonParams
                $Result.name | Should -Contain $NewZonePrimary
                $Result.type | Should -Contain 'SOA'
            }
            It "returns all record sets in a zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSRecordSet @CommonParams
                $Result.name | Should -Contain $NewZonePrimary
                $Result.type | Should -Contain 'SOA'
            }
            It "returns filtered record set for a specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = $NewZonePrimary
                    'Type' = 'NS'
                }
                $Result = Get-EDNSRecordSet @TestParams @CommonParams
                $Result.name | Should -Contain $NewZonePrimary
                $Result.type | Should -Contain 'NS'
            }
        }
        Context "Get-EDNSMasterFile" {
            It "returns whole master file for the specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $PD.MasterFile = Get-EDNSMasterFile @TestParams @CommonParams
                $PD.MasterFile | Should -BeLike "*;; File Generated at *"
            }
            It "returns whole master file for the specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSMasterFile @CommonParams
                $Result | Should -BeLike "*;; File Generated at *"
            }
        }
        Context "Set-EDNSMasterFile" {
            It "uploads an entire zone file without errors (pipeline)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = $NewZonePrimary
                    'Type' = 'SOA'
                }
                $SOA = Get-EDNSRecordSet @TestParams @CommonParams
                $Serial = [int] ($SOA.rdata[0] -split ' ')[2]
                $NewSerial = $Serial + 1
                $NewMasterFile = $PD.MasterFile -replace $Serial, $NewSerial
    
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $NewMasterFile | Set-EDNSMasterFile @TestParams @CommonParams
            }
        }
        Context 'Set-EDNSRecordSet' {
            It "updates a single record set in the specified zone (parameter)" {
                $TestParams = @{
                    'Zone'  = $NewZonePrimary
                    'Name'  = "$SingleRecordName.$NewZonePrimary"
                    'Type'  = 'A'
                    'TTL'   = 60
                    'RData' = '2.2.2.2'
                }
                $PD.SetRecordParam = Set-EDNSRecordSet @TestParams @CommonParams
                $PD.SetRecordParam.name | Should -Be "$SingleRecordName.$NewZonePrimary"
                $PD.SetRecordParam.ttl | Should -Be 60
                $PD.SetRecordParam.Type | Should -Be 'A'
                $PD.SetRecordParam.rdata | Should -Be @('2.2.2.2')
            }
            It "updates a single record set in the specified zone (pipeline)" {
                $PD.SetRecordParam.rdata[0] = '3.3.3.3'
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $PD.SetRecordPipeline = $PD.SetRecordParam | Set-EDNSRecordSet @TestParams @CommonParams
                $PD.SetRecordPipeline.name | Should -Be "$SingleRecordName.$NewZonePrimary"
                $PD.SetRecordPipeline.ttl | Should -Be 60
                $PD.SetRecordPipeline.Type | Should -Be 'A'
                $PD.SetRecordPipeline.rdata | Should -Be @('3.3.3.3')
            }
            It "throws an error when trying to update without incrementing the SOA" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $AllRecordSets = Get-EDNSRecordSet @TestParams @CommonParams
                $TestParams = @{
                    'Zone'    = $NewZonePrimary
                    'Confirm' = $false
                }
                { $AllRecordSets | Set-EDNSRecordSet @TestParams @CommonParams } | Should -throw
            }
            It "replaces all records when set to auto-increment SOA" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $AllRecordSets = Get-EDNSRecordSet @TestParams @CommonParams
                $TestParams = @{
                    'Zone'             = $NewZonePrimary
                    'AutoIncrementSOA' = $true
                    'Confirm'          = $false
                }
                $AllRecordSets | Set-EDNSRecordSet @TestParams @CommonParams
            }
        }
        Context "Remove-EDNSRecordSet" {
            It "removes specified record set from a zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'Name' = $PD.NewRecord.Name
                    'Type' = $PD.NewRecord.Type
                }
                Remove-EDNSRecordSet @TestParams @CommonParams
            }
            It "removes specified record set from a zone (pipeline)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $PD.NewRecords | Remove-EDNSRecordSet @TestParams @CommonParams
                $PD.NewRecordPipeline | Remove-EDNSRecordSet @TestParams @CommonParams
            }
        }
    }
    
    Context "TSIG Keys" -Tag "Done" {
        BeforeAll {
            $Zones = @{
                'zones' = @()
            }
            $BodySecondaryObject.zone = $SecondaryTsig1
            $Zones.zones += $BodySecondaryObject.psobject.Copy()
            $BodySecondaryObject.zone = $SecondaryTsig2
            $Zones.zones += $BodySecondaryObject.psobject.Copy()
            $ZoneCreation = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
            # Wait for creation to complete
            while (-not $Status.isComplete) {
                $TestParams = @{
                    'RequestID' = $ZoneCreation.requestId
                }
                $Status = Get-EDNSZoneBulkCreateStatus @TestParams @CommonParams
                Start-Sleep -Seconds 3
                Write-Host -ForegroundColor Yellow "Waiting for zone creation to complete..."
            }
            Start-Sleep -Seconds 3
        }
        Context "Get-EDNSTSIGKey" {
            It "returns all TSIG keys" {
                $TestParams = @{
                    'Search'      = 'md5'
                    'SortBy'      = 'name'
                    'ContractIDs' = $TestContractId
                }
                $Result = Get-EDNSTSIGKey @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Algorithms = $Result.algoritm | Sort-Object | Get-Unique
                $Algorithms | ForEach-Object {
                    $_.ToLower() | Should -BeLike "hmac-md5*"
                }
            }
            It "returns a TSIG key for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $BodySecondaryObject.zone
                }
                $Result = Get-EDNSTSIGKey @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns a TSIG key for specified zone (pipeline)" {
                $Result = $BodySecondaryObject.zone | Get-EDNSTSIGKey @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSTSIGKey" {
            It "updates TSIG key data for specified zone (parameter)" {
                $TestParams = @{
                    'Zone'             = $BodySecondaryObject.zone
                    'TSIGKeyAlgorithm' = $BodySecondaryObject.TSIGKey.algorithm
                    'TSIGKeyName'      = $BodySecondaryObject.TSIGKey.name
                    'TSIGKeySecret'    = $BodySecondaryObject.TSIGKey.secret
                }
                $Result = Set-EDNSTSIGKey @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for specified zone (pipeline)" {
                $Body = @{
                    'zones' = @($BodySecondaryObject.zone)
                    'key'   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (parameter)" {
                $TestParams = @{
                    'Zone'             = $Zones.zones.zone
                    'TSIGKeyAlgorithm' = $BodySecondaryObject.TSIGKey.algorithm
                    'TSIGKeyName'      = $BodySecondaryObject.TSIGKey.name
                    'TSIGKeySecret'    = $BodySecondaryObject.TSIGKey.secret
                }
                $Result = Set-EDNSTSIGKey @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (pipeline)" {
                $Body = @{
                    'zones' = $Zones.zones.zone
                    'key'   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSTSIGKeyUsedBy" {
            It "returns all zone names using specified TSIG key (parameter)" {
                $TestParams = @{
                    'TSIGKeyAlgorithm' = $BodySecondaryObject.TSIGKey.algorithm
                    'TSIGKeyName'      = $BodySecondaryObject.TSIGKey.name
                    'TSIGKeySecret'    = $BodySecondaryObject.TSIGKey.secret
                }
                $Result = Get-EDNSTSIGKeyUsedBy @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using specified TSIG key (pipeline)" {
                $Result = $BodySecondaryObject.TSIGKey | Get-EDNSTSIGKeyUsedBy @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using the same TSIG key as specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $BodySecondaryObject.zone
                }
                $Result = Get-EDNSTSIGKeyUsedBy @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
        }
        Context 'Get-EDNSTSIGKeyContract' {
            It 'returns in the right format' {
                $TestParams = @{
                    'TSIGKeyAlgorithm' = $BodySecondaryObject.TSIGKey.algorithm
                    'TSIGKeyName'      = $BodySecondaryObject.TSIGKey.name
                    'TSIGKeySecret'    = $BodySecondaryObject.TSIGKey.secret
                }
                $PD.TSIGKeyContract = Get-EDNSTSIGKeyContract @TestParams @CommonParams
                $PD.TSIGKeyContract.contractId | Should -Be $TestContractID
                $PD.TSIGKeyContract.zoneNames.zones | Should -Contain $BodySecondaryObject.zone
            }
        }
        Context "Remove-EDNSTSIGKey" {
            It "removes the TSIG key for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $Zones.zones.zone[0]
                }
                $Result = Remove-EDNSTSIGKey @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "removes the TSIG key for specified zone (pipeline)" {
                $Result = $Zones.zones.zone[1] | Remove-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        AfterAll {
            $Zones.zones | Remove-EDnsZone -BypassSafetyChecks @CommonParams
        }
    }
    
    Context "Bulk Zone Operations" -Tag "Done" {
        Context "New-EDNSZoneBulkCreate (Single Zone)" {
            BeforeEach {
                $BodyPrimaryObject.zone = "primary-bulk-1-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
            }
            It "creates a new zone creation request (parameter)" {
                $Result = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            AfterEach {
                Start-Sleep -Seconds 3
                $TestParams = @{
                    'Zone'               = $BodyPrimaryObject.zone
                    'BypassSafetyChecks' = $true
                }
                New-EDNSZoneBulkDelete @TestParams @CommonParams
            }
        }
        Context "New-EDNSZoneBulkCreate (Multi Zone)" {
            BeforeEach {
                $Zones = @{
                    'zones' = @()
                }
                $BodyPrimaryObject.zone = "primary-bulk-2-$Timestamp.pwsh.test"
                $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                $BodyPrimaryObject.zone = "primary-bulk-3-$Timestamp.pwsh.test"
                $Zones.zones += $BodyPrimaryObject.psobject.Copy()
            }
            It "creates a new zone creation request (parameter)" {
                $Result = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            AfterEach {
                Start-Sleep -Seconds 3
                New-EDNSZoneBulkDelete @CommonParams -Zone $Zones.zones.zone -BypassSafetyChecks
            }
        }
        Context "Get-EDNSZoneBulkCreateStatus" {
            BeforeAll {
                $BodyPrimaryObject.zone = "primary-bulk-4-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
                $CreateResult = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $TestParams = @{
                    'RequestID' = $CreateResult.requestId
                }
                $Result = Get-EDNSZoneBulkCreateStatus @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EDNSZoneBulkCreateStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                $TestParams = @{
                    'Zone'               = $BodyPrimaryObject.zone
                    'BypassSafetyChecks' = $true
                }
                New-EDNSZoneBulkDelete @TestParams @CommonParams
            }
        }
        Context "Get-EDNSZoneBulkCreateResult" {
            BeforeAll {
                $BodyPrimaryObject.zone = "primary-bulk-5-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
                $CreateResult = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $TestParams = @{
                    'RequestID' = $CreateResult.requestId
                }
                $Result = Get-EDNSZoneBulkCreateResult @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EDNSZoneBulkCreateResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EDNSZoneBulkDelete @CommonParams -Zone $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EDNSZoneBulkDelete (Single zone)" {
            BeforeEach {
                $BodyPrimaryObject.zone = "primary-bulk-6-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $TestParams = @{
                    'Zone' = $BodyPrimaryObject.zone
                }
                $Result = New-EDNSZoneBulkDelete @TestParams @CommonParams
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $BodyPrimaryObject.zone | New-EDNSZoneBulkDelete @CommonParams
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
        }
        Context "New-EDNSZoneBulkDelete (Multi zone)" {
            BeforeEach {
                $Zones = @{
                    'zones' = @()
                }
                $BodyPrimaryObject.zone = "primary-bulk-7-$Timestamp.pwsh.test"
                $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                $BodyPrimaryObject.zone = "primary-bulk-8-$Timestamp.pwsh.test"
                $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                    
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $TestParams = @{
                    'Zone' = $Zones.zones.zone
                }
                $Result = New-EDNSZoneBulkDelete @TestParams @CommonParams
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $Zones.zones.zone | New-EDNSZoneBulkDelete @CommonParams
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
        }
        Context "Get-EDNSZoneBulkDeleteStatus" {
            BeforeAll {
                $BodyPrimaryObject.zone = "primary-bulk-9-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EDNSZoneBulkDelete @CommonParams -Zone $BodyPrimaryObject.zone -BypassSafetyChecks
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $TestParams = @{
                    'RequestID' = $DeleteResult.requestId
                }
                $Result = Get-EDNSZoneBulkDeleteStatus @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EDNSZoneBulkDeleteStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneBulkDeleteResult" {
            BeforeAll {
                $BodyPrimaryObject.zone = "primary-bulk-9-$Timestamp.pwsh.test"
                $Zones = @{
                    'zones' = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EDNSZoneBulkDelete @CommonParams -Zone $BodyPrimaryObject.zone -BypassSafetyChecks
                while (-not $Status.isComplete) {
                    $TestParams = @{
                        'RequestID' = $DeleteResult.requestId
                    }
                    $Status = Get-EDNSZoneBulkDeleteStatus @TestParams @CommonParams
                    Start-Sleep -s 3
                    Write-Host -ForegroundColor Yellow "Waiting for zone deletion to complete..."
                }
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $TestParams = @{
                    'RequestID' = $DeleteResult.requestId
                }
                $Result = Get-EDNSZoneBulkDeleteResult @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EDNSZoneBulkDeleteResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Zone Versions" -Tag "Done" {
        Context "Get-EDNSZoneVersion" {
            It "returns all details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $PD.ZoneVersions = Get-EDNSZoneVersion @TestParams @CommonParams
                $PD.ZoneVersions | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSZoneVersion @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified version id of a zone (parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $PD.ZoneVersions[0].versionid
                }
                $Result = Get-EDNSZoneVersion @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Compare-EDNSZoneVersion" {
            It "returns diff details for specified zone versions (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'From' = $PD.ZoneVersions[0].VersionID
                    'To'   = $PD.ZoneVersions[1].VersionID
                }
                $Result = Compare-EDNSZoneVersion @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns diff details for specified zone versions (pipeline)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                    'To'   = $PD.ZoneVersions[1].VersionID
                }
                $Result = $PD.ZoneVersions[0] | Compare-EDNSZoneVersion @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneVersionRecordSet" {
            It "returns all details for specified zone version (parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                }
                $Result = Get-EDNSZoneVersionRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone version (pipeline)" {
                $TestParams = @{
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                }
                $Result = $PD.Zone | Get-EDNSZoneVersionRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (array, parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                    'Types'     = @('SOA', 'NS')
                    'SortBy'    = @('name', 'type')
                }
                $Result = Get-EDNSZoneVersionRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (string, parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                    'Types'     = @('SOA', 'NS')
                    'SortBy'    = @('name', 'type')
                }
                $Result = Get-EDNSZoneVersionRecordSet @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Restore-EDNSZoneVersion" {
            BeforeAll {
                $Versions = $PD.ZoneVersions | Sort-Object lastActivationDate -Descending
                $OldVersion = $Versions[1]
            }
            It "restores specified zone version (parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $OldVersion.versionId
                }
                $Result = Restore-EDNSZoneVersion @TestParams @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "restores specified zone version (pipeline)" {
                $Result = $OldVersion | Restore-EDNSZoneVersion @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneVersionMasterFile" {
            It "returns Master Zone file for specified zone version (parameter)" {
                $TestParams = @{
                    'Zone'      = $NewZonePrimary
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                }
                $Result = Get-EDNSZoneVersionMasterFile @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline)" {
                $TestParams = @{
                    'VersionID' = $PD.ZoneVersions[0].VersionID
                }
                $Result = $PD.Zone | Get-EDNSZoneVersionMasterFile @TestParams @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline, ByPropertyName)" {
                $Result = $PD.ZoneVersions[0] | Get-EDNSZoneVersionMasterFile @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Data Services" -Tag "Done" {
        Context "Get-EDNSAuthority" {
            It "returns details for specified contract IDs (string, parameter)" {
                $TestParams = @{
                    'ContractID' = $TestContractID
                }
                $Result = Get-EDNSAuthority @TestParams @CommonParams
                $Result.contractId | Should -Be $TestContractID
                $Result.authorities | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (string, pipeline)" {
                $Result = $TestContractID | Get-EDNSAuthority @CommonParams
                $Result.contractId | Should -Be $TestContractID
                $Result.authorities | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSContracts" {
            It "returns details of all contracts" {
                $Result = Get-EDNSContracts @CommonParams
                $Result.contractId | Should -Not -BeNullOrEmpty
                $Result.contractName | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $TestParams = @{
                    'GroupID' = $TestGroupId
                }
                $Result = Get-EDNSContracts @TestParams @CommonParams
                $Result.contractId | Should -Not -BeNullOrEmpty
                $Result.contractName | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract ID (pipeline)" {
                $Result = $TestGroupId | Get-EDNSContracts @CommonParams
                $Result.contractId | Should -Not -BeNullOrEmpty
                $Result.contractName | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSDNSSECAlgorithms" {
            It "returns DNSSEC Algorithm list" {
                $Result = Get-EDNSDNSSECAlgorithms @CommonParams
                $Result | Should -Contain "RSA_SHA1"
            }
        }
        Context "Get-EDNSEdgeHostnames" {
            It "returns Edge hostname list" {
                $Result = Get-EDNSEdgeHostnames @CommonParams
                $Result[0].edgeHostname | Should -Not -BeNullOrEmpty
                $Result[0].supportsZoneApexMapping | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSGroups" {
            It "returns details for all groups" {
                $Result = Get-EDNSGroups @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $TestParams = @{
                    'GroupID' = $TestGroupId
                }
                $Result = Get-EDNSGroups @TestParams @CommonParams
                $Result[0].groupId | Should -Not -BeNullOrEmpty
                $Result[0].groupName | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (pipeline)" {
                $Result = $TestGroupId | Get-EDNSGroups @CommonParams
                $Result[0].groupId | Should -Be $TestGroupId
                $Result[0].groupName | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSRecordSetTypes" {
            It "returns details for specified zone (parameter)" {
                $TestParams = @{
                    'Zone' = $NewZonePrimary
                }
                $Result = Get-EDNSRecordSetTypes @TestParams @CommonParams
                $Result | Should -Contain "A"
                $Result | Should -Contain "CNAME"
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $PD.Zone | Get-EDNSRecordSetTypes @CommonParams
                $Result | Should -Contain "A"
                $Result | Should -Contain "CNAME"
            }
        }
        Context "Get-EDNSTSIGAlgorithms" {
            It "returns TSIG Algorithm list" {
                $Result = Get-EDNSTSIGAlgorithms @CommonParams
                $Result | Should -Contain "hmac-sha256"
                $Result | Should -Contain "hmac-sha384"
            }
        }
    }
    
    Context "Proxies" -Tag "Proxies" {
        Context "Get-EDNSProxy" {
            It "lists alls proxies" {
                $PD.Proxies = Get-EDNSProxy @CommonParams
                $PD.Proxies[0].id | Should -not -BeNullOrEmpty
                $PD.Proxies[0].name | Should -not -BeNullOrEmpty
                $PD.Proxies[0].authorities | Should -not -BeNullOrEmpty
            }
            It 'retrieves a specific proxy (parameter)' {
                $TestParams = @{
                    'ProxyID' = $TestProxyID
                }
                $PD.Proxy = Get-EDNSProxy @TestParams @CommonParams
                $PD.Proxy.id | Should -Be $TestProxyID
                $PD.Proxy.name | Should -Be $TestProxyName
                $PD.Proxy.authorities | Should -not -BeNullOrEmpty
            }
            It 'retrieves a specific proxy (pipeline)' {
                $Proxy = $PD.Proxy | Get-EDNSProxy @CommonParams
                $Proxy.id | Should -Be $TestProxyID
                $Proxy.name | Should -Be $TestProxyName
                $Proxy.authorities | Should -not -BeNullOrEmpty
            }
        }
    
        Context 'Set-EDNSProxy' {
            It 'updates correctly using the pipeline' {
                $PD.UpdateProxyByPipeline = $PD.Proxy | Set-EDNSProxy @CommonParams
                $PD.UpdateProxyByPipeline.id | Should -Be $TestProxyID
                $PD.UpdateProxyByPipeline.name | Should -Be $TestProxyName
            }
    
            It 'updates correctly using parameters' {
                $TestParams = @{
                    'ProxyID' = $PD.Proxy.ID
                    'Body'    = $PD.Proxy | ConvertTo-Json
                }
                $PD.UpdateProxyByParams = Set-EDNSProxy @TestParams @CommonParams
                $PD.UpdateProxyByParams.id | Should -Be $TestProxyID
                $PD.UpdateProxyByParams.name | Should -Be $TestProxyName
            }
        }
    
        Context 'Get-EDNSProxyHealthcheckRecordTypes' {
            It 'lists health check record types' {
                $PD.hcrecords = Get-EDNSProxyHealthcheckRecordTypes @CommonParams
                $PD.hcrecords | Should -Contain 'A'
                $PD.hcrecords | Should -Contain 'AAAA'
                $PD.hcrecords | Should -Contain 'CNAME'
            }
        }
    
        Context 'Proxy Zones' {
            Context 'New-EDNSProxyZone' {
                It 'creates successfully by attributes' {
                    $TestParams = @{
                        'ProxyID'    = $PD.Proxy.Id
                        'Name'       = "powershell-test1-$Timestamp.test"
                        'FilterMode' = 'MANUAL'
                    }
                    $PD.NewProxyZoneAttribute = New-EDNSProxyZone @TestParams @CommonParams
                    $PD.NewProxyZoneAttribute.requestId | Should -Not -BeNullOrEmpty
                    $PD.NewProxyZoneAttribute.expirationDate | Should -Not -BeNullOrEmpty
                }
                It 'creates successfully by body' {
                    $Body = @{
                        'proxyZones' = @(
                            @{
                                'name'       = "powershell-test2-$Timestamp.test"
                                'filterMode' = 'NONE'
                            }
                            @{
                                'name'       = "powershell-test3-$Timestamp.test"
                                'filterMode' = 'AUTOMATIC'
                                'tsigKey'    = @{
                                    'name'      = "powershell-tsig1-$Timestamp"
                                    'algorithm' = 'hmac-sha256'
                                    'secret'    = (ConvertTo-Base64 -UnencodedString "This is a super-secret secret!")
                                }
                            }
                        )
                    }
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.Id
                        'Body'    = $Body
                    }
                    $PD.NewProxyZoneBody = New-EDNSProxyZone @TestParams @CommonParams
                    $PD.NewProxyZoneBody.requestId | Should -Not -BeNullOrEmpty
                    $PD.NewProxyZoneBody.expirationDate | Should -Not -BeNullOrEmpty
                }
            }
    
            Context 'Get-EDNSProxyZoneCreateStatus' {
                It 'returns the correct data (parameter)' {
                    $TestParams = @{
                        'ProxyID'   = $PD.Proxy.Id
                        'RequestID' = $PD.NewProxyZoneBody.requestId
                    }
                    $PD.ProxyZoneCreateStatus = Get-EDNSProxyZoneCreateStatus @TestParams @CommonParams
                    $PD.ProxyZoneCreateStatus.requestId | Should -Be $PD.NewProxyZoneBody.requestId
                    $PD.ProxyZoneCreateStatus.zonesSubmitted | Should -Be 2
                    $PD.ProxyZoneCreateStatus.isComplete | Should -Not -BeNullOrEmpty
    
                    while ($PD.ProxyZoneCreateStatus.isComplete -ne $true) {
                        Start-Sleep -s 15
                        $PD.ProxyZoneCreateStatus = Get-EDNSProxyZoneCreateStatus @TestParams @CommonParams
                    }
                }
                
                It 'returns the correct data (parameter)' {
                    $TestParams = @{
                        'RequestID' = $PD.NewProxyZoneBody.requestId
                    }
                    $ProxyZoneCreateStatus = $PD.Proxy | Get-EDNSProxyZoneCreateStatus @TestParams @CommonParams
                    $ProxyZoneCreateStatus.requestId | Should -Be $PD.NewProxyZoneBody.requestId
                    $ProxyZoneCreateStatus.zonesSubmitted | Should -Be 2
                    $ProxyZoneCreateStatus.isComplete | Should -Not -BeNullOrEmpty
                }
            }
    
            Context 'Get-EDNSProxyZoneCreateResult' {
                It 'returns the correct data (parameter)' {
                    $TestParams = @{
                        'ProxyID'   = $PD.Proxy.Id
                        'RequestID' = $PD.NewProxyZoneBody.requestId
                    }
                    $PD.ProxyZoneCreateResult = Get-EDNSProxyZoneCreateResult @TestParams @CommonParams
                    $PD.ProxyZoneCreateResult.requestId | Should -Be $PD.NewProxyZoneBody.requestId
                    $PD.ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test2-$Timestamp.test"
                    $PD.ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test3-$Timestamp.test"
                }
                It 'returns the correct data (pipeline)' {
                    $TestParams = @{
                        'RequestID' = $PD.NewProxyZoneBody.requestId
                    }
                    $ProxyZoneCreateResult = $PD.Proxy | Get-EDNSProxyZoneCreateResult @TestParams @CommonParams
                    $ProxyZoneCreateResult.requestId | Should -Be $PD.NewProxyZoneBody.requestId
                    $ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test2-$Timestamp.test"
                    $ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test3-$Timestamp.test"
                }
            }
    
            Context 'Get-EDNSProxyZone' {
                It 'returns a list of zones (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.Id
                    }
                    $PD.ProxyZones = Get-EDNSProxyZone @TestParams @CommonParams | Where-Object { $_.Name -like "*-$Timestamp.test" }
                    $PD.ProxyZones.count | Should -Be 3
                    $PD.ProxyZones[0].Name | Should -Not -BeNullOrEmpty
                    $PD.ProxyZones[0].filterMode | Should -Not -BeNullOrEmpty
                }
                It 'retrieves a single proxy zone by name (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.Id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    $PD.ProxyZone = Get-EDNSProxyZone @TestParams @CommonParams
                    $PD.ProxyZone.name | Should -Be $PD.ProxyZones[0].Name
                    $PD.ProxyZone.filterMode | Should -Be $PD.ProxyZones[0].filterMode
                }
                It 'retrieves a single proxy zone by name (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[0].Name
                    }
                    $PD.ProxyZone = $PD.Proxy | Get-EDNSProxyZone @TestParams @CommonParams
                    $PD.ProxyZone.name | Should -Be $PD.ProxyZones[0].Name
                    $PD.ProxyZone.filterMode | Should -Be $PD.ProxyZones[0].filterMode
                }
            }
            Context 'Get-EDNSProxyZone' {
                It 'returns a list of zones (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.Id
                    }
                    $PD.ProxyZones = Get-EDNSProxyZone @TestParams @CommonParams
                    $PD.ProxyZones.count | Should -Be 3
                    $PD.ProxyZones[0].Name | Should -Not -BeNullOrEmpty
                    $PD.ProxyZones[0].filterMode | Should -Not -BeNullOrEmpty
                }
                It 'returns a list of zones (pipeline)' {
                    $ProxyZones = $PD.Proxy | Get-EDNSProxyZone @CommonParams
                    $ProxyZones.count | Should -Be 3
                    $ProxyZones[0].Name | Should -Not -BeNullOrEmpty
                    $ProxyZones[0].filterMode | Should -Not -BeNullOrEmpty
                }
                It 'retrieves a single proxy zone by name (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.Id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    $PD.ProxyZone = Get-EDNSProxyZone @TestParams @CommonParams
                    $PD.ProxyZone.name | Should -Be $PD.ProxyZones[0].Name
                    $PD.ProxyZone.filterMode | Should -Be $PD.ProxyZones[0].filterMode
                }
                It 'retrieves a single proxy zone by name (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[0].Name
                    }
                    $PD.ProxyZone = $PD.Proxy | Get-EDNSProxyZone @TestParams @CommonParams
                    $PD.ProxyZone.name | Should -Be $PD.ProxyZones[0].Name
                    $PD.ProxyZone.filterMode | Should -Be $PD.ProxyZones[0].filterMode
                }
            }

            Context 'Set-EDNSProxyZoneTSIGKey' {
                It 'updates correctly (parameter)' {
                    $TestParams = @{
                        'ProxyID'          = $PD.Proxy.Id
                        'Name'             = $PD.ProxyZones[2].Name
                        'TSIGKeyAlgorithm' = 'hmac-sha256'
                        'TSIGKeyName'      = "powershell-tsig2-$Timestamp"
                        'TSIGKeySecret'    = ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!"
                    }
                    Set-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                }
                It 'updates correctly (pipeline)' {
                    $TestParams = @{
                        'Name'             = $PD.ProxyZones[2].Name
                        'TSIGKeyAlgorithm' = 'hmac-sha256'
                        'TSIGKeyName'      = "powershell-tsig2-$Timestamp"
                        'TSIGKeySecret'    = ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!"
                    }
                    $PD.Proxy | Set-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                }
            }
    
            Context 'Get-EDNSProxyZoneTSIGKey' {
                It 'retrieves the keys correctly (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIG = Get-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                    $PD.ProxyZoneTSIG.name | Should -Be "powershell-tsig2-$Timestamp"
                    $PD.ProxyZoneTSIG.algorithm | Should -Be 'hmac-sha256'
                    $PD.ProxyZoneTSIG.secret | Should -Be (ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!")
                }
                It 'retrieves the keys correctly (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIG = $PD.Proxy | Get-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                    $PD.ProxyZoneTSIG.name | Should -Be "powershell-tsig2-$Timestamp"
                    $PD.ProxyZoneTSIG.algorithm | Should -Be 'hmac-sha256'
                    $PD.ProxyZoneTSIG.secret | Should -Be (ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!")
                }
            }
    
            Context 'Get-EDNSProxyZoneTSIGKeyUsedBy' {
                It 'retrieves the keys correctly (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIGUsedBy = Get-EDNSProxyZoneTSIGKeyUsedBy @TestParams @CommonParams
                    $PD.ProxyZoneTSIGUsedBy.name | Should -Be $TestProxyName
                    $PD.ProxyZoneTSIGUsedBy.id | Should -Be $TestProxyID
                }
                It 'retrieves the keys correctly (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIGUsedBy = $PD.Proxy | Get-EDNSProxyZoneTSIGKeyUsedBy @TestParams @CommonParams
                    $PD.ProxyZoneTSIGUsedBy.name | Should -Be $TestProxyName
                    $PD.ProxyZoneTSIGUsedBy.id | Should -Be $TestProxyID
                }
            }
    
            Context 'Remove-EDNSProxyZoneTSIGKey' {
                It 'removes successfully' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[2].Name
                    }
                    Remove-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                }
            }
    
            Context 'Add-EDNSProxyZoneManualFilterName' {
                It 'adds a filter name correctly' {
                    $TestParams = @{
                        'ProxyID'     = $PD.Proxy.id
                        'Name'        = $PD.ProxyZones[0].Name
                        'FilterNames' = @(
                            "newfiltername1.$($PD.ProxyZones[0].Name)"
                            "newfiltername2.$($PD.ProxyZones[0].Name)"
                            "newfiltername3.$($PD.ProxyZones[0].Name)"
                        )
                    }
                    $PD.ZoneAddFilterName = Add-EDNSProxyZoneManualFilterName @TestParams @CommonParams
                    $PD.ZoneAddFilterName.addCount | Should -Be 3
                    $PD.ZoneAddFilterName.deleteCount | Should -Be 0
                }
            }
    
            Context 'Set-EDNSProxyZoneManualFilterNames' {
                It 'removes a filter name correctly' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[0].Name
                        'Body'    = @{
                            'add'    = @(
                                "addfiltername1.$($PD.ProxyZones[0].Name)"
                                "addfiltername2.$($PD.ProxyZones[0].Name)"
                            )
                            'delete' = @(
                                "newfiltername3.$($PD.ProxyZones[0].Name)"
                            )
                        }
                    }
                    $PD.ZoneRemoveFilterName = Set-EDNSProxyZoneManualFilterNames @TestParams @CommonParams
                    $PD.ZoneRemoveFilterName.deleteCount | Should -Be 1
                    $PD.ZoneRemoveFilterName.addCount | Should -Be 2
                }
            }
    
            Context 'Get-EDNSProxyZoneManualFilterReport' {
                It 'lists manual filters (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    $PD.ManualFilters = Get-EDNSProxyZoneManualFilterReport @TestParams @CommonParams
                    $PD.ManualFilters[0] | Should -BeLike '*filtername*'
                }
                It 'lists manual filters (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[0].Name
                    }
                    $PD.ManualFilters = $PD.Proxy | Get-EDNSProxyZoneManualFilterReport @TestParams @CommonParams
                    $PD.ManualFilters[0] | Should -BeLike '*filtername*'
                }
            }
    
            Context 'Remove-EDNSProxyZoneManualFilterName' {
                It 'removes a filter name correctly' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    $PD.ZoneRemoveFilterName = $PD.ManualFilters | Remove-EDNSProxyZoneManualFilterName @TestParams @CommonParams
                    $PD.ZoneRemoveFilterName.deleteCount | Should -Be 4
                    $PD.ZoneRemoveFilterName.addCount | Should -Be 0
                }
            }
    
            Context 'Set-EDNSProxyZoneManualFilterNames' {
                BeforeAll {
                    $ZoneFile = "TestDrive:/zonefile"
                    # Set zone file contents
                    $ZoneContents = @"
`$TTL 2d    ; default TTL for zone
`$ORIGIN $($PD.ProxyZones[0].Name). ; base domain-name
@         IN      SOA   ns1.example.com. hostmaster.example.com. (
                                2003080800 ; serial number
                                12h        ; refresh
                                15m        ; update retry
                                3w         ; expiry
                                2h         ; minimum
                                )
ns1        IN      A       1.2.3.4
mail       IN      A       1.2.3.4
joe        IN      A       1.2.3.4
www        IN      A       1.2.3.4
ftp        IN      A       1.2.3.4
"@
                    $ZoneContents | Out-File $ZoneFile
                }
                It 'sets filter names from a zone file (parameter)' {
                    $TestParams = @{
                        'ProxyID'  = $PD.Proxy.id
                        'Name'     = $PD.ProxyZones[0].Name
                        'ZoneFile' = $ZoneFile
                    }
                    $PD.ZoneFilterFromFile = Set-EDNSProxyZoneManualFilterNames @TestParams @CommonParams
                    $PD.ZoneFilterFromFile.deleteCount | Should -Be 0
                    $PD.ZoneFilterFromFile.addCount | Should -Be 6
                }
                It 'sets filter names from a zone file (pipeline)' {
                    $TestParams = @{
                        'Name'     = $PD.ProxyZones[0].Name
                        'ZoneFile' = $ZoneFile
                    }
                    $PD.ZoneFilterFromFile = $PD.Proxy | Set-EDNSProxyZoneManualFilterNames @TestParams @CommonParams
                    $PD.ZoneFilterFromFile.deleteCount | Should -Be 0
                    $PD.ZoneFilterFromFile.addCount | Should -Be 0
                }
                AfterAll {
                    $RemoveParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    Get-EDNSProxyZoneManualFilterReport @RemoveParams @CommonParams | Remove-EDNSProxyZoneManualFilterName @RemoveParams @CommonParams
                }
            }
    
            Context 'Set-EDNSProxyZoneApexAlias' {
                It 'creates an apex successfully (parameter)' {
                    $TestParams = @{
                        'ProxyID'   = $PD.Proxy.id
                        'Name'      = $PD.ProxyZones[0].Name
                        'ApexAlias' = "apex.$($PD.ProxyZones[0].Name)"
                    }
                    Set-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }
    
            Context 'Remove-EDNSProxyZoneApexAlias' {
                It 'creates an apex successfully (parameter)' {
                    $TestParams = @{
                        'ProxyID' = $PD.Proxy.id
                        'Name'    = $PD.ProxyZones[0].Name
                    }
                    Remove-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }

            Context 'Set-EDNSProxyZoneApexAlias' {
                It 'updates an apex successfully (pipeline)' {
                    $TestParams = @{
                        'Name'      = $PD.ProxyZones[0].Name
                        'ApexAlias' = "apex2.$($PD.ProxyZones[0].Name)"
                    }
                    $PD.Proxy | Set-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }
    
            Context 'Remove-EDNSProxyZoneApexAlias' {
                It 'creates an apex successfully (pipeline)' {
                    $TestParams = @{
                        'Name' = $PD.ProxyZones[0].Name
                    }
                    $PD.Proxy | Remove-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }
    
            Context 'Convert-EDNSProxyZone' {
                Context 'to manual' {
                    It 'converts successfully' {
                        $TestParams = @{
                            'ProxyID'           = $PD.Proxy.id
                            'Mode'              = 'MANUAL'
                            'Name'              = $PD.ProxyZones[1].Name
                            'ManualFilterNames' = "conversion.$($PD.ProxyZones[1].Name)"
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
    
                Context 'to automatic' {
                    It 'converts successfully' {
                        $TestParams = @{
                            'ProxyID'          = $PD.Proxy.id
                            'Mode'             = 'AUTOMATIC'
                            'Name'             = $PD.ProxyZones[1].Name
                            'TSIGKeyAlgorithm' = 'hmac-sha256'
                            'TSIGKeyName'      = "conversion-key1-$Timestamp"
                            'TSIGKeySecret'    = ConvertTo-Base64 -UnencodedString 'there can be only one'
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
    
                Context 'to all' {
                    It 'converts successfully' {
                        $TestParams = @{
                            'ProxyID' = $PD.Proxy.id
                            'Mode'    = 'ALL'
                            'Name'    = $PD.ProxyZones[1].Name
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
    
                Context 'to none' {
                    It 'converts successfully' {
                        $TestParams = @{
                            'ProxyID' = $PD.Proxy.id
                            'Mode'    = 'NONE'
                            'Name'    = $PD.ProxyZones[1].Name
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
            }
    
            Context 'Remove-EDNSProxyZone' {
                It 'removes a single zone successfully (parameter)' {
                    $TestParams = @{
                        'ProxyID'            = $PD.Proxy.Id
                        'BypassSafetyChecks' = $true
                        'ProxyZones'         = $PD.ProxyZones[0].Name
                        'Comment'            = "Deleting with Pester"
                    }
                    $PD.RemoveProxyZoneParam = Remove-EDNSProxyZone @TestParams @CommonParams
                    $PD.RemoveProxyZoneParam.requestId | Should -Not -BeNullOrEmpty
                    $PD.RemoveProxyZoneParam.expirationDate | Should -Not -BeNullOrEmpty
                }
                It 'removes multiple zones successfully (pipeline)' {
                    $TestParams = @{
                        'ProxyID'            = $PD.Proxy.Id
                        'BypassSafetyChecks' = $true
                        'Comment'            = "Deleting with Pester"
                    }
                    $PD.RemoveProxyZonePipeline = $PD.ProxyZones[1..2] | Remove-EDNSProxyZone @TestParams @CommonParams
                    $PD.RemoveProxyZonePipeline.requestId | Should -Not -BeNullOrEmpty
                    $PD.RemoveProxyZonePipeline.expirationDate | Should -Not -BeNullOrEmpty
                }
            }
    
            Context 'Get-EDNSProxyZoneDeleteStatus' {
                It 'gets delete status (parameter)' {
                    $TestParams = @{
                        'ProxyID'   = $PD.Proxy.Id
                        'RequestID' = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $PD.ProxyZoneDeleteStatus = Get-EDNSProxyZoneDeleteStatus @TestParams @CommonParams
                    $PD.ProxyZoneDeleteStatus.zonesSubmitted | Should -Be 2
                    $PD.ProxyZoneDeleteStatus.isComplete | Should -Not -BeNullOrEmpty
    
                    while ($PD.ProxyZoneDeleteStatus.isComplete -ne $true) {
                        Start-Sleep -s 15
                        $PD.ProxyZoneDeleteStatus = Get-EDNSProxyZoneDeleteStatus @TestParams @CommonParams
                    }
                }
                It 'gets delete status (pipeline)' {
                    $TestParams = @{
                        'RequestID' = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $ProxyZoneDeleteStatus = $PD.Proxy | Get-EDNSProxyZoneDeleteStatus @TestParams @CommonParams
                    $ProxyZoneDeleteStatus.zonesSubmitted | Should -Be 2
                    $ProxyZoneDeleteStatus.isComplete | Should -Not -BeNullOrEmpty
                }
            }
    
            Context 'Get-EDNSProxyZoneDeleteResult' {
                It 'returns the correct data (parameter)' {
                    $TestParams = @{
                        'ProxyID'   = $PD.Proxy.Id
                        'RequestID' = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $PD.ProxyZoneDeleteResult = Get-EDNSProxyZoneDeleteResult @TestParams @CommonParams
                    $PD.ProxyZoneDeleteResult.requestId | Should -Be $PD.RemoveProxyZonePipeline.requestId
                    $PD.ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[1].Name
                    $PD.ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[2].Name
                }
                It 'returns the correct data (pipeline)' {
                    $TestParams = @{
                        'RequestID' = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $ProxyZoneDeleteResult = $PD.Proxy | Get-EDNSProxyZoneDeleteResult @TestParams @CommonParams
                    $ProxyZoneDeleteResult.requestId | Should -Be $PD.RemoveProxyZonePipeline.requestId
                    $ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[1].Name
                    $ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[2].Name
                }
            }
        }
    }
}