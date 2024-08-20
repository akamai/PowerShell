BeforeDiscovery {}

BeforeAll {
    Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
    Import-Module $PSScriptRoot/../src/Akamai.EdgeDNS/Akamai.EdgeDNS.psd1 -Force

    $TestParams = @{
        EdgeRCFile = $env:PesterEdgeRCFile
        Section    = $env:PesterEdgeRCSection
    }

    $TestContractId = $env:PesterContractID
    $TestGroupId = $env:PesterGroupID
    $TestZonePrimary = "primary.pwsh.test"
    $TestZoneSecondary = "secondary.pwsh.test"
    $TestZoneAlias = "alias.pwsh.test"

    $BodyPrimaryObject = [PSCustomObject]@{
        zone                  = $TestZonePrimary
        type                  = "PRIMARY"
        endCustomerId         = "1234567"
        comment               = "PWSH Pester Test"
        signAndServe          = $true
        signAndServeAlgorithm = "ECDSA_P256_SHA256"
    }

    $BodySecondaryObject = [PSCustomObject]@{
        zone          = $TestZoneSecondary
        type          = "SECONDARY"
        endCustomerId = "1234567"
        comment       = "PWSH Pester Test"
        masters       = @(
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
        tsigKey       = @{
            algorithm = "hmac-md5"
            name      = "pwshtest"
            secret    = "cHdzaHRlc3Q="
        }
        signAndServe  = $false
    }

    $BodyAliasObject = [PSCustomObject]@{
        zone          = $TestZoneAlias
        type          = "ALIAS"
        endCustomerID = 1234567
        comment       = "PWSH Pester Test"
        target        = $TestZonePrimary
    }

    $PD = @{}
}

Describe "EdgeDNS" {
    Describe "Zones" -Tag "Done" {
        Context "New-EdnsZone" {
            It "creates new PRIMARY zone (parameters)" {
                $Zone = "params-primary.pwsh.test"
                $TestParams += @{
                    Zone          = $Zone
                    Type          = "PRIMARY"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                }
                $Result = New-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $TestParams.Zone
            }
            It "creates new SECONDARY zone (parameters, masters as array)" {
                $Zone = "params-secondary.pwsh.test"
                $TestParams += @{
                    Zone             = $Zone
                    Type             = "SECONDARY"
                    ContractID       = $TestContractId
                    GroupID          = $TestGroupId
                    Comment          = "PWSH Pester Test"
                    EndCustomerID    = 1234567
                    Masters          = @("192.168.10.10", "192.168.10.11")
                    TSIGKeyAlgorithm = "hmac-md5"
                    TSIGKeyName      = "pwshtest"
                    TSIGKeySecret    = "cHdzaHRlc3Q="
                }
                $Result = New-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $TestParams.Zone
            }
            It "Creates new SECONDARY zone (parameters, masters as string)" {
                $Zone = "params2-secondary.pwsh.test"
                $TestParams += @{
                    Zone             = $Zone
                    Type             = "SECONDARY"
                    ContractID       = $TestContractId
                    GroupID          = $TestGroupId
                    Comment          = "PWSH Pester Test"
                    EndCustomerID    = 1234567
                    Masters          = "192.168.10.10,192.168.10.11"
                    TSIGKeyAlgorithm = "hmac-md5"
                    TSIGKeyName      = "pwshtest"
                    TSIGKeySecret    = "cHdzaHRlc3Q="
                }
                $Result = New-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $TestParams.Zone
            }
            It "Creates new ALIAS zone (parameters)" {
                $Zone = "params-alias.pwsh.test"
                $TestParams += @{
                    Zone          = $Zone
                    Type          = "ALIAS"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                    Target        = $TestZonePrimary
                }
                $Result = New-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $TestParams.Zone
            }
            It "Creates new PRIMARY zone from JSON Body (parameters)" {
                $Zone = "json-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject | ConvertTo-Json -Depth 5
                $Result = New-EdnsZone @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (parameters)" {
                $Zone = "object-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject
                $Result = New-EdnsZone @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from JSON (pipeline)" {
                $Zone = "json-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | ConvertTo-Json -Depth 5 | New-EdnsZone @TestParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (pipeline)" {
                $Zone = "object-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | New-EdnsZone @TestParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }            
            AfterEach {
                New-EdnsZoneBulkDelete -BypassSafetyChecks -Zones $Zone -EdgeRCFile $TestParams.EdgeRCFile -Section $TestParams.Section
                Start-Sleep -Seconds 2
            }
        }
        Context "Get-EdnsZone" {
            It "returns details for all zones (no parameters)" {
                $Result = Get-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZone @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZone @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Get-EdnsZoneContract" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneContract @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneContract @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneAlias" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneAlias @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneAlias @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneTransferStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneTransferStatus @TestParams -Zones $TestZoneSecondary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneTransferStatus @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneDNSSECStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneDNSSECStatus @TestParams -Zones $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneDNSSECStatus @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsZone" {
            It "updates settings for specified zone (parameter)" {
                $Body = Get-EdnsZone @TestParams -Zone $TestZonePrimary
                $Body.endCustomerId = 12321
                $Result = Set-EdnsZone @TestParams -Zone $TestZonePrimary -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 12321
            }
            It "updates settings for specified zone (pipeline)" {
                $Body = Get-EdnsZone @TestParams -Zone $TestZonePrimary
                $Body.endCustomerId = 34543
                $Result = $Body | Set-EdnsZone @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 34543
            }
        }
    }
    
    Describe "Record Sets" {
        Context "Get-EdnsRecordSetTypes" {
            It "returns all types for specified record set in a zone (parameter)" {
                $Result = Get-EdnsRecordSetTypes @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all types for specified record set in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSetTypes @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsRecordSet" {
            It "returns all record sets in a zone (parameter)" {
                $Result = Get-EdnsRecordSet @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all record sets in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSet @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns filtered record set for a specified zone (parameter)" {
                $Result = Get-EdnsRecordSet @TestParams -Zone $TestZonePrimary -Name $TestZonePrimary -Type NS
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsMasterFile" {
            It "returns whole master file for the specified zone (parameter)" {
                $Result = Get-EdnsMasterFile @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns whole master file for the specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsMasterFile @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsMasterFile" {
            It "returns whole master file for the specified zone (pipeline)" {
                $MasterFile = Get-EdnsMasterFile @TestParams -Zone $TestZonePrimary
                $MasterFile | Where-Object { $_ -match "primary\.pwsh\.test\.\s+\d+\s+IN\s+SOA\s+.*hostmaster.primary.pwsh.test.\s+(\d+)" } | Out-Null
                $ExistingSerial = [int]$Matches[1]
                $NewSerial = ($ExistingSerial + 1).ToString()
                $NewMasterFile = $MasterFile -replace $ExistingSerial, $NewSerial
                $Result = $NewMasterFile | Set-EdnsMasterFile @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "New-EdnsRecordSet" {
            BeforeAll {
                $Zone = "primary.pwsh.test"
                $SingleRecordName = "newrecord-param"
                $MultiRecordName = "newrecord-body"
            }
            It "creates a record set in the specified zone (parameter)" {
                New-EdnsRecordSet -Zone $Zone -Name "$SingleRecordName.$Zone" -Type A -TTL 60 -RData '1.1.1.1' @TestParams
                $PD.NewRecord = Get-EdnsRecordSet -Zone $Zone -Name "$SingleRecordName.$Zone" -Type A @TestParams
                $PD.NewRecord.name | Should -Be "$SingleRecordName.$Zone"
                $PD.NewRecord.ttl | Should -Be 60
                $PD.NewRecord.Type | Should -Be 'A'
                $PD.NewRecord.rdata | Should -Be @('1.1.1.1')
            }
            It "creates a record set in the specified zone (body)" {
                $Body = @{
                    'recordsets' = @(
                        @{
                            name  = "$MultiRecordName.$Zone"
                            rdata = @('2.2.2.2')
                            ttl   = 60
                            type  = 'A'
                        }
                        @{
                            name  = "$MultiRecordName.$Zone"
                            rdata = @('AkamaiPowershell')
                            ttl   = 60
                            type  = 'TXT'
                        }
                    )
                }
                New-EdnsRecordSet -Zone $Zone -Body $Body @TestParams
                $PD.NewRecords = Get-EdnsRecordSet -Search "$MultiRecordName.$Zone" -Zone $Zone @TestParams
                $PD.NewRecords[0].name | Should -Be "$MultiRecordName.$Zone"
                $PD.NewRecords[0].ttl | Should -Be 60
                $PD.NewRecords[0].Type | Should -Be 'A'
                $PD.NewRecords[0].rdata | Should -Be @('2.2.2.2')
                $PD.NewRecords[1].name | Should -Be "$MultiRecordName.$Zone"
                $PD.NewRecords[1].ttl | Should -Be 60
                $PD.NewRecords[1].Type | Should -Be 'TXT'
                $PD.NewRecords[1].rdata | Should -Be @('"AkamaiPowershell"')
            }
        }
        Context "Remove-EdnsZoneRecordSet" {
            BeforeAll {
                $Zone = "primary.pwsh.test"
            }
            It "removes specified record set from a zone (parameter)" {
                Remove-EdnsRecordSet -Zone $Zone -Name $PD.NewRecord.Name -Type $PD.NewRecord.Type @TestParams
            }
            It "removes specified record set from a zone (pipeline)" {
                $PD.NewRecords | Remove-EdnsRecordSet -Zone $Zone @TestParams
            }
        }
    }
    
    Describe "TSIG Keys" -Tag "Done" {
        BeforeAll {
            $Zones = @{
                zones = @()
            } 
            for ($i = 0; $i -lt 2; $i++) {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodySecondaryObject.zone = "secondary-tsig-$Timestamp.pwsh.test"
                $Zones.zones += $BodySecondaryObject.psobject.Copy()
                Start-Sleep -Milliseconds 100
            }
            $ZoneCreation = New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
            # Wait for creation to complete
            while (-not $Status.isComplete) {
                $Status = Get-EdnsZoneBulkCreateStatus -RequestID $ZoneCreation.requestId @TestParams
                Start-Sleep -s 3
                Write-Host -ForegroundColor Yellow "Waiting for zone creation to complete..."
            }
        }
        Context "Get-EdnsTSIGKey" {
            It "returns all TSIG keys" {
                $Result = Get-EdnsTSIGKey @TestParams -Search tsig -SortBy name -ContractIDs $TestContractId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns a TSIG key for specified zone (parameter)" {
                $Result = Get-EdnsTSIGKey @TestParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns a TSIG key for specified zone (pipeline)" {
                $Result = $BodySecondaryObject.zone | Get-EdnsTSIGKey @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsTSIGKey" {
            It "updates TSIG key data for specified zone (parameter)" {
                $Result = Set-EdnsTSIGKey @TestParams -Zones $BodySecondaryObject.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for specified zone (pipeline)" {
                $Body = @{
                    zones = @($BodySecondaryObject.zone)
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EdnsTSIGKey @TestParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (parameter)" {
                $Result = Set-EdnsTSIGKey @TestParams -Zones $Zones.zones.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (pipeline)" {
                $Body = @{
                    zones = $Zones.zones.zone
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EdnsTSIGKey @TestParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsTSIGKeyUsedBy" {
            It "returns all zone names using specified TSIG key (parameter)" {
                $Result = Get-EdnsTSIGKeyUsedBy @TestParams -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using specified TSIG key (pipeline)" {
                $Result = $BodySecondaryObject.TSIGKey | Get-EdnsTSIGKeyUsedBy @TestParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using the same TSIG key as specified zone (parameter)" {
                $Result = Get-EdnsTSIGKeyUsedBy @TestParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
        }
        Context "Remove-EdnsTSIGKey" {
            It "removes the TSIG key for specified zone (parameter)" {
                $Result = Remove-EdnsTSIGKey @TestParams -Zone $Zones.zones.zone[0]
                $Result | Should -BeNullOrEmpty
            }
            It "removes the TSIG key for specified zone (pipeline)" {
                $Result = $Zones.zones.zone[1] | Remove-EdnsTSIGKey @TestParams
                $Result | Should -BeNullOrEmpty
            }
        }
        AfterAll {
            New-EdnsZoneBulkDelete @TestParams -Zones $Zones.zones.zone -BypassSafetyChecks
        }
    }
    
    Describe "Bulk Zone Operations" -Tag "Done" {
        Context "New-EdnsZoneBulkCreate (Single Zone)" {
            BeforeEach {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
            }
            It "creates a new zone creation request (parameter)" {
                $Result = New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            AfterEach {
                Start-Sleep -Seconds 3
                New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EdnsZoneBulkCreate (Multi Zone)" {
            BeforeEach {
                $Zones = @{
                    zones = @()
                } 
                for ($i = 0; $i -lt 2; $i++) {
                    $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                    $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                    $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                    Start-Sleep -Milliseconds 100
                }
            }
            It "creates a new zone creation request (parameter)" {
                $Result = New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            AfterEach {
                Start-Sleep -Seconds 3
                New-EdnsZoneBulkDelete @TestParams -Zones $Zones.zones.zone -BypassSafetyChecks
            }
        }
        Context "Get-EdnsZoneBulkCreateStatus" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkCreateStatus @TestParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EdnsZoneBulkCreateStatus @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "Get-EdnsZoneBulkCreateResult" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkCreateResult @TestParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EdnsZoneBulkCreateResult @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EdnsZoneBulkDelete (Single zone)" {
            BeforeEach {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $BodyPrimaryObject.zone | New-EdnsZoneBulkDelete @TestParams
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
        }
        Context "New-EdnsZoneBulkDelete (Multi zone)" {
            BeforeEach {
                $Zones = @{
                    zones = @()
                } 
                for ($i = 0; $i -lt 2; $i++) {
                    $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                    $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                    $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                    Start-Sleep -Milliseconds 100
                }
                New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EdnsZoneBulkDelete @TestParams -Zones $Zones.zones.zone
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $Zones.zones.zone | New-EdnsZoneBulkDelete @TestParams
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
        }
        Context "Get-EdnsZoneBulkDeleteStatus" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkDeleteStatus @TestParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EdnsZoneBulkDeleteStatus @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneBulkDeleteResult" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EdnsZoneBulkCreate @TestParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EdnsZoneBulkDelete @TestParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                while (-not $Status.isComplete) {
                    $Status = Get-EdnsZoneBulkDeleteStatus -RequestID $DeleteResult.requestId @TestParams
                    Start-Sleep -s 3
                    Write-Host -ForegroundColor Yellow "Waiting for zone deletion to complete..."
                }
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkDeleteResult @TestParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EdnsZoneBulkDeleteResult @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Change Lists" -Tag "Done" {
        Context "New-EdnsChangeList" {
            It "creates a new changelist (parameter)" {
                $Result = New-EdnsChangeList @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeList" {
            It "returns details for all changelists" {
                $Result = Get-EdnsChangeList @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EdnsChangeList @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsChangeList @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListSettings" {
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EdnsChangeListSettings @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsChangeListSettings @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsChangeListSettings" {
            It "updates changelist with specified zone settings (parameter)" {
                $Settings = Get-EdnsChangeListSettings @TestParams -Zone $TestZonePrimary
                $Settings.endCustomerID = 77777
                $Result = $Settings | Set-EdnsChangeListSettings @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSet" {
            It "returns all changelist record sets for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSet @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record sets of selected type for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSet @TestParams -Zone $TestZonePrimary -Types NS, SOA
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSetNames" {
            It "returns changelist record set names for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSetNames @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSetTypes" {
            It "returns changelist record set types for specified zone and record name (parameter)" {
                $Result = Get-EdnsChangeListRecordSetTypes @TestParams -Zone $TestZonePrimary -Name $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsChangeListRecordSet" {
            It "modifies record set for a changelist (parameter)" {
                $RecordSetName = "info.primary.pwsh.test"
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                # $RecordSetName = 'info.' -join $TestZonePrimary
                $Result = Set-EdnsChangeListRecordSet @TestParams -Zone $TestZonePrimary -Name $RecordSetName -Type TXT -Op EDIT -TTL 60 -RData "This is a PWSH Pester test $Timestamp"
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListDiff" {
            It "shows changes between current changelist and active record set" {
                $Result = Get-EdnsChangeListDiff @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Submit-EdnsChangeList" {
            It "submits changelist (paramter)" {
                $Result = Submit-EdnsChangeList @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
                Start-Sleep -Seconds 2
            }
        }
        Context "Set-EdnsChangeListMasterFile" {
            BeforeAll {
                New-EdnsChangeList @TestParams -Zone $TestZonePrimary
            }
            It "uploads master zone file to changelist (paramter)" {
                $ZoneFile = Get-EdnsMasterFile @TestParams -Zone $TestZonePrimary
                $Result = Set-EdnsChangeListMasterFile @TestParams -Zone $TestZonePrimary -Body $ZoneFile
                $Result | Should -BeNullOrEmpty
            }
            It "uploads master zone file to changelist (pipeline)" {
                $ZoneFile = Get-EdnsMasterFile @TestParams -Zone $TestZonePrimary
                $Result = $ZoneFile | Set-EdnsChangeListMasterFile @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Remove-EdnsChangeList" {
            It "removes an existing changelist (parameter)" {
                $Result = Remove-EdnsChangeList @TestParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
    }
    
    Describe "Zone Versions" -Tag "Done" {
        Context "Get-EdnsZoneVersion" {
            It "returns all details for specified zone (parameter)" {
                $Result = Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneVersion @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified version id of a zone (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Compare-EdnsZoneVersion" {
            It "returns diff details for specified zone versions (parameter)" {
                $From = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $To = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[1]
                $Result = Compare-EdnsZoneVersion @TestParams -Zone $TestZonePrimary -From $From -To $To
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneVersionRecordSet" {
            It "returns all details for specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @TestParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone version (pipeline)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EdnsZoneVersionRecordSet @TestParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (array, parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @TestParams -Zone $TestZonePrimary -VersionID $VersionID -Types @("SOA", "NS") -SortBy @("name", "type")
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (string, parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @TestParams -Zone $TestZonePrimary -VersionID $VersionID -Types "SOA,NS" -SortBy "name,type"
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Restore-EdnsZoneVersion" {
            It "restores specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion -Zone $TestZonePrimary @TestParams | Sort-Object lastActivationDate -Descending).versionId[1]
                $Result = Restore-EdnsZoneVersion @TestParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -BeNullOrEmpty
            }
            It "restores specified zone version (pipeline, ByPropertyName)" {
                $OldVersion = $(Get-EdnsZoneVersion -zone $TestZonePrimary @TestParams | Sort-Object lastActivationDate -Descending)[1]
                $Result = $OldVersion | Restore-EdnsZoneVersion @TestParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneVersionMasterFile" {
            It "returns Master Zone file for specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionMasterFile @TestParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline)" {
                $VersionID = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EdnsZoneVersionMasterFile @TestParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline, ByPropertyName)" {
                $ZoneVersion = $(Get-EdnsZoneVersion @TestParams -Zone $TestZonePrimary)[0]
                $Result = $ZoneVersion | Get-EdnsZoneVersionMasterFile @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Data Services" -Tag "Done" {
        Context "Get-EdnsAuthority" {
            It "returns details for specified contract IDs (string, parameter)" {
                $Result = Get-EdnsAuthority @TestParams -ContractID "$TestContractID,$TestContractID"
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (string, pipeline)" {
                $Result = "$TestContractID,$TestContractID" | Get-EdnsAuthority @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, parameter)" {
                $Result = Get-EdnsAuthority @TestParams -ContractID @($TestContractID, $TestContractID)
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, pipeline)" {
                $Result = @($TestContractID, $TestContractID) | Get-EdnsAuthority @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsContracts" {
            It "returns details of all contracts" {
                $Result = Get-EdnsContracts @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EdnsContracts @TestParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract ID (pipeline)" {
                $Result = $TestGroupId | Get-EdnsContracts @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsDNSSECAlgorithms" {
            It "returns DNSSEC Algorithm list" {
                $Result = Get-EdnsDNSSECAlgorithms @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsEdgeHostnames" {
            It "returns Edge hostname list" {
                $Result = Get-EdnsEdgeHostnames @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsGroups" {
            It "returns details for all groups" {
                $Result = Get-EdnsGroups @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EdnsGroups @TestParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (pipeline)" {
                $Result = $TestGroupId | Get-EdnsGroups @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }        
        Context "Get-EdnsRecordSetTypes" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsRecordSetTypes @TestParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSetTypes @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsTSIGAlgorithms" {
            It "returns TSIG Algorithm list" {
                $Result = Get-EdnsTSIGAlgorithms @TestParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
}