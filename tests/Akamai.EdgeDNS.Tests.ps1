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
    $TestProxyName = 'akamaipowershell'
    $TestProxyID = $env:PesterDNSProxyID
    $TestProxyZoneName = 'akamaipowershell-proxy.net'

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

AfterAll {
    # Remove zones
    $DirectZones = @(
        "params-primary.pwsh.test"
        "params-secondary.pwsh.test"
        "params2-secondary.pwsh.test"
        "params-alias.pwsh.test"
        "json-body-primary.pwsh.test"
        "object-body-primary.pwsh.test"
        "json-pipeline-primary.pwsh.test"
        "object-pipeline-primary.pwsh.test"
    )

    $AllZones = Get-EDNSZone @CommonParams
    $ZonesToDelete = @()
    $ZonesToDelete += $AllZones | Where-Object zone -in $DirectZones
    $ZonesToDelete += $AllZones | Where-Object zone -match '^primary\-bulk\-[\d]+\.pwsh\.test$'
    $ZonesToDelete += $AllZones | Where-Object zone -match '^secondary\-tsig\-[\d]+\.pwsh\.test$'
    if ($ZonesToDelete.Count -gt 0) {
        Write-Warning "Deleting the following EDNS zones: $($ZonesToDelete.zone)"
        New-EdnsZoneBulkDelete @CommonParams -Zones $ZonesToDelete.zone -BypassSafetyChecks
    }

    # Remove recordsets
    $Zone = 'primary.pwsh.test'
    $Records = "newrecord-param", "newrecord-pipeline", "newrecord-body"
    $Records | ForEach-Object { 
        try {
            Remove-EdnsRecordSet -Zone $Zone -Name "$_.$Zone" -Type A @CommonParams
            Remove-EdnsRecordSet -Zone $Zone -Name "$_.$Zone" -Type TXT @CommonParams
        }
        catch {

        }
    }

    # Remove proxy zones
    $ProxyZones = Get-EDNSProxyZone -ProxyID $TestProxyID @CommonParams
    ForEach ($ProxyZone in $ProxyZones) {
        if ($ProxyZone.filterMode -eq 'MANUAL') {
            Get-EDNSProxyZoneManualFilterReport -ProxyID $TestProxyID -Name $ProxyZone.Name @CommonParams | Remove-EDNSProxyZoneManualFilterName -ProxyID $TestProxyID -Name $AutoProxyZone.Name @CommonParams
        }
        $ProxyZone | Remove-EDNSProxyZone -ProxyID $TestProxyID -BypassSafetyChecks -Comment 'cleanup' @CommonParams
    }
}

