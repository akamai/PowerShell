Describe 'Safe Cloud Access Manager Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CloudAccessManager/Akamai.CloudAccessManager.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestKeyName = 'AkamaiPowershell'
        $TestKeyVersion = 1
        $TestNewKeyBody = '{
            "credentials": {
                 "cloudAccessKeyId": "AKAMAICAMKEYID1EXAMPLE",
                 "cloudSecretAccessKey": "cDblrAMtnIAxN/g7dF/bAxLfiANAXAMPLEKEY"
            },
            "networkConfiguration": {
                 "securityNetwork": "STANDARD_TLS"
            },
            "accessKeyName": "Sales-s3",
            "contractId": "1-7FALA",
            "groupId": 10725
        }'
        $TestNewKeyObject = ConvertFrom-Json $TestNewKeyBody
        $PD = @{}
    }

    AfterAll {
        
    }

    Context 'Get-CloudAccessKeys, all' {
        It 'returns a list' {
            $PD.Keys = Get-CloudAccessKey @CommonParams
            $PD.Keys.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Extract KeyUID from keys' {
        It 'exists' {
            $PD.KeyUID = ($PD.Keys | Where-Object accessKeyName -eq $TestKeyName).accessKeyUid
            $PD.KeyUID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudAccessKey, single' {
        It 'returns the right key' {
            $PD.Key = Get-CloudAccessKey -AccessKeyUID $PD.KeyUID @CommonParams
            $PD.Key.accessKeyName | Should -Be $TestKeyName
        }
    }

    Context 'Get-CloudAccessKeyVersions, all' {
        It 'returns a list' {
            $PD.Versions = Get-CloudAccessKeyVersion -AccessKeyUID $PD.KeyUID @CommonParams
            $PD.Versions.count | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudAccessKeyVersion, single' {
        It 'returns the right version' {
            $PD.Version = Get-CloudAccessKeyVersion -AccessKeyUID $PD.KeyUID -Version $TestKeyVersion @CommonParams
            $PD.Version.version | Should -Be $TestKeyVersion
        }
    }

    Context 'Get-CloudAccessKeyVersionProperties' {
        It 'returns a list' {
            $PD.Properties = Get-CloudAccessKeyVersionProperties -AccessKeyUID $PD.KeyUID -Version $TestKeyVersion @CommonParams
            $PD.Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudAccessLookup' {
        It 'returns the corect data' {
            $PD.Lookup = New-CloudAccessLookup -AccessKeyUID $PD.KeyUID -Version $TestKeyVersion @CommonParams
            $PD.Lookup.lookupId | Should -Not -BeNullOrEmpty
            # Pause for long enough to allow the lookup to complete
            Start-Sleep -Seconds $PD.Lookup.retryAfter
        }
    }


    Context 'Get-CloudAccessLookup' {
        It 'returns the corect data' {
            $PD.LookupResult = Get-CloudAccessLookup -LookupID $PD.Lookup.lookupId @CommonParams
            $PD.LookupResult.properties[0].accessKeyUid | Should -Be $PD.KeyUID
        }
    }
}

Describe 'Unsafe Cloud Access Manager Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.CloudAccessManager/Akamai.CloudAccessManager.psd1 -Force
        
        $TestNewKeyBody = '{
            "credentials": {
                 "cloudAccessKeyId": "AKAMAICAMKEYID1EXAMPLE",
                 "cloudSecretAccessKey": "cDblrAMtnIAxN/g7dF/bAxLfiANAXAMPLEKEY"
            },
            "networkConfiguration": {
                 "securityNetwork": "STANDARD_TLS"
            },
            "accessKeyName": "Sales-s3",
            "contractId": "1-7FALA",
            "groupId": 10725
        }'
        $TestNewKeyObject = ConvertFrom-Json $TestNewKeyBody
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CloudAccessManager"
        $PD = @{}
    }
    Context 'New-CloudAccessKey by param' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudAccessKey.json"
                return $Response | ConvertFrom-Json
            }
            $NewKeyByParam = New-CloudAccessKey -Body $TestNewKeyBody
            $NewKeyByParam.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudAccessKey by pipeline' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudAccessKey.json"
                return $Response | ConvertFrom-Json
            }
            $NewKeyByPipeline = $TestNewKeyObject | New-CloudAccessKey
            $NewKeyByPipeline.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudAccessKeyCreateRequest' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudAccessKeyCreateRequest.json"
                return $Response | ConvertFrom-Json
            }
            $CreateRequest = Get-CloudAccessKeyCreateRequest -RequestID 12345
            $CreateRequest.accessKeyVersion.accessKeyUid | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudAccessKeyVersion' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-CloudAccessKeyVersion.json"
                return $Response | ConvertFrom-Json
            }
            $NewVersion = New-CloudAccessKeyVersion -AccessKeyUID $KeyUID -CloudAccessKeyID 123456789 -CloudSecretAccessKey 123456789
            $NewVersion.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-CloudAccessKeyVersion' {
        It 'completes successfully' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-CloudAccessKeyVersion.json"
                return $Response | ConvertFrom-Json
            }
            $RemoveVersion = Remove-CloudAccessKeyVersion -AccessKeyUID $KeyUID -Version 2
            $RemoveVersion.deploymentStatus | Should -Not -BeNullOrEmpty
        }
    }
    
}


