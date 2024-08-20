Describe 'Safe Akamai.CloudWrapper Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CloudWrapper/Akamai.CloudWrapper.psm1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestPropertyName = $env:PesterAMDPropertyName
        $TestConfigName = 'akamaipowershell'
        $TestConfig = @"
{
  "configName": "$TestConfigName",
  "contractId": "$TestContract",
  "propertyIds": [
    "12345"
  ],
  "comments": "testing",
  "retainIdleObjects": false,
  "locations": [
    {
      "trafficTypeId": 3,
      "comments": "Testing",
      "capacity": {
        "value": 1,
        "unit": "GB"
      },
      "mapName": "cw-s-usw"
    }
  ],
  "multiCdnSettings": {
    "origins": [
      {
        "originId": "origin976",
        "hostname": "akamaipowershell.download.akamai.com",
        "propertyId": 1071960
      }
    ],
    "cdns": [
      {
        "cdnCode": "dn010",
        "enabled": true,
        "cdnAuthKeys": [],
        "ipAclCidrs": [
          "1.2.3.4"
        ],
        "httpsOnly": false
      }
    ],
    "dataStreams": {
      "enabled": false,
      "dataStreamIds": []
    },
    "bocc": {
      "enabled": false
    },
    "enableSoftAlerts": true,
    "advancedSettings": null,
    "arlId": 1086598
  },
  "notificationEmails": [
    "mail@example.com"
  ]
}
"@ | ConvertFrom-Json

        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 Provider
    #------------------------------------------------

    Context 'Get-CloudWrapperProvider' {
        It 'lists providers' {
            $PD.Providers = Get-CloudWrapperProvider @TestParams @CommonParams
            $PD.Providers.count | Should -BeGreaterThan 0
            $PD.Providers[0].cdnCode | Should -Not -BeNullOrEmpty
            $PD.Providers[0].cdnName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Location
    #------------------------------------------------

    Context 'Get-CloudWrapperLocation' {
        It 'lists locations' {
            $PD.Locations = Get-CloudWrapperLocation @CommonParams
            $PD.Locations.count | Should -BeGreaterThan 0
            $PD.Locations[0].locationId | Should -Not -BeNullOrEmpty
            $PD.Locations[0].locationName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Capacity
    #------------------------------------------------

    Context 'Get-CloudWrapperCapacity' {
        It 'returns the correct data' {
            $PD.Capacity = Get-CloudWrapperCapacity -ContractIds $TestContract @CommonParams
            $PD.Capacity[0].approvedCapacity | Should -Not -BeNullOrEmpty
            $PD.Capacity[0].assignedCapacity | Should -Not -BeNullOrEmpty
            $PD.Capacity[0].contractId | Should -Be $TestContract
        }
    }

    #------------------------------------------------
    #                 Property
    #------------------------------------------------

    Context 'Get-CloudWrapperProperty' {
        It 'returns the correct data' {
            $PD.Properties = Get-CloudWrapperProperty @CommonParams
            $PD.Properties.count | Should -BeGreaterThan 0
            $PD.Properties[0].propertyId | Should -Not -BeNullOrEmpty
            $PD.Properties[0].propertyName | Should -Not -BeNullOrEmpty
            $PD.Properties[0].groupId | Should -Not -BeNullOrEmpty
            $PD.Property = $PD.Properties | Where-Object propertyName -eq $TestPropertyName
            $PD.Property | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Origin
    #------------------------------------------------

    Context 'Get-CloudwrapperOrigin' {
        It 'returns the correct data' {
            $PD.Origins = $PD.Property | Get-CloudwrapperOrigin @CommonParams
            $PD.Origins.default.originType | Should -Not -BeNullOrEmpty
            $PD.Origins.default.hostname | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Configuration
    #------------------------------------------------

    Context 'New-CloudWrapperConfiguration by pipeline' {
        It 'creates successfully' {
            # Update with real property ID
            $TestConfig.propertyIds[0] = [string] $PD.Property.PropertyID
            $PD.NewConfig = $TestConfig | New-CloudWrapperConfiguration @CommonParams
            $PD.NewConfig.configName | Should -Not -BeNullOrEmpty
            $PD.NewConfig.configId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudWrapperConfiguration, all' {
        It 'returns a list of configs' {
            $PD.Configs = Get-CloudWrapperConfiguration @CommonParams
            $PD.Configs.count | Should -BeGreaterThan 0
            $PD.Configs[0].configName | Should -Not -BeNullOrEmpty
            $PD.Configs[0].configId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-CloudWrapperConfiguration, single' {
        It 'returns the correct config' {
            $TestParams = @{
                ConfigID = $PD.Configs[0].configId
            }
            $PD.Config = Get-CloudWrapperConfiguration @TestParams @CommonParams
            $PD.Config.configName | Should -Be $PD.Configs[0].configName
            $PD.Config.configId | Should -Be $PD.Configs[0].configId
        }
    }

    Context 'Set-CloudWrapperConfiguration by parameter' {
        It 'returns the correct data' {
            $TestParams = @{
                Body     = $PD.NewConfig
                ConfigID = $PD.NewConfig.configId
            }
            $SetByParam = Set-CloudWrapperConfiguration @TestParams @CommonParams
            $SetByParam.configName | Should -Be $PD.NewConfig.configName
            $SetByParam.configId | Should -Be $PD.NewConfig.configId
        }
    }

    Context 'Set-CloudWrapperConfiguration by pipeline' {
        It 'returns the correct data' {
            $SetByPipeline = $PD.NewConfig | Set-CloudWrapperConfiguration @CommonParams
            $SetByPipeline.configName | Should -Be $PD.NewConfig.configName
            $SetByPipeline.configId | Should -Be $PD.NewConfig.configId
        }
    }

    #------------------------------------------------
    #                 ConfigurationOrigins
    #------------------------------------------------

    Context 'Get-CloudWrapperConfigurationOrigins' {
        It 'returns the correct data' {
            $TestParams = @{
                ConfigID = $PD.NewConfig.configId
            }
            $PD.ConfigOrigins = Get-CloudWrapperConfigurationOrigins @TestParams @CommonParams
            $PD.ConfigOrigins[0].primary | Should -Not -BeNullOrEmpty
            $PD.ConfigOrigins[0].backup | Should -Not -BeNullOrEmpty
            $PD.ConfigOrigins[0].locationName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 ConfigurationOrigins
    #------------------------------------------------

    Context 'Remove-CloudWrapperConfiguration by pipeline' {
        It 'throws no errors' {
            $PD.NewConfig | Remove-CloudWrapperConfiguration @CommonParams
        }
    }
}

Describe 'Unsafe Akamai.CloudWrapper Tests' {
    
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CloudWrapper/Akamai.CloudWrapper.psm1 -Force
        $TestContract = '1-2AB34C'
        $TestGroup = 123456
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CloudWrapper"
        $PD = @{}
        
    }

    AfterAll {
        
    }

    #------------------------------------------------
    #                 AuthKey
    #------------------------------------------------

    Context 'Get-CloudWrapperAuthKey' {
        It 'gets a key in the right format' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudWrapper -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudWrapperAuthKey.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                CdnCode    = 'dn004'
                ContractID = '1-2AB34C'
            }
            $PD.AuthKey = Get-CloudWrapperAuthKey @TestParams
            $PD.AuthKey.authKeyName | Should -Not -BeNullOrEmpty
            $PD.AuthKey.headerName | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 Activation
    #------------------------------------------------

    Context 'New-CloudWrapperConfigurationActivation by parameter' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudWrapper -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudWrapperConfigurationActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                ConfigurationIDs = 12345
            }
            New-CloudWrapperConfigurationActivation @TestParams
        }
    }

    Context 'New-CloudWrapperConfigurationActivation by pipeline' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudWrapper -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudWrapperConfigurationActivation.json"
                return $Response | ConvertFrom-Json
            }
            12345, 23456 | New-CloudWrapperConfigurationActivation
        }
    }

}