Describe "EdgeDNS" {
    Describe "Zones" -Tag "Done" {
        Context "New-EDNSZone" {
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
                $Result = New-EDNSZone @CommonParams
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
                $Result = New-EDNSZone @CommonParams
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
                $Result = New-EDNSZone @CommonParams
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
                $Result = New-EDNSZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $CommonParams.Zone
            }
            It "Creates new PRIMARY zone from JSON Body (parameters)" {
                $Zone = "json-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject | ConvertTo-Json -Depth 5
                $Result = New-EDNSZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (parameters)" {
                $Zone = "object-body-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Body = $BodyPrimaryObject
                $Result = New-EDNSZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from JSON (pipeline)" {
                $Zone = "json-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | ConvertTo-Json -Depth 5 | New-EDNSZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }
            It "Creates new PRIMARY zone from PSObject (pipeline)" {
                $Zone = "object-pipeline-primary.pwsh.test"
                $BodyPrimaryObject.Zone = $Zone
                $Result = $BodyPrimaryObject | New-EDNSZone @CommonParams -ContractID $TestContractId -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
                $Result.zone | Should -Be $BodyPrimaryObject.Zone
            }            
            AfterEach {
                New-EDNSZoneBulkDelete -BypassSafetyChecks -Zones $Zone -EdgeRCFile $CommonParams.EdgeRCFile -Section $CommonParams.Section
                Start-Sleep -Seconds 2
            }
        }
        Context "Get-EDNSZone" {
            It "returns details for all zones (no parameters)" {
                $Result = Get-EDNSZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSZone @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZone @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Get-EDNSZoneContract" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSZoneContract @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZoneContract @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneAlias" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSZoneAlias @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZoneAlias @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneTransferStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSZoneTransferStatus @CommonParams -Zones $TestZoneSecondary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZoneTransferStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Get-EDNSSecondarySOA' {
            It 'returns the correct SOA' {
                $PD.SecondarySOA = Get-EDNSSecondarySOA -Zones $TestZoneSecondary @CommonParams
                $PD.SecondarySOA[0].name | Should -Be $TestZoneSecondary
                $PD.SecondarySOA[0].soaSerialLock | Should -Match '^[0-9]+$'
            }
        }
        Context "Get-EDNSZoneDNSSECStatus" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSZoneDNSSECStatus @CommonParams -Zones $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZoneDNSSECStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSZone" {
            It "updates settings for specified zone (parameter)" {
                $Body = Get-EDNSZone @CommonParams -Zone $TestZonePrimary
                $Body.endCustomerId = 12321
                $Result = Set-EDNSZone @CommonParams -Zone $TestZonePrimary -Body $Body
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 12321
            }
            It "updates settings for specified zone (pipeline)" {
                $Body = Get-EDNSZone @CommonParams -Zone $TestZonePrimary
                $Body.endCustomerId = 34543
                $Result = $Body | Set-EDNSZone @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
                $Result.endCustomerId | Should -Be 34543
            }
        }

        Context 'Zone Conversion' -Tag 'Zone Conversion' {
            BeforeAll {
                Write-Host -ForegroundColor Yellow "Creating conversion zones"
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                # Set zone names
                $ConvertZone1 = "convert1-$Timestamp.pwsh.test"
                $ConvertZone2 = "convert2-$Timestamp.pwsh.test"
                $ConvertZone3 = "convert3-$Timestamp.pwsh.test"

                # Create 3 zones: 2 primary, 1 secondary
                $ConvertZone1Params = @{
                    Zone          = $ConvertZone1
                    Type          = "PRIMARY"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                }
                New-EDNSZone @ConvertZone1Params @CommonParams
                
                $ConvertZone2Params = @{
                    Zone          = $ConvertZone2
                    Type          = "PRIMARY"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                }
                New-EDNSZone @ConvertZone2Params @CommonParams
                
                $ConvertZone3Params = @{
                    Zone          = $ConvertZone3
                    Type          = "ALIAS"
                    ContractID    = $TestContractId
                    GroupID       = $TestGroupId
                    Comment       = "PWSH Pester Test"
                    EndCustomerID = 1234567
                    Target        = $TestZonePrimary
                }
                New-EDNSZone @ConvertZone3Params @CommonParams

                # Create SOA and NS records
                New-EDNSChangeList -Zone $ConvertZone1 @CommonParams
                New-EDNSChangeList -Zone $ConvertZone2 @CommonParams
                Submit-EDNSChangeList -Zone $ConvertZone1 @CommonParams
                Submit-EDNSChangeList -Zone $ConvertZone2 @CommonParams

                $ConvertZone1Status = Get-EDNSZone -Zone $ConvertZone1 @CommonParams
                $ConvertZone2Status = Get-EDNSZone -Zone $ConvertZone1 @CommonParams
                $ConvertZone3Status = Get-EDNSZone -Zone $ConvertZone1 @CommonParams

                $Wait = $true
                while ($Wait) {
                    $ConvertZone1Status = Get-EDNSZone -Zone $ConvertZone1 @CommonParams
                    $ConvertZone2Status = Get-EDNSZone -Zone $ConvertZone2 @CommonParams
                    $ConvertZone3Status = Get-EDNSZone -Zone $ConvertZone3 @CommonParams
                    
                    if ($ConvertZone1Status.activationState -eq 'ACTIVE' -and $ConvertZone2Status.activationState -eq 'ACTIVE' -and $ConvertZone3Status.activationState -eq 'ACTIVE') {
                        $Wait = $false
                    }
                    else {
                        Write-Host -ForegroundColor Yellow "Waiting 30s for zone creation to complete"
                        Start-Sleep -s 30
                    }
                }
            }

            It 'converts to secondary successfully' {
                $TestParams = @{
                    Zone             = $ConvertZone1
                    Masters          = '1.2.3.4'
                    Comment          = 'Converted by Pester'
                    TSIGKeyAlgorithm = 'hmac-sha256'
                    TSIGKeyName      = "convert-tsig-$Timestamp"
                    TSIGKeySecret    = ConvertTo-Base64 -UnencodedString 'Better to burn out, than to fade away'
                }
                $PD.ConvertToSecondary = Convert-EDNSZoneToSecondary @TestParams @CommonParams
                $PD.ConvertToSecondary.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToSecondary.expirationDate | Should -Not -BeNullOrEmpty
            }

            It 'converts to alias successfully' {
                $TestParams = @{
                    Zone           = $ConvertZone2
                    Comment        = 'Converted by Pester'
                    TargetZoneName = $TestZonePrimary
                }
                $PD.ConvertToAlias = Convert-EDNSZoneToAlias @TestParams @CommonParams
                $PD.ConvertToAlias.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToAlias.expirationDate | Should -Not -BeNullOrEmpty
            }

            It 'converts to primary successfully' {
                $TestParams = @{
                    Zone    = $ConvertZone3
                    Comment = 'Converted by Pester'
                }
                $PD.ConvertToPrimary = Convert-EDNSZoneToPrimary @TestParams @CommonParams
                $PD.ConvertToPrimary.requestId | Should -Not -BeNullOrEmpty
                $PD.ConvertToPrimary.expirationDate | Should -Not -BeNullOrEmpty
            }

            Context 'Get-EDNSConvertStatus' {
                It 'returns conversion status' {
                    $Wait = $true
                    while ($Wait) {
                        $PD.ZoneConvertSecondaryStatus = Get-EDNSConvertStatus -RequestID $PD.ConvertToSecondary.requestId @CommonParams
                        $PD.ZoneConvertAliasStatus = Get-EDNSConvertStatus -RequestID $PD.ConvertToAlias.requestId @CommonParams
                        $PD.ZoneConvertPrimaryStatus = Get-EDNSConvertStatus -RequestID $PD.ConvertToPrimary.requestId @CommonParams
                        
                        if ($PD.ZoneConvertSecondaryStatus.isComplete -and $PD.ZoneConvertAliasStatus.isComplete -and $PD.ZoneConvertPrimaryStatus.isComplete) {
                            $Wait = $false
                        }
                        else {
                            Write-Debug "Waiting 30s for zone conversion to complete"
                            Start-Sleep -Seconds 30
                        }
                    }
                    
                    $PD.ZoneConvertSecondaryStatus.requestId | Should -Be $PD.ConvertToSecondary.requestId
                    $PD.ZoneConvertSecondaryStatus.isComplete | Should -Be $true
                    $PD.ZoneConvertAliasStatus.requestId | Should -Be $PD.ConvertToAlias.requestId
                    $PD.ZoneConvertAliasStatus.isComplete | Should -Be $true
                    $PD.ZoneConvertPrimaryStatus.requestId | Should -Be $PD.ConvertToPrimary.requestId
                    $PD.ZoneConvertPrimaryStatus.isComplete | Should -Be $true
                }
            }

            Context 'Get-EDNSConvertResult for secondary' {
                It 'returns conversion result' {
                    $TestParams = @{
                        RequestID = $PD.ConvertToSecondary.requestId
                    }
                    $PD.ZoneConvertSecondaryResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertSecondaryResult.requestId | Should -Be $PD.ConvertToSecondary.requestId
                    $PD.ZoneConvertSecondaryResult.successfullyConvertedZones | Should -Contain $ConvertZone1
                }
            }

            Context 'Get-EDNSConvertResult for alias' {
                It 'returns conversion result' {
                    $TestParams = @{
                        RequestID = $PD.ConvertToAlias.requestId
                    }
                    $PD.ZoneConvertAliasResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertAliasResult.requestId | Should -Be $PD.ConvertToAlias.requestId
                    $PD.ZoneConvertAliasResult.successfullyConvertedZones | Should -Contain $ConvertZone2
                }
            }

            Context 'Get-EDNSConvertResult for primary' {
                It 'returns conversion result' {
                    $TestParams = @{
                        RequestID = $PD.ConvertToPrimary.requestId
                    }
                    $PD.ZoneConvertPrimaryResult = Get-EDNSConvertResult @TestParams @CommonParams
                    $PD.ZoneConvertPrimaryResult.requestId | Should -Be $PD.ConvertToPrimary.requestId
                    $PD.ZoneConvertPrimaryResult.successfullyConvertedZones | Should -Contain $ConvertZone3
                }
            }

            AfterAll {
                New-EDNSZoneBulkDelete -Zones $ConvertZone1, $ConvertZone2, $ConvertZone3 -BypassSafetyChecks @CommonParams
            }
        }
    }
    
    Describe "Record Sets" {
        Context "Get-EDNSRecordSetTypes" {
            It "returns all types for specified record set in a zone (parameter)" {
                $Result = Get-EDNSRecordSetTypes @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all types for specified record set in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSRecordSetTypes @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSRecordSet" {
            It "returns all record sets in a zone (parameter)" {
                $Result = Get-EDNSRecordSet @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all record sets in a zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSRecordSet @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns filtered record set for a specified zone (parameter)" {
                $Result = Get-EDNSRecordSet @CommonParams -Zone $TestZonePrimary -Name $TestZonePrimary -Type NS
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSMasterFile" {
            It "returns whole master file for the specified zone (parameter)" {
                $Result = Get-EDNSMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns whole master file for the specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSMasterFile @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSMasterFile" {
            It "returns whole master file for the specified zone (pipeline)" {
                $MasterFile = Get-EDNSMasterFile @CommonParams -Zone $TestZonePrimary
                $MasterFile | Where-Object { $_ -match "primary\.pwsh\.test\.\s+\d+\s+IN\s+SOA\s+.*hostmaster.primary.pwsh.test.\s+(\d+)" } | Out-Null
                $ExistingSerial = [int]$Matches[1]
                $NewSerial = ($ExistingSerial + 1).ToString()
                $NewMasterFile = $MasterFile -replace $ExistingSerial, $NewSerial
                $Result = $NewMasterFile | Set-EDNSMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "New-EDNSRecordSet" {
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
                New-EDNSRecordSet @TestParams @CommonParams
                $PD.NewRecord = Get-EDNSRecordSet -Zone $Zone -Name "$SingleRecordName.$Zone" -Type 'A' @CommonParams
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
                $NewRecord | New-EDNSRecordSet -Zone $Zone @CommonParams
                $PD.NewRecordPipeline = Get-EDNSRecordSet -Zone $Zone -Name "$SingleRecordPipeline.$Zone" -Type 'A' @CommonParams
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
                New-EDNSRecordSet -Zone $Zone -Body $Body @CommonParams
                $PD.NewRecords = Get-EDNSRecordSet -Search "$MultiRecordName.$Zone" -Zone $Zone @CommonParams
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
        Context 'Set-EDNSRecordSet' {
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
                $PD.SetRecordParam = Set-EDNSRecordSet @TestParams @CommonParams
                $PD.SetRecordParam.name | Should -Be "$SingleRecordName.$Zone"
                $PD.SetRecordParam.ttl | Should -Be 60
                $PD.SetRecordParam.Type | Should -Be 'A'
                $PD.SetRecordParam.rdata | Should -Be @('2.2.2.2')
            }
            It "updates a single record set in the specified zone (pipeline)" {
                $PD.SetRecordParam.rdata[0] = '3.3.3.3'
                $PD.SetRecordPipeline = $PD.SetRecordParam | Set-EDNSRecordSet -Zone $Zone @CommonParams
                $PD.SetRecordPipeline.name | Should -Be "$SingleRecordName.$Zone"
                $PD.SetRecordPipeline.ttl | Should -Be 60
                $PD.SetRecordPipeline.Type | Should -Be 'A'
                $PD.SetRecordPipeline.rdata | Should -Be @('3.3.3.3')
            }
            It "throws an error when trying to update without incrementing the SOA" {
                $AllRecordSets = Get-EDNSRecordSet -Zone $Zone @CommonParams
                { $AllRecordSets | Set-EDNSRecordSet -Zone $Zone -Confirm:$false @CommonParams } | Should -throw
            }
            It "replaces all records when set to auto-increment SOA" {
                $AllRecordSets = Get-EDNSRecordSet -Zone $Zone @CommonParams
                $AllRecordSets | Set-EDNSRecordSet -Zone $Zone -AutoIncrementSOA -Confirm:$false @CommonParams
            }
        }
        Context "Remove-EDNSRecordSet" {
            BeforeAll {
                $Zone = "primary.pwsh.test"
            }
            It "removes specified record set from a zone (parameter)" {
                Remove-EDNSRecordSet -Zone $Zone -Name $PD.NewRecord.Name -Type $PD.NewRecord.Type @CommonParams
            }
            It "removes specified record set from a zone (pipeline)" {
                $PD.NewRecords | Remove-EDNSRecordSet -Zone $Zone @CommonParams
                $PD.NewRecordPipeline | Remove-EDNSRecordSet -Zone $Zone @CommonParams
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
            $ZoneCreation = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
            # Wait for creation to complete
            while (-not $Status.isComplete) {
                $Status = Get-EDNSZoneBulkCreateStatus -RequestID $ZoneCreation.requestId @CommonParams
                Start-Sleep -Seconds 3
                Write-Host -ForegroundColor Yellow "Waiting for zone creation to complete..."
            }
            Start-Sleep -Seconds 3
        }
        Context "Get-EDNSTSIGKey" {
            It "returns all TSIG keys" {
                $Result = Get-EDNSTSIGKey @CommonParams -Search md5 -SortBy name -ContractIDs $TestContractId
                $Result | Should -Not -BeNullOrEmpty
                $Algorithms = $Result.algoritm | Sort-Object | Get-Unique
                $Algorithms | ForEach-Object {
                    $_.ToLower() | Should -BeLike "hmac-md5*"
                }
            }
            It "returns a TSIG key for specified zone (parameter)" {
                $Result = Get-EDNSTSIGKey @CommonParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns a TSIG key for specified zone (pipeline)" {
                $Result = $BodySecondaryObject.zone | Get-EDNSTSIGKey @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSTSIGKey" {
            It "updates TSIG key data for specified zone (parameter)" {
                $Result = Set-EDNSTSIGKey @CommonParams -Zones $BodySecondaryObject.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for specified zone (pipeline)" {
                $Body = @{
                    zones = @($BodySecondaryObject.zone)
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (parameter)" {
                $Result = Set-EDNSTSIGKey @CommonParams -Zones $Zones.zones.zone -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -BeNullOrEmpty
            }
            It "updates TSIG key data for multiple zones (pipeline)" {
                $Body = @{
                    zones = $Zones.zones.zone
                    key   = $BodySecondaryObject.tsigKey
                }
                $Result = $Body | Set-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSTSIGKeyUsedBy" {
            It "returns all zone names using specified TSIG key (parameter)" {
                $Result = Get-EDNSTSIGKeyUsedBy @CommonParams -TSIGKeyAlgorithm $BodySecondaryObject.TSIGKey.algorithm -TSIGKeyName $BodySecondaryObject.TSIGKey.name -TSIGKeySecret $BodySecondaryObject.TSIGKey.secret
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using specified TSIG key (pipeline)" {
                $Result = $BodySecondaryObject.TSIGKey | Get-EDNSTSIGKeyUsedBy @CommonParams
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
            It "returns all zone names using the same TSIG key as specified zone (parameter)" {
                $Result = Get-EDNSTSIGKeyUsedBy @CommonParams -Zone $BodySecondaryObject.zone
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeGreaterThan 1
            }
        }
        Context 'Get-EDNSTSIGKeyContract' {
            It 'returns in the right format' {
                $TestParams = @{
                    TSIGKeyAlgorithm = $BodySecondaryObject.TSIGKey.algorithm
                    TSIGKeyName      = $BodySecondaryObject.TSIGKey.name
                    TSIGKeySecret    = $BodySecondaryObject.TSIGKey.secret

                }
                $PD.TSIGKeyContract = Get-EDNSTSIGKeyContract @TestParams @CommonParams
                $PD.TSIGKeyContract.contractId | Should -Be $TestContractID
                $PD.TSIGKeyContract.zoneNames.zones | Should -Contain $BodySecondaryObject.zone
            }
        }
        Context "Remove-EDNSTSIGKey" {
            It "removes the TSIG key for specified zone (parameter)" {
                $Result = Remove-EDNSTSIGKey @CommonParams -Zone $Zones.zones.zone[0]
                $Result | Should -BeNullOrEmpty
            }
            It "removes the TSIG key for specified zone (pipeline)" {
                $Result = $Zones.zones.zone[1] | Remove-EDNSTSIGKey @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        AfterAll {
            New-EDNSZoneBulkDelete @CommonParams -Zones $Zones.zones.zone -BypassSafetyChecks
        }
    }
    
    Describe "Bulk Zone Operations" -Tag "Done" {
        Context "New-EDNSZoneBulkCreate (Single Zone)" {
            BeforeEach {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
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
                New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EDNSZoneBulkCreate (Multi Zone)" {
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
                New-EDNSZoneBulkDelete @CommonParams -Zones $Zones.zones.zone -BypassSafetyChecks
            }
        }
        Context "Get-EDNSZoneBulkCreateStatus" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EDNSZoneBulkCreateStatus @CommonParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EDNSZoneBulkCreateStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "Get-EDNSZoneBulkCreateResult" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                $CreateResult = New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EDNSZoneBulkCreateResult @CommonParams -RequestID $CreateResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $CreateResult | Get-EDNSZoneBulkCreateResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            AfterAll {
                New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
            }
        }
        Context "New-EDNSZoneBulkDelete (Single zone)" {
            BeforeEach {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone
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
                    zones = @()
                } 
                for ($i = 0; $i -lt 2; $i++) {
                    $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                    $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                    $Zones.zones += $BodyPrimaryObject.psobject.Copy()
                    Start-Sleep -Milliseconds 100
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
            }
            It "creates a new zone delete request (parameter)" {
                $Result = New-EDNSZoneBulkDelete @CommonParams -Zones $Zones.zones.zone
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
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EDNSZoneBulkDeleteStatus @CommonParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EDNSZoneBulkDeleteStatus @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneBulkDeleteResult" {
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                $BodyPrimaryObject.zone = "primary-bulk-$Timestamp.pwsh.test"
                $Zones = @{
                    zones = @($BodyPrimaryObject)
                }
                New-EDNSZoneBulkCreate @CommonParams -ContractID $TestContractId -GroupID $TestGroupId -Body $Zones
                Start-Sleep -Seconds 3
                $DeleteResult = New-EDNSZoneBulkDelete @CommonParams -Zones $BodyPrimaryObject.zone -BypassSafetyChecks
                while (-not $Status.isComplete) {
                    $Status = Get-EDNSZoneBulkDeleteStatus -RequestID $DeleteResult.requestId @CommonParams
                    Start-Sleep -s 3
                    Write-Host -ForegroundColor Yellow "Waiting for zone deletion to complete..."
                }
                Start-Sleep -Seconds 3
            }
            It "returns details for specified request ID (parameter)" {
                $Result = Get-EDNSZoneBulkDeleteResult @CommonParams -RequestID $DeleteResult.requestId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified request ID (pipeline, ByPropertyName)" {
                $Result = $DeleteResult | Get-EDNSZoneBulkDeleteResult @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Change Lists" -Tag "Done" {
        Context "New-EDNSChangeList" {
            It "creates a new changelist (parameter)" {
                $Result = New-EDNSChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeList" {
            It "returns details for all changelists" {
                $Result = Get-EDNSChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EDNSChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSChangeList @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListSettings" {
            It "returns changelist details for specified zone (parameter)" {
                $Result = Get-EDNSChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSChangeListSettings @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSChangeListSettings" {
            It "updates changelist with specified zone settings (parameter)" {
                $Settings = Get-EDNSChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Settings.endCustomerID = 77777
                $Result = $Settings | Set-EDNSChangeListSettings @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSet" {
            It "returns all changelist record sets for specified zone (parameter)" {
                $Result = Get-EDNSChangeListRecordSet @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns changelist record sets of selected type for specified zone (parameter)" {
                $Result = Get-EDNSChangeListRecordSet @CommonParams -Zone $TestZonePrimary -Types NS, SOA
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSetNames" {
            It "returns changelist record set names for specified zone (parameter)" {
                $Result = Get-EDNSChangeListRecordSetNames @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListRecordSetTypes" {
            It "returns changelist record set types for specified zone and record name (parameter)" {
                $Result = Get-EDNSChangeListRecordSetTypes @CommonParams -Zone $TestZonePrimary -Name $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Set-EDNSChangeListRecordSet" {
            It "modifies record set for a changelist (parameter)" {
                $RecordSetName = "info.primary.pwsh.test"
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
                # $RecordSetName = 'info.' -join $TestZonePrimary
                $Result = Set-EDNSChangeListRecordSet @CommonParams -Zone $TestZonePrimary -Name $RecordSetName -Type TXT -Op EDIT -TTL 60 -RData "This is a PWSH Pester test $Timestamp"
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSChangeListDiff" {
            It "shows changes between current changelist and active record set" {
                $Result = Get-EDNSChangeListDiff @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context 'Find-EDNSChangeList' {
            It 'returns the correct change list' {
                $PD.FindChangeList = Find-EDNSChangeList -Zone $TestZonePrimary @CommonParams
                $PD.FindChangeList[0].zone | Should -Be $TestZonePrimary
                $PD.FindChangeList[0].zoneVersionId | Should -Not -BeNullOrEmpty
            }
        }
        Context "Submit-EDNSChangeList" {
            It "submits changelist (paramter)" {
                $Result = Submit-EDNSChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
                Start-Sleep -Seconds 2
            }
        }
        Context "Set-EDNSChangeListMasterFile" {
            BeforeAll {
                New-EDNSChangeList @CommonParams -Zone $TestZonePrimary
            }
            It "uploads master zone file to changelist (paramter)" {
                $ZoneFile = Get-EDNSMasterFile @CommonParams -Zone $TestZonePrimary
                $Result = Set-EDNSChangeListMasterFile @CommonParams -Zone $TestZonePrimary -Body $ZoneFile
                $Result | Should -BeNullOrEmpty
            }
            It "uploads master zone file to changelist (pipeline)" {
                $ZoneFile = Get-EDNSMasterFile @CommonParams -Zone $TestZonePrimary
                $Result = $ZoneFile | Set-EDNSChangeListMasterFile @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Remove-EDNSChangeList" {
            It "removes an existing changelist (parameter)" {
                $Result = Remove-EDNSChangeList @CommonParams -Zone $TestZonePrimary
                $Result | Should -BeNullOrEmpty
            }
        }
    }
    
    Describe "Zone Versions" -Tag "Done" {
        Context "Get-EDNSZoneVersion" {
            It "returns all details for specified zone (parameter)" {
                $Result = Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSZoneVersion @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified version id of a zone (parameter)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -HaveCount 1
            }
        }
        Context "Compare-EDNSZoneVersion" {
            It "returns diff details for specified zone versions (parameter)" {
                $From = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $To = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[1]
                $Result = Compare-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary -From $From -To $To
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneVersionRecordSet" {
            It "returns all details for specified zone version (parameter)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EDNSZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns all details for specified zone version (pipeline)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EDNSZoneVersionRecordSet @CommonParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (array, parameter)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EDNSZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID -Types @("SOA", "NS") -SortBy @("name", "type")
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns sorted and filtered details for specified zone version (string, parameter)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EDNSZoneVersionRecordSet @CommonParams -Zone $TestZonePrimary -VersionID $VersionID -Types "SOA,NS" -SortBy "name,type"
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Restore-EDNSZoneVersion" {
            It "restores specified zone version (parameter)" {
                $VersionID = $(Get-EDNSZoneVersion -Zone $TestZonePrimary @CommonParams | Sort-Object lastActivationDate -Descending).versionId[1]
                $Result = Restore-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -BeNullOrEmpty
            }
            It "restores specified zone version (pipeline, ByPropertyName)" {
                $OldVersion = $(Get-EDNSZoneVersion -zone $TestZonePrimary @CommonParams | Sort-Object lastActivationDate -Descending)[1]
                $Result = $OldVersion | Restore-EDNSZoneVersion @CommonParams
                $Result | Should -BeNullOrEmpty
            }
        }
        Context "Get-EDNSZoneVersionMasterFile" {
            It "returns Master Zone file for specified zone version (parameter)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = Get-EDNSZoneVersionMasterFile @CommonParams -Zone $TestZonePrimary -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline)" {
                $VersionID = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary).versionid[0]
                $Result = $TestZonePrimary | Get-EDNSZoneVersionMasterFile @CommonParams -VersionID $VersionID
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns Master Zone file for specified zone version (pipeline, ByPropertyName)" {
                $ZoneVersion = $(Get-EDNSZoneVersion @CommonParams -Zone $TestZonePrimary)[0]
                $Result = $ZoneVersion | Get-EDNSZoneVersionMasterFile @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Describe "Data Services" -Tag "Done" {
        Context "Get-EDNSAuthority" {
            It "returns details for specified contract IDs (string, parameter)" {
                $Result = Get-EDNSAuthority @CommonParams -ContractID "$TestContractID,$TestContractID"
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (string, pipeline)" {
                $Result = "$TestContractID,$TestContractID" | Get-EDNSAuthority @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, parameter)" {
                $Result = Get-EDNSAuthority @CommonParams -ContractID @($TestContractID, $TestContractID)
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract IDs (array, pipeline)" {
                $Result = @($TestContractID, $TestContractID) | Get-EDNSAuthority @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSContracts" {
            It "returns details of all contracts" {
                $Result = Get-EDNSContracts @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EDNSContracts @CommonParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified contract ID (pipeline)" {
                $Result = $TestGroupId | Get-EDNSContracts @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSDNSSECAlgorithms" {
            It "returns DNSSEC Algorithm list" {
                $Result = Get-EDNSDNSSECAlgorithms @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSEdgeHostnames" {
            It "returns Edge hostname list" {
                $Result = Get-EDNSEdgeHostnames @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSGroups" {
            It "returns details for all groups" {
                $Result = Get-EDNSGroups @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (parameter)" {
                $Result = Get-EDNSGroups @CommonParams -GroupID $TestGroupId
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified group ID (pipeline)" {
                $Result = $TestGroupId | Get-EDNSGroups @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }        
        Context "Get-EDNSRecordSetTypes" {
            It "returns details for specified zone (parameter)" {
                $Result = Get-EDNSRecordSetTypes @CommonParams -Zone $TestZonePrimary
                $Result | Should -Not -BeNullOrEmpty
            }
            It "returns details for specified zone (pipeline)" {
                $Result = $TestZonePrimary | Get-EDNSRecordSetTypes @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
        Context "Get-EDNSTSIGAlgorithms" {
            It "returns TSIG Algorithm list" {
                $Result = Get-EDNSTSIGAlgorithms @CommonParams
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Describe "Proxies" -Tag "Proxies" {
        Context "Get-EDNSProxy" {
            It "lists alls proxies" {
                $PD.Proxies = Get-EDNSProxy @CommonParams
                $PD.Proxies[0].id | Should -not -BeNullOrEmpty
                $PD.Proxies[0].name | Should -not -BeNullOrEmpty
                $PD.Proxies[0].authorities | Should -not -BeNullOrEmpty
            }

            It 'retrieves a specific proxy' {
                $PD.Proxy = Get-EDNSProxy -ProxyID $TestProxyID @CommonParams
                $PD.Proxy.id | Should -Be $TestProxyID
                $PD.Proxy.name | Should -Be $TestProxyName
                $PD.Proxy.authorities | Should -not -BeNullOrEmpty
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
                    ProxyID = $PD.Proxy.ID
                    Body    = $PD.Proxy | ConvertTo-Json
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
            BeforeAll {
                $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)
            }
            Context 'New-EDNSProxyZone' {
                It 'creates successfully by attributes' {
                    $TestParams = @{
                        ProxyID    = $PD.Proxy.Id
                        Name       = "powershell-test1-$Timestamp.test"
                        FilterMode = 'MANUAL'
                    }
                    $PD.NewProxyZoneAttribute = New-EDNSProxyZone @TestParams @CommonParams
                    $PD.NewProxyZoneAttribute.requestId | Should -Not -BeNullOrEmpty
                    $PD.NewProxyZoneAttribute.expirationDate | Should -Not -BeNullOrEmpty
                }
                It 'creates successfully by body' {
                    $Body = @{
                        'proxyZones' = @(
                            @{
                                name       = "powershell-test2-$Timestamp.test"
                                filterMode = 'NONE'
                            }
                            @{
                                name       = "powershell-test3-$Timestamp.test"
                                filterMode = 'AUTOMATIC'
                                tsigKey    = @{
                                    name      = "powershell-tsig1-$Timestamp"
                                    algorithm = 'hmac-sha256'
                                    secret    = (ConvertTo-Base64 -UnencodedString "This is a super-secret secret!")
                                }
                            }
                        )
                    }
                    $TestParams = @{
                        ProxyID = $PD.Proxy.Id
                        Body    = $Body
                    }
                    $PD.NewProxyZoneBody = New-EDNSProxyZone @TestParams @CommonParams
                    $PD.NewProxyZoneBody.requestId | Should -Not -BeNullOrEmpty
                    $PD.NewProxyZoneBody.expirationDate | Should -Not -BeNullOrEmpty
                }
            }

            Context 'Get-EDNSProxyZoneCreateStatus' {
                It 'returns the correct data' {
                    $TestParams = @{
                        ProxyID   = $PD.Proxy.Id
                        RequestID = $PD.NewProxyZoneBody.requestId
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
            }

            Context 'Get-EDNSProxyZoneCreateResult' {
                It 'returns the correct data' {
                    $TestParams = @{
                        ProxyID   = $PD.Proxy.Id
                        RequestID = $PD.NewProxyZoneBody.requestId
                    }
                    $PD.ProxyZoneCreateResult = Get-EDNSProxyZoneCreateResult @TestParams @CommonParams
                    $PD.ProxyZoneCreateResult.requestId | Should -Be $PD.NewProxyZoneBody.requestId
                    $PD.ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test2-$Timestamp.test"
                    $PD.ProxyZoneCreateResult.successfullyCreatedZones | Should -Contain "powershell-test3-$Timestamp.test"
                }
            }

            Context 'Get-EDNSProxyZone' {
                It 'returns a list of zones' {
                    $PD.ProxyZones = Get-EDNSProxyZone -ProxyID $PD.Proxy.Id @CommonParams
                    $PD.ProxyZones.count | Should -Be 3
                    $PD.ProxyZones[0].Name | Should -Not -BeNullOrEmpty
                    $PD.ProxyZones[0].filterMode | Should -Not -BeNullOrEmpty
                }

                It 'retrieves a single proxy zone by name' {
                    $PD.ProxyZone = Get-EDNSProxyZone -ProxyID $PD.Proxy.Id -Name $PD.ProxyZones[0].Name @CommonParams
                    $PD.ProxyZone.name | Should -Be $PD.ProxyZones[0].Name
                    $PD.ProxyZone.filterMode | Should -Be $PD.ProxyZones[0].filterMode
                }
            }

            Context 'Set-EDNSProxyZoneTSIGKey' {
                It 'updates correctly' {
                    $TestParams = @{
                        ProxyID          = $PD.Proxy.Id
                        Name             = $PD.ProxyZones[2].Name
                        TSIGKeyAlgorithm = 'hmac-sha256'
                        TSIGKeyName      = "powershell-tsig2-$Timestamp"
                        TSIGKeySecret    = ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!"
                    }
                    Set-EDNSProxyZoneTSIGKey @TestParams @CommonParams   
                }
            }

            Context 'Get-EDNSProxyZoneTSIGKey' {
                It 'retrieves the keys correctly' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIG = Get-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                    $PD.ProxyZoneTSIG.name | Should -Be "powershell-tsig2-$Timestamp"
                    $PD.ProxyZoneTSIG.algorithm | Should -Be 'hmac-sha256'
                    $PD.ProxyZoneTSIG.secret | Should -Be (ConvertTo-Base64 -UnencodedString "shhhhhhhhhhh!")
                }
            }

            Context 'Get-EDNSProxyZoneTSIGKeyUsedBy' {
                It 'retrieves the keys correctly' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[2].Name
                    }
                    $PD.ProxyZoneTSIGUsedBy = Get-EDNSProxyZoneTSIGKeyUsedBy @TestParams @CommonParams
                    $PD.ProxyZoneTSIGUsedBy.name | Should -Be $TestProxyName
                    $PD.ProxyZoneTSIGUsedBy.id | Should -Be $TestProxyID
                }
            }

            Context 'Remove-EDNSProxyZoneTSIGKey' {
                It 'removes successfully' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[2].Name
                    }
                    Remove-EDNSProxyZoneTSIGKey @TestParams @CommonParams
                }
            }

            Context 'Add-EDNSProxyZoneManualFilterName' {
                It 'adds a filter name correctly' {
                    $TestParams = @{
                        ProxyID     = $PD.Proxy.id
                        Name        = $PD.ProxyZones[0].Name
                        FilterNames = @(
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
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[0].Name
                        Body    = @{
                            add    = @(
                                "addfiltername1.$($PD.ProxyZones[0].Name)"
                                "addfiltername2.$($PD.ProxyZones[0].Name)"
                            )
                            delete = @(
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
                It 'lists manual filters' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[0].Name
                    }
                    $PD.ManualFilters = Get-EDNSProxyZoneManualFilterReport @TestParams @CommonParams
                    $PD.ManualFilters[0] | Should -BeLike '*filtername*'
                }
            }

            Context 'Remove-EDNSProxyZoneManualFilterName' {
                It 'removes a filter name correctly' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[0].Name
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
                    "`$TTL 2d    ; default TTL for zone
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
ftp        IN      A       1.2.3.4" | Out-File $ZoneFile
                }
                It 'sets filter names from a zone file' {
                    $TestParams = @{
                        ProxyID  = $PD.Proxy.id
                        Name     = $PD.ProxyZones[0].Name
                        ZoneFile = $ZoneFile
                    }
                    $PD.ZoneFilterFromFile = Set-EDNSProxyZoneManualFilterNames @TestParams @CommonParams
                    $PD.ZoneFilterFromFile.deleteCount | Should -Be 0
                    $PD.ZoneFilterFromFile.addCount | Should -Be 6
                }
                AfterAll {
                    $RemoveParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[0].Name
                    }
                    Get-EDNSProxyZoneManualFilterReport @RemoveParams @CommonParams | Remove-EDNSProxyZoneManualFilterName @RemoveParams @CommonParams
                }
            }

            Context 'Set-EDNSProxyZoneApexAlias' {
                It 'creates an apex successfully' {
                    $TestParams = @{
                        ProxyID   = $PD.Proxy.id
                        Name      = $PD.ProxyZones[0].Name
                        ApexAlias = "apex.$($PD.ProxyZones[0].Name)"
                    }
                    Set-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }
            
            Context 'Remove-EDNSProxyZoneApexAlias' {
                It 'creates an apex successfully' {
                    $TestParams = @{
                        ProxyID = $PD.Proxy.id
                        Name    = $PD.ProxyZones[0].Name
                    }
                    Remove-EDNSProxyZoneApexAlias @TestParams @CommonParams
                }
            }

            Context 'Set-EDNSProxyZoneFilterMode' {
                Context 'to manual' {
                    It 'converts successfully' {
                        $TestParams = @{
                            ProxyID           = $PD.Proxy.id
                            Mode              = 'MANUAL'
                            Name              = $PD.ProxyZones[1].Name
                            ManualFilterNames = "conversion.$($PD.ProxyZones[1].Name)"
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
                
                Context 'to automatic' {
                    It 'converts successfully' {
                        $TestParams = @{
                            ProxyID          = $PD.Proxy.id
                            Mode             = 'AUTOMATIC'
                            Name             = $PD.ProxyZones[1].Name
                            TSIGKeyAlgorithm = 'hmac-sha256'
                            TSIGKeyName      = "conversion-key1-$Timestamp"
                            TSIGKeySecret    = ConvertTo-Base64 -UnencodedString 'there can be only one'
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
                
                Context 'to all' {
                    It 'converts successfully' {
                        $TestParams = @{
                            ProxyID = $PD.Proxy.id
                            Mode    = 'ALL'
                            Name    = $PD.ProxyZones[1].Name
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
                
                Context 'to none' {
                    It 'converts successfully' {
                        $TestParams = @{
                            ProxyID = $PD.Proxy.id
                            Mode    = 'NONE'
                            Name    = $PD.ProxyZones[1].Name
                        }
                        Convert-EDNSProxyZone @TestParams @CommonParams
                    }
                }
            }

            Context 'Remove-EDNSProxyZone' {
                It 'removes a single zone successfully by params' {
                    $TestParams = @{
                        ProxyID            = $PD.Proxy.Id
                        BypassSafetyChecks = $true
                        ProxyZones         = $PD.ProxyZones[0].Name
                        Comment            = "Deleting with Pester"
                    }
                    $PD.RemoveProxyZoneParam = Remove-EDNSProxyZone @TestParams @CommonParams
                    $PD.RemoveProxyZoneParam.requestId | Should -Not -BeNullOrEmpty
                    $PD.RemoveProxyZoneParam.expirationDate | Should -Not -BeNullOrEmpty
                }
                It 'removes multiple zones by the pipeline' {
                    $TestParams = @{
                        ProxyID            = $PD.Proxy.Id
                        BypassSafetyChecks = $true
                        Comment            = "Deleting with Pester"
                    }
                    $PD.RemoveProxyZonePipeline = $PD.ProxyZones[1..2] | Remove-EDNSProxyZone @TestParams @CommonParams
                    $PD.RemoveProxyZonePipeline.requestId | Should -Not -BeNullOrEmpty
                    $PD.RemoveProxyZonePipeline.expirationDate | Should -Not -BeNullOrEmpty
                }
            }

            Context 'Get-EDNSProxyZoneDeleteStatus' {
                It 'returns the correct data' {
                    $TestParams = @{
                        ProxyID   = $PD.Proxy.Id
                        RequestID = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $PD.ProxyZoneDeleteStatus = Get-EDNSProxyZoneDeleteStatus @TestParams @CommonParams
                    $PD.ProxyZoneDeleteStatus.zonesSubmitted | Should -Be 2
                    $PD.ProxyZoneDeleteStatus.isComplete | Should -Not -BeNullOrEmpty

                    while ($PD.ProxyZoneDeleteStatus.isComplete -ne $true) {
                        Start-Sleep -s 15
                        $PD.ProxyZoneDeleteStatus = Get-EDNSProxyZoneDeleteStatus @TestParams @CommonParams
                    }
                }
            }

            Context 'Get-EDNSProxyZoneDeleteResult' {
                It 'returns the correct data' {
                    $TestParams = @{
                        ProxyID   = $PD.Proxy.Id
                        RequestID = $PD.RemoveProxyZonePipeline.requestId
                    }
                    $PD.ProxyZoneDeleteResult = Get-EDNSProxyZoneDeleteResult @TestParams @CommonParams
                    $PD.ProxyZoneDeleteResult.requestId | Should -Be $PD.RemoveProxyZonePipeline.requestId
                    $PD.ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[1].Name
                    $PD.ProxyZoneDeleteResult.successfullyDeletedZones | Should -Contain $PD.ProxyZones[2].Name
                }
            }
        }
    }
}