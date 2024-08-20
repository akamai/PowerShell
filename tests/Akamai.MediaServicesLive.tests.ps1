Describe 'Safe Akamai.MediaServicesLive Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.MediaServicesLive/Akamai.MediaServicesLive.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestHostname = 'akamaipowershell.akamaiorigin.net'
        $TestHostnamePrefix = 'akamaipowershell'
        $TestStreamName = 'pwshstream'
        
        $TestNewStream = @"
{
    "name": "$TestStreamName",
    "contractId": "$TestContract",
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
        "hostName": "$TestStreamName",
        "cpcode": 12345
    },
    "streamAuth": {
        "username": "YouShallNot",
        "password": "PaS5!",
        "algorithm": "SHA512"
    }
}
"@ | ConvertFrom-Json
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 Contract                  
    #------------------------------------------------

    Context 'Get-MSLContract' {
        It 'lists contracts' {
            $PD.Contracts = Get-MSLContract @CommonParams
            $PD.Contracts[0].contractId | Should -Be $TestContract
            $PD.Contracts[0].accountId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 CPCodes                  
    #------------------------------------------------
    
    Context 'Get-MSLCPCode' {
        It 'lists cpcodes' {
            $PD.CpCodes = Get-MSLCPCode -Type INGEST @CommonParams
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
    
    Context 'Get-MSLOrigin - All' {
        It 'lists origin objects' {
            $PD.Origins = Get-MSLOrigin @CommonParams
            $PD.Origins[0].id | Should -Not -BeNullOrEmpty
            $PD.Origins[0].hostName | Should -Not -BeNullOrEmpty
            $PD.NewOrigin = $PD.origins | Where-Object hostNameIdentifier -eq $TestHostnamePrefix
            $PD.NewOrigin | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-MSLOrigin - Single' {
        It 'gets the correct object' {
            $PD.Origin = Get-MSLOrigin -OriginID $PD.NewOrigin.id @CommonParams
            $PD.Origin.id | Should -Be $PD.NewOrigin.id
            $PD.Origin.cpcode | Should -Be $PD.CpCodes[0].id
        }
    }
    
    Context 'Get-MSLOriginCPCode' {
        It 'returns the expected list' {
            $PD.OriginCPCodes = Get-MSLOriginCPCode @CommonParams
            $PD.OriginCPCodes[0].id | Should -Not -BeNullOrEmpty
            $PD.OriginCPCodes[0].contractIds[0] | Should -Be $TestContract
        }
    }
    
    Context 'Set-MSLOrigin by Pipeline' {
        It 'updates successfully' {
            $PD.Origin | Set-MSLOrigin @CommonParams
        }
    }
    
    Context 'Set-MSLOrigin by Param' {
        It 'updates successfully' {
            Set-MSLOrigin -OriginID $PD.Origin.id -Body $PD.Origin @CommonParams
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
            $TestNewStream.origin.cpcode = $PD.CpCodes[0].id
            New-MSLStream -Body $TestNewStream @CommonParams
        }
    }

    Context 'Get-MSLStream - All' {
        It 'lists stream objects' {
            $PD.Streams = Get-MSLStream @CommonParams
            $PD.Streams[0].id | Should -Not -BeNullOrEmpty
            $PD.Streams[0].cpcode | Should -Not -BeNullOrEmpty
            $PD.TestNewStream = $PD.Streams | Where-Object name -eq $TestStreamName
            $PD.TestNewStream | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-MSLStream - Single' {
        It 'gets the correct object' {
            $PD.Stream = Get-MSLStream -StreamID $PD.TestNewStream.id @CommonParams
            $PD.Stream.id | Should -Be $PD.TestNewStream.id
            $PD.Stream.name | Should -Be $TestStreamName
            $PD.Stream.cpcode | Should -Be $PD.CpCodes[0].id
        }
    }

    Context 'Set-MSLStream by Pipeline' {
        It 'updates successfully' {
            $PD.Stream | Set-MSLStream @CommonParams
        }
    }
    
    Context 'Set-MSLStream by Param' {
        It 'updates successfully' {
            Set-MSLStream -StreamID $PD.Stream.id -Body $PD.Stream @CommonParams
        }
    }

    Context 'Remove-MSLStream' {
        It 'deletes successfully' {
            Remove-MSLStream -StreamID $PD.Stream.id @CommonParams
        }
    }

}

Describe 'UnSafe Akamai.MediaServicesLive Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.MediaServicesLive/Akamai.MediaServicesLive.psd1 -Force
        
        $TestContract = '1-2AB34C'
        $TestGroup = 123456
        $TestNewOrigin = @"
{
    "contractId": "$TestContract",
    "hostName": "$TestHostname",
    "cpcode": 123456,
    "encoderZone": "US_EAST",
    "backupEncoderZone": "EUROPE",
    "groupId": $TestGroup,
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
        
    }

    #------------------------------------------------
    #                 CDNs                  
    #------------------------------------------------
    
    Context 'Get-MSLCDN' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLCDN.json"
                return $Response | ConvertFrom-Json
            }
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
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
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MSLCPCode.json"
                return $Response | ConvertFrom-Json
            }
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MSLCPCode.json"
                return $Response | ConvertFrom-Json
            }
            $PD.NewCPCode = New-MSLCPCode -Name 'Test' -ContractID $TestContract
            $PD.NewCPCode.id | Should -Not -BeNullOrEmpty
            $PD.NewCPCode.name | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                   VOD Origins                
    #------------------------------------------------

    Context 'Get-MSLPublishingLocations' {
        It 'lists vod origins' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-MSLVODOrigin.json"
                return $Response | ConvertFrom-Json
            }
            $PD.VODOrigins = Get-MSLVODOrigin -EncoderLocation Europe
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
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-MSLOrigin.json"
                return $Response | ConvertFrom-Json
            }
            New-MSLOrigin -Body $TestNewOrigin
        }
    }

    Context 'Remove-MSLOrigin' {
        It 'deletes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.MediaServicesLive -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-MSLOrigin.json"
                return $Response | ConvertFrom-Json
            }
            Remove-MSLOrigin -OriginID 123456
        }
    }
}

