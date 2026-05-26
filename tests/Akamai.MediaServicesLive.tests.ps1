BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.MediaServicesLive Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.MediaServicesLive'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestHostname = "pester.akamaiorigin.net"
        $TestHostnamePrefix = "pester"
        $TestStreamName = "pester-$Timestamp"
        $TestNewStream = @"
{
    "name": "$TestStreamName",
    "contractId": "$TestContractID",
    "format": "HLS",
    "cpcode": 12345,
    "ingestAccelerated": false,
    "encoderZone": "EUROPE",
    "backupEncoderZone": "AUSTRALIA",
    "isDedicatedOrigin": false,
    "activeArchiveDurationInDays": 2,
    "groupId": $TestGroupID,
    "allowedIps": [
        "192.0.2.19"
    ],
    "additionalEmailIds": [
        "mail@example.com"
    ],
    "origin": {
        "hostName": "$Timestamp"
    },
    "streamAuth": {
        "username": "YouShallNot",
        "password": "PaS5!",
        "algorithm": "SHA512"
    }
}
"@ | ConvertFrom-Json
        $TestNewOrigin = @"
{
    "contractId": "$TestContractID",
    "hostName": "$TestHostname",
    "cpcode": 123456,
    "encoderZone": "US_EAST",
    "backupEncoderZone": "EUROPE",
    "groupId": $TestGroupID,
    "emailIds": [
        "mail@example.com"
    ],
    "sharedKeys": [
        {
            "type": "AKAMAI",
            "authMethod": "MSL_MULTI_ACCOUNT",
            "name": "pwsh",
            "key": "7153f558f89e058ae",
            "enabled": true
        }
    ]
}
"@ | ConvertFrom-Json
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.MediaServicesLive"
        $PD = @{}
    }

    AfterAll {
        Get-MSLStream @CommonParams | Where-Object name -eq $TestStreamName | Remove-MSLStream @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 Contract                  
    #------------------------------------------------

    Context 'Get-MSLContract' {
        It 'lists contracts' {
            $PD.Contracts = Get-MSLContract @CommonParams
            $PD.Contracts[0].contractId | Should -Be $TestContractID
            $PD.Contracts[0].accountId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CPCodes                  
    #------------------------------------------------
    
    Context 'Get-MSLCPCode' {
        It 'lists cpcodes' {
            $TestParams = @{
                'Type' = 'INGEST'
            }
            $PD.CpCodes = Get-MSLCPCode @TestParams @CommonParams
            $PD.CpCodes[0].id | Should -Match '[\d]+'
        }
    }

    #------------------------------------------------
    #                 Keys                  
    #------------------------------------------------
    
    Context 'New-MSLKey' {
        It 'creates a new key' {
            $PD.Key = New-MSLKey @CommonParams
            $PD.Key.key | Should -Match '[a-zA-Z0-9+=\/]+'
        }
    }

    #------------------------------------------------
    #                 Origins                  
    #------------------------------------------------
    
    Context 'Get-MSLOrigin' {
        It 'lists origin objects' {
            $PD.Origins = Get-MSLOrigin @CommonParams
            $PD.Origins[0].id | Should -Not -BeNullOrEmpty
            $PD.Origins[0].hostName | Should -Not -BeNullOrEmpty
            $PD.NewOrigin = $PD.origins | Where-Object hostNameIdentifier -eq $TestHostnamePrefix
            $PD.NewOrigin | Should -Not -BeNullOrEmpty
        }
        It 'gets a single origin' {
            $TestParams = @{
                'OriginID' = $PD.NewOrigin.id
            }
            $PD.Origin = Get-MSLOrigin @TestParams @CommonParams
            $PD.Origin.id | Should -Be $PD.NewOrigin.id
            $PD.Origin.cpcode | Should -Be $PD.CpCodes[0].id
        }
    }
    
    Context 'Get-MSLOriginCPCode' {
        It 'returns the expected list' {
            $PD.OriginCPCodes = Get-MSLOriginCPCode @CommonParams
            $PD.OriginCPCodes[0].id | Should -Not -BeNullOrEmpty
            $PD.OriginCPCodes[0].contractIds[0] | Should -Be $TestContractID
        }
    }
    
    Context 'Set-MSLOrigin' {
        It 'updates by param' {
            $TestParams = @{
                'OriginID' = $PD.Origin.id
                'Body'     = $PD.Origin
            }
            Set-MSLOrigin @TestParams @CommonParams
        }
        It 'updates by pipeline' {
            $PD.Origin | Set-MSLOrigin @CommonParams
        }
    }

    #------------------------------------------------
    #             Publishing Locations
    #------------------------------------------------
    
    Context 'Get-MSLPublishingLocations' {
        It 'lists locations' {
            $PD.Locations = Get-MSLPublishingLocations @CommonParams
            $PD.Locations[0].location | Should -Not -BeNullOrEmpty
            $PD.Locations[0].code | Should -Not -BeNullOrEmpty
            $PD.Locations[0].netstorageZone | Should -Not -BeNullOrEmpty
            $PD.Locations[0].ingestLocations | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                   Streams                
    #------------------------------------------------
    
    Context 'New-MSLStream' {
        It 'creates a new stream' {
            $TestNewStream.cpcode = $PD.CpCodes[0].id
            $TestNewStream | New-MSLStream @CommonParams
        }
    }

    Context 'Get-MSLStream' {
        It 'lists stream objects' {
            $PD.Streams = Get-MSLStream @CommonParams
            $PD.Streams[0].id | Should -Not -BeNullOrEmpty
            $PD.Streams[0].cpcode | Should -Not -BeNullOrEmpty
            $PD.TestNewStream = $PD.Streams | Where-Object name -eq $TestStreamName
            $PD.TestNewStream | Should -Not -BeNullOrEmpty
        }
        It 'gets a single stream' {
            $PD.Stream = $PD.TestNewStream | Get-MSLStream @CommonParams
            $PD.Stream.id | Should -Be $PD.TestNewStream.id
            $PD.Stream.name | Should -Be $TestStreamName
            $PD.Stream.cpcode | Should -Be $PD.CpCodes[0].id
        }
    }
    

    Context 'Set-MSLStream by Pipeline' {
        It 'updates by param' {
            $TestParams = @{
                'StreamID' = $PD.Stream.id
                'Body'     = $PD.Stream
            }
            Set-MSLStream @TestParams @CommonParams
        }
        It 'updates by pipeline' {
            $PD.Stream | Set-MSLStream @CommonParams
        }
    }
    
    Context 'Remove-MSLStream' {
        It 'deletes successfully' {
            $TestParams = @{
                'StreamID' = $PD.Stream.id
            }
            Remove-MSLStream @TestParams @CommonParams
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-MSLStream
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 CDNs                  
    #------------------------------------------------
    
    Context 'Get-MSLCDN' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLCDN.json"
                return $Response | ConvertFrom-Json
            }
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLCDN.json"
                return $Response | ConvertFrom-Json
            }
            $PD.CDNs = Get-MSLCDN
            $PD.CDNs[0].code | Should -Not -BeNullOrEmpty
            $PD.CDNs[0].name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CPCodes                  
    #------------------------------------------------

    Context 'New-MSLCPCode' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MSLCPCode.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Name'       = 'Test'
                'ContractID' = $TestContractID
            }
            $PD.NewCPCode = New-MSLCPCode @TestParams
            $PD.NewCPCode.id | Should -Not -BeNullOrEmpty
            $PD.NewCPCode.name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                   VOD Origins                
    #------------------------------------------------

    Context 'Get-MSLPublishingLocations' {
        It 'lists vod origins' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLVODOrigin.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'EncoderLocation' = 'Europe'
            }
            $PD.VODOrigins = Get-MSLVODOrigin @TestParams
            $PD.VODOrigins[0].cpcode | Should -Not -BeNullOrEmpty
            $PD.VODOrigins[0].name | Should -Not -BeNullOrEmpty
            $PD.VODOrigins[0].streamCount | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Origins                  
    #------------------------------------------------
    
    Context 'New-MSLOrigin' {
        It 'creates a new origin' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MSLOrigin.json"
                return $Response | ConvertFrom-Json
            }
            $TestNewOrigin | New-MSLOrigin
        }
    }

    Context 'Remove-MSLOrigin' {
        It 'deletes successfully' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-MSLOrigin.json"
                return $Response | ConvertFrom-Json
            }
            123456 | Remove-MSLOrigin
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                return 'IAR executed'
            }
            $Result = & {} | Remove-MSLOrigin
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #                 Migration                  
    #------------------------------------------------

    Context 'Migration' -Tag 'Migration' {
        Context 'New-MSLMigration' {
            It 'initiates a migration' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/New-MSLMigration.json"
                    return $Response | ConvertFrom-Json
                }
                $TestParams = @{
                    'StreamIDs'   = 12345
                    'MSL5APIKey'  = 'testkey'
                    MigrationType = 'HARD'
                }
                $PD.Migration = New-MSLMigration @TestParams
                $PD.Migration.migrationId | Should -Not -BeNullOrEmpty
            }
        }
    
        Context 'Get-MSLMigration' {
            It 'retrieves migration status' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLMigration.json"
                    return $Response | ConvertFrom-Json
                }
                $PD.MigrationStatus = Get-MSLMigration @TestParams
                $PD.MigrationStatus.streams[0].streamId | Should -Not -BeNullOrEmpty
                $PD.MigrationStatus.streams[0].migrationType | Should -Not -BeNullOrEmpty
            }
        }
    
        Context 'Undo-MSLMigration' {
            It 'reverts a migration' {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.MediaServicesLive -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Undo-MSLMigration.json"
                    return $Response | ConvertFrom-Json
                }
                $TestParams = @{
                    'StreamIDs'  = 12345
                    'MSL5APIKey' = 'testkey'
                }
                $PD.UndoMigration = Undo-MSLMigration @TestParams
                $PD.UndoMigration.reverseMigrationId | Should -Not -BeNullOrEmpty
            }
        }
    }
}

