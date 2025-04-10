BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

BeforeAll {
    Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
    Import-Module $PSScriptRoot/../src/Akamai.EdgeDNS/Akamai.EdgeDNS.psd1 -Force

    $CommonParams = @{
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
                $CommonParams += @{
                    Zone          = $Zone
                    Type          = "PRIMARY"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                }
                $Result = New-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $CommonParams.Zone
            }
            It "creates new SECONDARY zone (parameters, masters as array)" {
                $Zone = "params-secondary.pwsh.test"
                $CommonParams += @{
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
                $Result = New-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $CommonParams.Zone
            }
            It "Creates new SECONDARY zone (parameters, masters as string)" {
                $Zone = "params2-secondary.pwsh.test"
                $CommonParams += @{
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
                $Result = New-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $CommonParams.Zone
            }
            It "Creates new ALIAS zone (parameters)" {
                $Zone = "params-alias.pwsh.test"
                $CommonParams += @{
                    Zone          = $Zone
                    Type          = "ALIAS"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                    Target        = $TestZonePrimary
                }
                $Result = New-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $CommonParams.Zone
            }
            It "Creates new PRIMARY zone from JSON Body (parameters)" {
                $Zone = "json-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject | ConvertTo-Json -Depth 5
                $Result = New-EdnsZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (parameters)" {
                $Zone = "object-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject
                $Result = New-EdnsZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from JSON (pipeline)" {
                $Zone = "json-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | ConvertTo-Json -Depth 5 | New-EdnsZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (pipeline)" {
                $Zone = "object-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | New-EdnsZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }            
            AfterEach {
                New-EdnsZoneBulkDelete -BypassSafetyChecks -Zones $Zone -EdgeRCFile $CommonParams.EdgeRCFile -Section $CommonParams.Section
                Start-Sleep -Seconds 2
            }
        }
        Context "Get-EdnsZone" {
            It "returns details for all zones (no parameters)" {
                $Result = Get-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZone @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Get-EdnsZoneContract" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneContract @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneContract @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneAlias" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneAlias @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneAlias @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneTransferStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneTransferStatus @CommonParams -Zones $TestZoneSecondary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneTransferStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneDNSSECStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsZoneDNSSECStatus @CommonParams -Zones $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneDNSSECStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsZone" {
            It "updates settings for specified zone (parameter)" {
                $Body = Get-EdnsZone @CommonParams -Zone $TestZonePrimary
                $Body.endCustomerId = 12321
                $Result = Set-EdnsZone @CommonParams -Zone $TestZonePrimary -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 12321
            }
            It "updates settings for specified zone (pipeline)" {
                $Body = Get-EdnsZone @CommonParams -Zone $TestZonePrimary
                $Body.endCustomerId = 34543
                $Result = $Body | Set-EdnsZone @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 34543
            }
        }
    }
    
    Describe "Record Sets" {
        Context "Get-EdnsRecordSetTypes" {
            It "returns all types for specified record set in a zone (parameter)" {
                $Result = Get-EdnsRecordSetTypes @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all types for specified record set in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSetTypes @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsRecordSet" {
            It "returns all record sets in a zone (parameter)" {
                $Result = Get-EdnsRecordSet @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all record sets in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSet @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns filtered record set for a specified zone (parameter)" {
                $Result = Get-EdnsRecordSet @CommonParams -Zone $TestZonePrimary -Name $TestZonePrimary -Type NS
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsMasterFile" {
            It "returns whole master file for the specified zone (parameter)" {
                $Result = Get-EdnsMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns whole master file for the specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsMasterFile @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsMasterFile" {
            It "returns whole master file for the specified zone (pipeline)" {
                $MasterFile = Get-EdnsMasterFile @CommonParams -Zone $TestZonePrimary
                $MasterFile | Where-Object { $_ -match "primary\.pwsh\.test\.\s+\d+\s+IN\s+SOA\s+.*hostmaster.primary.pwsh.test.\s+(\d+)" } | Out-Null
                $ExistingSerial = [int]$Matches[1]
                $NewSerial = ($ExistingSerial + 1).ToString()
                $NewMasterFile = $MasterFile -replace $ExistingSerial, $NewSerial
                $Result = $NewMasterFile | Set-EdnsMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "New-EdnsRecordSet" {
            BeforeAll {
                $Zone = "primary.pwsh.test"
                $SingleRecordName = "newrecord-param"
                $SingleRecordPipeline = "newrecord-pipeline"
                $MultiRecordName = "newrecord-body"
            }
            It "creates a record set in the specified zone (parameter)" {
                $TestParams = @{
                    'Zone'  = $Zone
                    'Name'  = "$SingleRecordName.$Zone"
                    'Type'  = 'A'
                    'TTL'   = 60
                    'RData' = '1.1.1.1'
                }
                New-EdnsRecordSet @TestParams @CommonParams
                $PD.NewRecord = Get-EdnsRecordSet -Zone $Zone -Name "$SingleRecordName.$Zone" -Type 'A' @CommonParams
                $PD.NewRecord.name | Should -Be "$SingleRecordName.$Zone"
                $PD.NewRecord.ttl | Should -Be 60
                $PD.NewRecord.Type | Should -Be 'A'
                $PD.NewRecord.rdata | Should -Be @('1.1.1.1')
            }
            It "creates a record set in the specified zone (pipeline)" {
                $NewRecord = [PSCustomObject] @{
                    'name'  = "$SingleRecordPipeline.$Zone"
                    'type'  = 'A'
                    'ttl'   = 60
                    'rdata' = @('2.2.2.2')
                }
                $NewRecord | New-EdnsRecordSet -Zone $Zone @CommonParams
                $PD.NewRecordPipeline = Get-EdnsRecordSet -Zone $Zone -Name "$SingleRecordPipeline.$Zone" -Type 'A' @CommonParams
                $PD.NewRecordPipeline.name | Should -Be "$SingleRecordPipeline.$Zone"
                $PD.NewRecordPipeline.ttl | Should -Be 60
                $PD.NewRecordPipeline.Type | Should -Be 'A'
                $PD.NewRecordPipeline.rdata | Should -Be @('2.2.2.2')
            }
            It "creates a record set in the specified zone (body)" {
                $Body = @{
                    'recordsets' = @(
                        @{
                            name  = "$MultiRecordName.$Zone"
                            rdata = @('3.3.3.3')
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
                New-EdnsRecordSet -Zone $Zone -Body $Body @CommonParams
                $PD.NewRecords = Get-EdnsRecordSet -Search "$MultiRecordName.$Zone" -Zone $Zone @CommonParams
                $PD.NewRecords[0].name | Should -Be "$MultiRecordName.$Zone"
                $PD.NewRecords[0].ttl | Should -Be 60
                $PD.NewRecords[0].Type | Should -Be 'A'
                $PD.NewRecords[0].rdata | Should -Be @('3.3.3.3')
                $PD.NewRecords[1].name | Should -Be "$MultiRecordName.$Zone"
                $PD.NewRecords[1].ttl | Should -Be 60
                $PD.NewRecords[1].Type | Should -Be 'TXT'
                $PD.NewRecords[1].rdata | Should -Be @('"AkamaiPowershell"')
            }
            AfterAll {
                Write-Host -ForegroundColor Yellow "Waiting for 30s for record creation to complete..."
                Start-Sleep -Seconds 30
            }
        }
        Context 'Set-EdnsRecordSet' {
            BeforeAll {
                $Zone = "primary.pwsh.test"
                $SingleRecordName = "newrecord-param"
                $MultiRecordName = "newrecord-body"
            }
            It "updates a single record set in the specified zone (parameter)" {
                $TestParams = @{
                    'Zone'  = $Zone
                    'Name'  = "$SingleRecordName.$Zone"
                    'Type'  = 'A'
                    'TTL'   = 60
                    'RData' = '2.2.2.2'
                }
                $PD.SetRecordParam = Set-EdnsRecordSet @TestParams @CommonParams
                $PD.SetRecordParam.name | Should -Be "$SingleRecordName.$Zone"
                $PD.SetRecordParam.ttl | Should -Be 60
                $PD.SetRecordParam.Type | Should -Be 'A'
                $PD.SetRecordParam.rdata | Should -Be @('2.2.2.2')
            }
            It "updates a single record set in the specified zone (pipeline)" {
                $PD.SetRecordParam.rdata[0] = '3.3.3.3'
                $PD.SetRecordPipeline = $PD.SetRecordParam | Set-EdnsRecordSet -Zone $Zone @CommonParams
                $PD.SetRecordPipeline.name | Should -Be "$SingleRecordName.$Zone"
                $PD.SetRecordPipeline.ttl | Should -Be 60
                $PD.SetRecordPipeline.Type | Should -Be 'A'
                $PD.SetRecordPipeline.rdata | Should -Be @('3.3.3.3')
            }
            It "throws an error when trying to update without incrementing the SOA" {
                $AllRecordSets = Get-EdnsRecordSet -Zone $Zone @CommonParams
                { $AllRecordSets | Set-EdnsRecordSet -Zone $Zone -Confirm:$false @CommonParams } | Should -throw
            }
            It "replaces all records when set to auto-increment SOA" {
                $AllRecordSets = Get-EdnsRecordSet -Zone $Zone @CommonParams
                $AllRecordSets | Set-EdnsRecordSet -Zone $Zone -AutoIncrementSOA -Confirm:$false @CommonParams
            }
        }
        Context "Remove-EdnsRecordSet" {
            BeforeAll {
                $Zone = "primary.pwsh.test"
            }
            It "removes specified record set from a zone (parameter)" {
                Remove-EdnsRecordSet -Zone $Zone -Name $PD.NewRecord.Name -Type $PD.NewRecord.Type @CommonParams
            }
            It "removes specified record set from a zone (pipeline)" {
                $PD.NewRecords | Remove-EdnsRecordSet -Zone $Zone @CommonParams
                $PD.NewRecordPipeline | Remove-EdnsRecordSet -Zone $Zone @CommonParams
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
            $ZoneCreation = New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
            # Wait for creation to complete
            while (-not $Status.isComplete) {
                $Status = Get-EdnsZoneBulkCreateStatus -RequestID $ZoneCreation.requestId @CommonParams
                Start-Sleep -Seconds 3
                Write-Host -ForegroundColor Yellow "Waiting for zone creation to complete..."
            }
            Start-Sleep -Seconds 3
        }
        Context "Get-EdnsTSIGKey" {
            It "returns all TSIG keys" {
                $Result = Get-EdnsTSIGKey @CommonParams -Search md5 -SortBy name -ContractIDs $TestContractId
                $Result | Should -Not -BeNullOrEmpty
                $Algorithms = $Result.algoritm | Sort-Object | Get-Unique
                $Algorithms | ForEach-Object {
                    $_.ToLower() | Should -BeLike "hmac-md5*"
                }
            }
            It "returns a TSIG key for specified zone (parameter)" {
                $Result = Get-EdnsTSIGKey @CommonParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns a TSIG key for specified zone (pipeline)" {
                $Result = $BodySecondaryObject.zone | Get-EdnsTSIGKey @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsTSIGKey" {
            It "updates TSIG key data for specified zone (parameter)" {
                $Result = Set-EdnsTSIGKey @CommonParams -Zones $BodySecondaryObject.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for specified zone (pipeline)" {
                $Body = @{
                    zones = @($BodySecondaryObject.zone)
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EdnsTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (parameter)" {
                $Result = Set-EdnsTSIGKey @CommonParams -Zones $Zones.zones.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (pipeline)" {
                $Body = @{
                    zones = $Zones.zones.zone
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EdnsTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsTSIGKeyUsedBy" {
            It "returns all zone names using specified TSIG key (parameter)" {
                $Result = Get-EdnsTSIGKeyUsedBy @CommonParams -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using specified TSIG key (pipeline)" {
                $Result = $BodySecondaryObject.TSIGKey | Get-EdnsTSIGKeyUsedBy @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using the same TSIG key as specified zone (parameter)" {
                $Result = Get-EdnsTSIGKeyUsedBy @CommonParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
        }
        Context "Remove-EdnsTSIGKey" {
            It "removes the TSIG key for specified zone (parameter)" {
                $Result = Remove-EdnsTSIGKey @CommonParams -Zone $Zones.zones.zone[0]
                $Result | Should -BeNullOrEmpty
            }
            It "removes the TSIG key for specified zone (pipeline)" {
                $Result = $Zones.zones.zone[1] | Remove-EdnsTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        AfterAll {
            New-EdnsZoneBulkDelete @CommonParams -Zones $Zones.zones.zone -BypassSafetyChecks
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
                $Result = New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            AfterEach {
                Start-Sleep -Seconds 3
                New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
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
                $Result = New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone creation request(pipeline)" {
                $Result = $Zones | New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            AfterEach {
                Start-Sleep -Seconds 3
                New-EdnsZoneBulkDelete @CommonParams -Zones $Zones.zones.zone -BypassSafetyChecks
            }
        }
        Context "Get-EdnsZoneBulkCreateStatus" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkCreateStatus @CommonParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EdnsZoneBulkCreateStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "Get-EdnsZoneBulkCreateResult" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkCreateResult @CommonParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EdnsZoneBulkCreateResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EdnsZoneBulkDelete (Single zone)" {
            BeforeEach {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone
                $Result.requestId | Should -Not -BeNullOrEmpty
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $BodyPrimaryObject.zone | New-EdnsZoneBulkDelete @CommonParams
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
                New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EdnsZoneBulkDelete @CommonParams -Zones $Zones.zones.zone
                $Result.requestId | Should -Not -BeNullOrEmpty
                $Result.requestId | Should -HaveCount 1
            }
            It "creates a new zone delete request (pipeline)" {
                $Result = $Zones.zones.zone | New-EdnsZoneBulkDelete @CommonParams
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
                New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkDeleteStatus @CommonParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EdnsZoneBulkDeleteStatus @CommonParams
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
                New-EdnsZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EdnsZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                while (-not $Status.isComplete) {
                    $Status = Get-EdnsZoneBulkDeleteStatus -RequestID $DeleteResult.requestId @CommonParams
                    Start-Sleep -s 3
                    Write-Host -ForegroundColor Yellow "Waiting for zone deletion to complete..."
                }
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EdnsZoneBulkDeleteResult @CommonParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EdnsZoneBulkDeleteResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Change Lists" -Tag "Done" {
        Context "New-EdnsChangeList" {
            It "creates a new changelist (parameter)" {
                $Result = New-EdnsChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeList" {
            It "returns details for all changelists" {
                $Result = Get-EdnsChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EdnsChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsChangeList @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListSettings" {
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EdnsChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsChangeListSettings @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsChangeListSettings" {
            It "updates changelist with specified zone settings (parameter)" {
                $Settings = Get-EdnsChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Settings.endCustomerID = 77777
                $Result = $Settings | Set-EdnsChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSet" {
            It "returns all changelist record sets for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSet @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record sets of selected type for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSet @CommonParams -Zone $TestZonePrimary -Types NS, SOA
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSetNames" {
            It "returns changelist record set names for specified zone (parameter)" {
                $Result = Get-EdnsChangeListRecordSetNames @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListRecordSetTypes" {
            It "returns changelist record set types for specified zone and record name (parameter)" {
                $Result = Get-EdnsChangeListRecordSetTypes @CommonParams -Zone $TestZonePrimary -Name $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EdnsChangeListRecordSet" {
            It "modifies record set for a changelist (parameter)" {
                $RecordSetName = "info.primary.pwsh.test"
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                # $RecordSetName = 'info.' -join $TestZonePrimary
                $Result = Set-EdnsChangeListRecordSet @CommonParams -Zone $TestZonePrimary -Name $RecordSetName -Type TXT -Op EDIT -TTL 60 -RData "This is a PWSH Pester test $Timestamp"
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsChangeListDiff" {
            It "shows changes between current changelist and active record set" {
                $Result = Get-EdnsChangeListDiff @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Submit-EdnsChangeList" {
            It "submits changelist (paramter)" {
                $Result = Submit-EdnsChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
                Start-Sleep -Seconds 2
            }
        }
        Context "Set-EdnsChangeListMasterFile" {
            BeforeAll {
                New-EdnsChangeList @CommonParams -Zone $TestZonePrimary
            }
            It "uploads master zone file to changelist (paramter)" {
                $ZoneFile = Get-EdnsMasterFile @CommonParams -Zone $TestZonePrimary
                $Result = Set-EdnsChangeListMasterFile @CommonParams -Zone $TestZonePrimary -Body $ZoneFile
                $Result | Should -BeNullOrEmpty
            }
            It "uploads master zone file to changelist (pipeline)" {
                $ZoneFile = Get-EdnsMasterFile @CommonParams -Zone $TestZonePrimary
                $Result = $ZoneFile | Set-EdnsChangeListMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Remove-EdnsChangeList" {
            It "removes an existing changelist (parameter)" {
                $Result = Remove-EdnsChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
    }
    
    Describe "Zone Versions" -Tag "Done" {
        Context "Get-EdnsZoneVersion" {
            It "returns all details for specified zone (parameter)" {
                $Result = Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsZoneVersion @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified version id of a zone (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Compare-EdnsZoneVersion" {
            It "returns diff details for specified zone versions (parameter)" {
                $From = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $To = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[1]
                $Result = Compare-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary -From $From -To $To
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneVersionRecordSet" {
            It "returns all details for specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone version (pipeline)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EdnsZoneVersionRecordSet @CommonParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (array, parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID -Types @("SOA", "NS") -SortBy @("name", "type")
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (string, parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID -Types "SOA,NS" -SortBy "name,type"
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Restore-EdnsZoneVersion" {
            It "restores specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion -Zone $TestZonePrimary @CommonParams | Sort-Object lastActivationDate -Descending).versionId[1]
                $Result = Restore-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -BeNullOrEmpty
            }
            It "restores specified zone version (pipeline, ByPropertyName)" {
                $OldVersion = $(Get-EdnsZoneVersion -zone $TestZonePrimary @CommonParams | Sort-Object lastActivationDate -Descending)[1]
                $Result = $OldVersion | Restore-EdnsZoneVersion @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EdnsZoneVersionMasterFile" {
            It "returns Master Zone file for specified zone version (parameter)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EdnsZoneVersionMasterFile @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline)" {
                $VersionID = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EdnsZoneVersionMasterFile @CommonParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline, ByPropertyName)" {
                $ZoneVersion = $(Get-EdnsZoneVersion @CommonParams -Zone $TestZonePrimary)[0]
                $Result = $ZoneVersion | Get-EdnsZoneVersionMasterFile @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Data Services" -Tag "Done" {
        Context "Get-EdnsAuthority" {
            It "returns details for specified contract IDs (string, parameter)" {
                $Result = Get-EdnsAuthority @CommonParams -ContractID "$TestContractID,$TestContractID"
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (string, pipeline)" {
                $Result = "$TestContractID,$TestContractID" | Get-EdnsAuthority @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, parameter)" {
                $Result = Get-EdnsAuthority @CommonParams -ContractID @($TestContractID, $TestContractID)
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, pipeline)" {
                $Result = @($TestContractID, $TestContractID) | Get-EdnsAuthority @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsContracts" {
            It "returns details of all contracts" {
                $Result = Get-EdnsContracts @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EdnsContracts @CommonParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract ID (pipeline)" {
                $Result = $TestGroupId | Get-EdnsContracts @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsDNSSECAlgorithms" {
            It "returns DNSSEC Algorithm list" {
                $Result = Get-EdnsDNSSECAlgorithms @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsEdgeHostnames" {
            It "returns Edge hostname list" {
                $Result = Get-EdnsEdgeHostnames @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsGroups" {
            It "returns details for all groups" {
                $Result = Get-EdnsGroups @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EdnsGroups @CommonParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (pipeline)" {
                $Result = $TestGroupId | Get-EdnsGroups @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }        
        Context "Get-EdnsRecordSetTypes" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EdnsRecordSetTypes @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EdnsRecordSetTypes @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EdnsTSIGAlgorithms" {
            It "returns TSIG Algorithm list" {
                $Result = Get-EdnsTSIGAlgorithms @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
}