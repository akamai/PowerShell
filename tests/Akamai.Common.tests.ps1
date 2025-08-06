BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Shared Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        # Import additional modules
        Import-Module $PSScriptRoot/../src/Akamai.APIDefinitions/Akamai.APIDefinitions.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.AppSec/Akamai.AppSec.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.ClientLists/Akamai.ClientLists.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.EdgeWorkers/Akamai.EdgeWorkers.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.METS/Akamai.METS.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.MOKS/Akamai.MOKS.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Property/Akamai.Property.psd1 -Force
        
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestAuthFile = $env:PesterAuthFile
        $TestClearTextString = 'This is my test string!'
        $TestBase64EncodedString = 'VGhpcyBpcyBteSB0ZXN0IHN0cmluZyE='
        $TestURLEncodedString = 'This%20is%20my%20test%20string!'
        $TestUnsanitizedQuery = 'one=1&two=&three=3&four='
        $TestSanitisedQuery = 'one=1&three=3'
        $TestUnsanitizedFileName = 'This\looks!Kinda<"bad">.txt'
        $TestSanitizedFileName = 'This%5Clooks!Kinda%3C%22bad%22%3E.txt'
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $PD = @{}
    }

    Context 'ConvertFrom-Base64' {
        It 'decodes successfully' {
            $PD.Bas64Decode = ConvertFrom-Base64 -EncodedString $TestBase64EncodedString
            $PD.Bas64Decode | Should -Be $TestClearTextString
        }
    }

    Context 'Get-RandomString - Alphabetical' {
        It 'produces alphabetical string' {
            $PD.RandomAlphabetical = Get-RandomString -Length 16 -Alphabetical
            $PD.RandomAlphabetical | Should -Match "[a-z]{16}"
        }
    }

    Context 'Get-RandomString - AlphaNumeric' {
        It 'produces alphanumeric string' {
            $PD.RandomAlphaNumeric = Get-RandomString -Length 16 -AlphaNumeric
            $PD.RandomAlphaNumeric | Should -Match "[a-z0-9]{16}"
        }
    }

    Context 'Get-RandomString - Numeric' {
        It 'produces numeric string' {
            $PD.RandomNumeric = Get-RandomString -Length 16 -Numeric
            $PD.RandomNumeric | Should -Match "[0-9]{16}"
        }
    }

    Context 'Get-RandomString - Hex' {
        It 'produces hex string' {
            $PD.RandomHex = Get-RandomString -Length 16 -Hex
            $PD.RandomHex | Should -Match "[a-f0-9]{16}"
        }
    }

    Context 'Format-QueryString' {
        It 'strips empty query params' {
            $PD.ParsedQuery = Format-QueryString -QueryString $TestUnsanitizedQuery
            $PD.ParsedQuery | Should -Be $TestSanitisedQuery
        }
    }

    Context 'Format-Filename' {
        It 'encodes invalid characters' {
            $PD.ParsedFileName = Format-Filename -Filename $TestUnsanitizedFileName
            $PD.ParsedFileName | Should -Be $TestSanitizedFilename
        }
    }

    Context 'Test-OpenAPI' {
        It 'returns data successfully' {
            $PD.APIResult = Test-OpenAPI -Path '/papi/v1/contracts' @CommonParams
            $PD.APIResult.count | Should -Not -Be 0
        }
    }

    Context 'Get-AkamaiCredentials' -Tag 'Get-AkamaiCredentials' {
        Context 'Get-AkamaiCredentials from edgerc' {
            BeforeAll {
                # Record previous env vars
                $PreviousHost = $Env:AKAMAI_HOST
                $PreviousClientToken = $Env:AKAMAI_CLIENT_TOKEN
                $PreviousAccessToken = $Env:AKAMAI_ACCESS_TOKEN
                $PreviousClientSecret = $Env:AKAMAI_CLIENT_SECRET
                $PreviousAccountSwitchKey = $env:AKAMAI_ACCOUNT_KEY
                # Set edgerc file
                $TestEdgeRCFile = New-Item -ItemType File -Path 'TestDrive:/.edgerc'
                $TestHost = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                $TestClientSecret = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                $TestAccessToken = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                $TestClientToken = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                $TestASK = '1-2A345B:1-2ABC'
                @"
[not-default]
client_secret = $TestClientSecret
host = $TestHost
access_token = $TestAccessToken
client_token = $TestClientToken
account_key = $TestASK
"@ | Out-File $TestEdgeRCFile.FullName
                $TestParams = @{
                    EdgeRCFile = $TestEdgeRCFile
                    Section    = 'not-default'
                }
            }
            It 'reads an edgerc file correctly' {
                $PD.Auth = Get-AkamaiCredentials @TestParams
                $PD.Auth.client_token | Should -Be $TestClientToken
                $PD.Auth.access_token | Should -Be $TestAccessToken
                $PD.Auth.client_secret | Should -Be $TestClientSecret
                $PD.Auth.host | Should -Be $TestHost
                $PD.Auth.account_key | Should -Be $TestASK
            }
            It 'overrides the account switch key when provided' {
                $OverrideASK = Get-AkamaiCredentials @TestParams -AccountSwitchKey 'Pester'
                $OverrideASK.client_token | Should -Be $TestClientToken
                $OverrideASK.access_token | Should -Be $TestAccessToken
                $OverrideASK.client_secret | Should -Be $TestClientSecret
                $OverrideASK.host | Should -Be $TestHost
                $OverrideASK.account_key | Should -Be 'Pester'
            }
            It 'does not contain an account switch key when input is set to none' {
                $NoAsk = Get-AkamaiCredentials -AccountSwitchKey 'none' @TestParams
                $NoAsk.client_token | Should -Be $TestClientToken
                $NoAsk.access_token | Should -Be $TestAccessToken
                $NoAsk.client_secret | Should -Be $TestClientSecret
                $NoAsk.host | Should -Be $TestHost
                $NoAsk.account_key | Should -BeNullOrEmpty
            }
        }
    
        Context 'Get-AkamaiCredentials from environment, default section' {
            It 'parses correctly' {
                $env:AKAMAI_HOST = 'env-host'
                $env:AKAMAI_CLIENT_TOKEN = 'env-client_token'
                $env:AKAMAI_ACCESS_TOKEN = 'env-access_token'
                $env:AKAMAI_CLIENT_SECRET = 'env-client_secret'
                $env:AKAMAI_ACCOUNT_KEY = 'env-account_key'
                $PD.DefaultEnvAuth = Get-AkamaiCredentials
                $PD.DefaultEnvAuth.client_token | Should -Be 'env-client_token'
                $PD.DefaultEnvAuth.access_token | Should -Be 'env-access_token'
                $PD.DefaultEnvAuth.client_secret | Should -Be 'env-client_secret'
                $PD.DefaultEnvAuth.host | Should -Be 'env-host'
                $PD.DefaultEnvAuth.account_key | Should -Be 'env-account_key'
            }
            It 'overrides an account switch key when provided' {
                $env:AKAMAI_HOST = 'env-host'
                $env:AKAMAI_CLIENT_TOKEN = 'env-client_token'
                $env:AKAMAI_ACCESS_TOKEN = 'env-access_token'
                $env:AKAMAI_CLIENT_SECRET = 'env-client_secret'
                $env:AKAMAI_ACCOUNT_KEY = 'env-account_key'
                $PD.DefaultEnvAuth = Get-AkamaiCredentials -AccountSwitchKey 'provided-ask'
                $PD.DefaultEnvAuth.client_token | Should -Be 'env-client_token'
                $PD.DefaultEnvAuth.access_token | Should -Be 'env-access_token'
                $PD.DefaultEnvAuth.client_secret | Should -Be 'env-client_secret'
                $PD.DefaultEnvAuth.host | Should -Be 'env-host'
                $PD.DefaultEnvAuth.account_key | Should -Be 'provided-ask'
            }
        }
    
        Context 'Get-AkamaiCredentials from environment, custom section' {
            It 'parses correctly' {
                $env:AKAMAI_PESTER_HOST = 'customenv-host'
                $env:AKAMAI_PESTER_CLIENT_TOKEN = 'customenv-client_token'
                $env:AKAMAI_PESTER_ACCESS_TOKEN = 'customenv-access_token'
                $env:AKAMAI_PESTER_CLIENT_SECRET = 'customenv-client_secret'
                $env:AKAMAI_PESTER_ACCOUNT_KEY = 'customenv-account_key'
                $PD.CustomEnvAuth = Get-AkamaiCredentials -Section Pester
                $PD.CustomEnvAuth.client_token | Should -Be 'customenv-client_token'
                $PD.CustomEnvAuth.access_token | Should -Be 'customenv-access_token'
                $PD.CustomEnvAuth.client_secret | Should -Be 'customenv-client_secret'
                $PD.CustomEnvAuth.host | Should -Be 'customenv-host'
                $PD.CustomEnvAuth.account_key | Should -Be 'customenv-account_key'
            }
            It 'overrides an account switch key when provided' {
                $env:AKAMAI_PESTER_HOST = 'customenv-host'
                $env:AKAMAI_PESTER_CLIENT_TOKEN = 'customenv-client_token'
                $env:AKAMAI_PESTER_ACCESS_TOKEN = 'customenv-access_token'
                $env:AKAMAI_PESTER_CLIENT_SECRET = 'customenv-client_secret'
                $env:AKAMAI_PESTER_ACCOUNT_KEY = 'provided-ask'
                $PD.CustomEnvAuth = Get-AkamaiCredentials -Section Pester
                $PD.CustomEnvAuth.client_token | Should -Be 'customenv-client_token'
                $PD.CustomEnvAuth.access_token | Should -Be 'customenv-access_token'
                $PD.CustomEnvAuth.client_secret | Should -Be 'customenv-client_secret'
                $PD.CustomEnvAuth.host | Should -Be 'customenv-host'
                $PD.CustomEnvAuth.account_key | Should -Be 'provided-ask'
            }
        }
    
        Context 'Get-AkamaiCredentials from session' {
            It 'parses correctly' {
                $TestParams = @{
                    'ClientSecret'      = 'session-client_secret'
                    'HostName'          = 'session-host'
                    'ClientAccessToken' = 'session-access_token'
                    'ClientToken'       = 'session-client_token'
                    'AccountSwitchKey'  = 'session-account_key'
                }
                New-AkamaiSession @TestParams
                $PD.SessionAuth = Get-AkamaiCredentials
                $PD.SessionAuth.client_token | Should -Be 'session-client_token'
                $PD.SessionAuth.access_token | Should -Be 'session-access_token'
                $PD.SessionAuth.client_secret | Should -Be 'session-client_secret'
                $PD.SessionAuth.host | Should -Be 'session-host'
                $PD.SessionAuth.account_key | Should -Be 'session-account_key'
            }
        }

        AfterAll {
            Remove-AkamaiSession
            $env:AKAMAI_HOST = $PreviousHost
            $env:AKAMAI_CLIENT_TOKEN = $PreviousClientToken
            $env:AKAMAI_ACCESS_TOKEN = $PreviousAccessToken
            $env:AKAMAI_CLIENT_SECRET = $PreviousClientSecret
            $env:AKAMAI_ACCOUNT_KEY = $PreviousAccountSwitchKey
            $env:AKAMAI_PESTER_HOST = $null
            $env:AKAMAI_PESTER_CLIENT_TOKEN = $null
            $env:AKAMAI_PESTER_ACCESS_TOKEN = $null
            $env:AKAMAI_PESTER_CLIENT_SECRET = $null
            $env:AKAMAI_PESTER_ACCOUNT_KEY = $null
        }
    }

    Context 'Confirm-Auth' {
        It 'prints nothing' {
            $PD.AuthErrors = Confirm-Auth -Auth $PD.Auth
            $PD.AuthErrors | Should -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageCredentials from file' {
        BeforeAll {
            $Key = 'ab1cd2e3fgh46uhjk7l8mn90opq1rstu23vw4xyza5bc6d7'
            $ID = 'sample'
            $Group = 'sample_group'
            $HostName = 'sample-nsu.akamaihd.net'
            $CPCode = 123456

            $Content = @"
[default]
key=$Key
id=$ID
group=$Group
host=$Hostname
cpcode=$CPCode
"@
            $AuthFile = 'TestDrive:/.nsrc'
            $Content | Set-Content -Path $AuthFile
        }
        It 'parses correctly' {
            $PD.NSAuth = Get-NetstorageCredentials -AuthFile $AuthFile -Section $Section
            $PD.NSAuth.cpcode | Should -Be $CPCode
            $PD.NSAuth.group | Should -Be $Group
            $PD.NSAuth.key | Should -Be $Key
            $PD.NSAuth.id | Should -Be $ID
            $PD.NSAuth.host | Should -Be $Hostname
        }
    }

    Context 'Get-NetstorageCredentials from default environment' {
        It 'parses correctly' {
            $env:NETSTORAGE_CPCODE = 'env-cpcode'
            $env:NETSTORAGE_GROUP = 'env-group'
            $env:NETSTORAGE_KEY = 'env-key'
            $env:NETSTORAGE_ID = 'env-id'
            $env:NETSTORAGE_HOST = 'env-host'
            $PD.DefaultEnvNSAuth = Get-NetstorageCredentials
            $PD.DefaultEnvNSAuth.cpcode | Should -Be 'env-cpcode'
            $PD.DefaultEnvNSAuth.group | Should -Be 'env-group'
            $PD.DefaultEnvNSAuth.key | Should -Be 'env-key'
            $PD.DefaultEnvNSAuth.id | Should -Be 'env-id'
            $PD.DefaultEnvNSAuth.host | Should -Be 'env-host'
        }
    }

    Context 'Get-NetstorageCredentials from custom environment' {
        It 'parses correctly' {
            $env:NETSTORAGE_CUSTOM_CPCODE = 'customenv-cpcode'
            $env:NETSTORAGE_CUSTOM_GROUP = 'customenv-group'
            $env:NETSTORAGE_CUSTOM_KEY = 'customenv-key'
            $env:NETSTORAGE_CUSTOM_ID = 'customenv-id'
            $env:NETSTORAGE_CUSTOM_HOST = 'customenv-host'
            $PD.CustomEnvNSAuth = Get-NetstorageCredentials -Section Custom
            $PD.CustomEnvNSAuth.cpcode | Should -Be 'customenv-cpcode'
            $PD.CustomEnvNSAuth.group | Should -Be 'customenv-group'
            $PD.CustomEnvNSAuth.key | Should -Be 'customenv-key'
            $PD.CustomEnvNSAuth.id | Should -Be 'customenv-id'
            $PD.CustomEnvNSAuth.host | Should -Be 'customenv-host'
        }
    }

    Context 'Remove-AkamaiSession' {
        It 'should not throw an error' {
            Remove-AkamaiSession 
        }
    }

    Context 'New-AkamaiOptions' -Tag 'New-AkamaiOptions' {
        BeforeAll {
            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
        }

        It 'should create the options file at the specified location' {
            New-AkamaiOptions
            $env:AkamaiOptionsPath | Should -Exist
        }

        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
        }
    }

    Context 'Options' -Tag 'Options' {
        Context 'New-AkamaiOptions' -Tag 'New-AkamaiOptions' {
            BeforeAll {
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
            }
            It 'populates the file with the correct options' {
                New-AkamaiOptions
                $Options = Get-Content -Raw -Path $env:AkamaiOptionsPath | ConvertFrom-Json
                $Options.EnableErrorRetries | Should -BeOfType bool
                $Options.EnableRateLimitRetries | Should -BeOfType bool
                $Options.DisablePapiPrefixes | Should -BeOfType bool
                $Options.EnableRateLimitWarnings | Should -BeOfType bool
                $Options.InitialErrorWait | Should -Match '^[0-9]+$'
                $Options.MaxErrorRetries | Should -Match '^[0-9]+$'
                $Options.RateLimitWarningPercentage | Should -Match '^[0-9]+$'
                $Options.EnableRecommendedActions | Should -BeOfType bool
                $Options.EnableDataCache | Should -BeOfType bool
            }
            AfterAll {
                Remove-Item -Path $env:AkamaiOptionsPath -Force
                $env:AkamaiOptionsPath = $PreviousOptionsPath
            }
        }

        Context 'Get-AkamaiOptions' -Tag 'Get-AkamaiOptions' {
            BeforeAll {
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
            }
            It 'returns options as expected' {
                Get-AkamaiOptions
                $Global:AkamaiOptions.EnableErrorRetries | Should -BeOfType bool
                $Global:AkamaiOptions.EnableRateLimitRetries | Should -BeOfType bool
                $Global:AkamaiOptions.DisablePapiPrefixes | Should -BeOfType bool
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -BeOfType bool
                $Global:AkamaiOptions.InitialErrorWait | Should -Match '^[0-9]+$'
                $Global:AkamaiOptions.MaxErrorRetries | Should -Match '^[0-9]+$'
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Match '^[0-9]+$'
                $Global:AkamaiOptions.EnableRecommendedActions | Should -BeOfType bool
                $Global:AkamaiOptions.EnableDataCache | Should -BeOfType bool
            }
            It 'should exist at default path' {
                $env:AkamaiOptionsPath | Should -Exist
            }
            AfterAll {
                Remove-Item -Path $env:AkamaiOptionsPath -Force
                $env:AkamaiOptionsPath = $PreviousOptionsPath
            }
        }
    
        Context 'Set-AkamaiOptions' -Tag 'Set-AkamaiOptions' {
            BeforeAll {
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
            }
            It 'should update correctly' {
                $TestParams = @{
                    EnableErrorRetries         = $true
                    InitialErrorWait           = 2
                    MaxErrorRetries            = 10
                    EnableRateLimitRetries     = $true
                    DisablePAPIPrefixes        = $true
                    EnableRateLimitWarnings    = $true
                    RateLimitWarningPercentage = 12
                    EnableDataCache            = $true
                    EnableRecommendedActions   = $true
                }
    
                # Check defaults
                Get-AkamaiOptions
                $Global:AkamaiOptions.EnableErrorRetries | Should -be $False
                $Global:AkamaiOptions.InitialErrorWait | Should -be 1
                $Global:AkamaiOptions.MaxErrorRetries | Should -be 5
                $Global:AkamaiOptions.EnableRateLimitRetries | Should -Be $False
                $Global:AkamaiOptions.DisablePapiPrefixes | Should -Be $False
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -Be $False
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 90
                $Global:AkamaiOptions.EnableDataCache | Should -Be $False
                $Global:AkamaiOptions.EnableRecommendedActions | Should -Be $False
    
                # Update
                Set-AkamaiOptions @TestParams | Out-Null
    
                # Check new values
                $Global:AkamaiOptions.EnableErrorRetries | Should -be $true
                $Global:AkamaiOptions.InitialErrorWait | Should -be 2
                $Global:AkamaiOptions.MaxErrorRetries | Should -be 10
                $Global:AkamaiOptions.EnableRateLimitRetries | Should -Be $true
                $Global:AkamaiOptions.DisablePapiPrefixes | Should -Be $true
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -Be $true
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 12
                $Global:AkamaiOptions.EnableDataCache | Should -Be $true
                $Global:AkamaiOptions.EnableRecommendedActions | Should -Be $true
            }
            It 'should create the data cache' {
                $SetOptions = Set-AkamaiOptions -EnableDataCache $true
                $SetOptions.EnableDataCache | Should -Be $true
                $Global:AkamaiDataCache | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.APIDefinitions | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.AppSec | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.ClientLists | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.METS | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.MOKS | Should -Not -BeNullOrEmpty
                $Global:AkamaiDataCache.Property | Should -Not -BeNullOrEmpty
            }
            It 'should respond with rate limit warnings' {
                Set-AkamaiOptions -EnableRateLimitWarnings $true -RateLimitWarningPercentage 0 | Out-Null
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 0
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -Be $true
                Get-PropertyContract @CommonParams -WarningAction Continue -WarningVariable RateWarning
                $RateWarning | Should -BeLike "Akamai Rate Limit used = *"
            }
            AfterAll {
                Remove-Item -Path $env:AkamaiOptionsPath -Force
                $env:AkamaiOptionsPath = $PreviousOptionsPath
            }
        }
        Context 'check options persist' {
            BeforeAll {
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
            }

            It 'should keep options beyond module re-import' {
                $OptionsParams = @{
                    RateLimitWarningPercentage = 12
                    InitialErrorWait           = 5
                    MaxErrorRetries            = 6
                }
                Set-AkamaiOptions @OptionsParams
                Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 12
                $Global:AkamaiOptions.InitialErrorWait | Should -Be 5
                $Global:AkamaiOptions.MaxErrorRetries | Should -Be 6
            }

            AfterAll {
                Remove-Item -Path $env:AkamaiOptionsPath -Force
                $env:AkamaiOptionsPath = $PreviousOptionsPath
            }
        }
    }

    Context 'Cache operations' {
        Context 'New-AkamaiDataCache' -Tag 'New-AkamaiDataCache' {
            It 'populates the cache object correctly' {
                New-AkamaiDataCache
                $AkamaiDataCache | Should -Not -BeNullOrEmpty
                'APIEndpoints' | Should -BeIn $AkamaiDataCache.APIDefinitions.Keys
                'Configs' | Should -BeIn $AkamaiDataCache.AppSec.Keys
                'Lists' | Should -BeIn $AkamaiDataCache.ClientLists.Keys
                'EdgeWorkers' | Should -BeIn $AkamaiDataCache.EdgeWorkers.Keys
                'CASets' | Should -BeIn $AkamaiDataCache.METS.Keys
                'ClientCerts' | Should -BeIn $AkamaiDataCache.MOKS.Keys
                'Properties' | Should -BeIn $AkamaiDataCache.Property.Keys
                'Includes' | Should -BeIn $AkamaiDataCache.Property.Keys
            }
        }
        Context 'Clear-AkamaiDataCache' -Tag 'Clear-AkamaiDataCache' {
            BeforeAll {
                $Modules = Get-Module
                # Pull assets before enabling data cache
                $AppSecConfigs = Get-AppSecConfiguration @CommonParams
                $ClientLists = Get-ClientList @CommonParams
                $EdgeWorkers = Get-EdgeWorker @CommonParams
                $METSCASets = Get-METSCASet @CommonParams
                $MOKSClientCerts = Get-MOKSClientCert @CommonParams
                $Includes = Get-PropertyInclude -GroupID $TestGroupID -ContractID $TestContract @CommonParams
                $Properties = Get-Property -GroupID $TestGroupID -ContractID $TestContract @CommonParams
                $APIEndpoints = Get-APIEndpoints -PageSize 10 @CommonParams
    
                Clear-AkamaiDataCache
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
                Set-AkamaiOptions -EnableDataCache $true
            }

            It 'populates the cache from Get- commands' {
                $Properties = Get-Property -GroupID $TestGroupID -ContractID $TestContract @CommonParams
                $EdgeWorkers = Get-EdgeWorker @CommonParams
                $AppSecConfigs = Get-AppSecConfiguration @CommonParams

                $AkamaiDataCache.Property.Properties | Should -BeOfType Hashtable
                $AkamaiDataCache.Property.Properties.Keys.count | Should -BeGreaterThan 0
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers | Should -BeOfType Hashtable
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys.count | Should -BeGreaterThan 0
                $AkamaiDataCache.AppSec.Configs | Should -BeOfType Hashtable
                $AkamaiDataCache.AppSec.Configs.Keys.count | Should -BeGreaterThan 0
            }
            It 'clears the entire data cache' {
                Clear-AkamaiDataCache
                $AkamaiDataCache.Property.Properties.Keys.count | Should -Be 0
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys.count | Should -Be 0
                $AkamaiDataCache.AppSec.Configs.Keys.count | Should -Be 0
            }

            ## API Definitions
            It 'clears an api definition from the cache by name' {
                # Populate the cache with a single item
                Get-APIEndpointVersion -APIEndpointName $APIEndpoints[0].apiEndPointName -VersionNumber latest @CommonParams
                $EndpointName = $AkamaiDataCache.APIDefinitions.APIEndpoints.Keys | Select-Object -First 1
                $EndpointID = $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName.APIEndpointID

                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName.APIEndpointID | Should -Be $EndpointID
                
                Clear-AkamaiDataCache -APIEndpointName $EndpointName
                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName | Should -BeNullOrEmpty
            }
            It 'clears an api definition from the cache by ID' {
                # Populate the cache with a single item
                Get-APIEndpointVersion -APIEndpointName $APIEndpoints[0].apiEndPointName -VersionNumber latest @CommonParams
                $EndpointName = $AkamaiDataCache.APIDefinitions.APIEndpoints.Keys | Select-Object -First 1
                $EndpointID = $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName.APIEndpointID

                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName.APIEndpointID | Should -Be $EndpointID
                
                Clear-AkamaiDataCache -APIEndpointID $EndpointID
                $AkamaiDataCache.APIDefinitions.APIEndpoints.$EndpointName | Should -BeNullOrEmpty
            }

            ## AppSec
            It 'clears an AAP Config from the cache by name' {
                # Populate the cache with a single item
                Get-AppSecConfiguration -ConfigName $AppSecConfigs[0].Name @CommonParams
                $ConfigName = $AkamaiDataCache.AppSec.Configs.Keys | Select-Object -First 1
                $ConfigID = $AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID

                $AkamaiDataCache.AppSec.Configs.$ConfigName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID | Should -Be $ConfigID
                
                Clear-AkamaiDataCache -AppSecConfigName $ConfigName
                $AkamaiDataCache.AppSec.Configs.$ConfigName | Should -BeNullOrEmpty
            }
            It 'clears an AAP Config from the cache by ID' {
                # Populate the cache with a single item
                Get-AppSecConfiguration -ConfigName $AppSecConfigs[0].Name @CommonParams
                $ConfigName = $AkamaiDataCache.AppSec.Configs.Keys | Select-Object -First 1
                $ConfigID = $AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID

                $AkamaiDataCache.AppSec.Configs.$ConfigName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.AppSec.Configs.$ConfigName.ConfigID | Should -Be $ConfigID
                
                Clear-AkamaiDataCache -AppSecConfigID $ConfigID
                $AkamaiDataCache.AppSec.Configs.$ConfigName | Should -BeNullOrEmpty
            }

            It 'clears an AAP policy from the cache by name' {
                # Populate the cache with a single item
                $ConfigName = $AppSecConfigs[0].Name
                Get-AppSecPolicy -ConfigName $ConfigName -VersionNumber latest @CommonParams
                $PolicyName = $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.Keys | Select-Object -First 1
                $PolicyID = $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID

                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID | Should -Be $PolicyID
                
                Clear-AkamaiDataCache -AppSecConfigName $ConfigName -AppSecPolicyName $PolicyName
                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName | Should -BeNullOrEmpty
            }
            It 'clears an AAP policy from the cache by ID' {
                # Populate the cache with a single item
                $ConfigName = $AppSecConfigs[0].Name
                Get-AppSecPolicy -ConfigName $ConfigName -VersionNumber latest @CommonParams
                $PolicyName = $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.Keys | Select-Object -First 1
                $PolicyID = $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID

                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName.PolicyID | Should -Be $PolicyID
                
                Clear-AkamaiDataCache -AppSecConfigName $ConfigName -AppSecPolicyID $PolicyID
                $AkamaiDataCache.AppSec.Configs.$ConfigName.Policies.$PolicyName | Should -BeNullOrEmpty
            }

            ## Client Lists
            It 'clears a client list from the cache by name' {
                # Populate the cache with a single item
                Get-ClientList -Name $ClientLists[0].name @CommonParams
                $ListName = $AkamaiDataCache.ClientLists.Lists.Keys | Select-Object -First 1
                $ListID = $AkamaiDataCache.ClientLists.Lists.$ListName.ListID

                $AkamaiDataCache.ClientLists.Lists.$ListName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.ClientLists.Lists.$ListName.ListID | Should -Be $ListID
                
                Clear-AkamaiDataCache -ClientListName $ListName
                $AkamaiDataCache.ClientLists.Lists.$ListName | Should -BeNullOrEmpty
            }
            It 'clears a client list from the cache by ID' {
                # Populate the cache with a single item
                Get-ClientList -Name $ClientLists[0].name @CommonParams
                $ListName = $AkamaiDataCache.ClientLists.Lists.Keys | Select-Object -First 1
                $ListID = $AkamaiDataCache.ClientLists.Lists.$ListName.ListID

                $AkamaiDataCache.ClientLists.Lists.$ListName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.ClientLists.Lists.$ListName.ListID | Should -Be $ListID
                
                Clear-AkamaiDataCache -ClientListID $ListID
                $AkamaiDataCache.ClientLists.Lists.$ListName | Should -BeNullOrEmpty
            }

            ## EdgeWorkers
            It 'clears an EdgeWorker from the cache by name' {
                # Populate the cache with a single item
                Get-EdgeWorker -EdgeWorkerName $EdgeWorkers[0].name @CommonParams
                $EdgeWorkerName = $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys | Select-Object -First 1
                $EdgeWorkerID = $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID

                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID | Should -Be $EdgeWorkerID
                
                Clear-AkamaiDataCache -EdgeWorkerName $EdgeWorkerName
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName | Should -BeNullOrEmpty
            }
            It 'clears an EdgeWorker from the cache by ID' {
                # Populate the cache with a single item
                Get-EdgeWorker -EdgeWorkerName $EdgeWorkers[0].name @CommonParams
                $EdgeWorkerName = $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys | Select-Object -First 1
                $EdgeWorkerID = $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID

                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID | Should -Be $EdgeWorkerID
                
                Clear-AkamaiDataCache -EdgeWorkerID $EdgeWorkerID
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName | Should -BeNullOrEmpty
            }

            ## METS
            It 'clears a METS CA Set from the cache by name' {
                # Populate the cache with a single item
                Get-METSCASet -CASetName $METSCASets[0].caSetName @CommonParams
                $CASetName = $AkamaiDataCache.METS.CASets.Keys | Select-Object -First 1
                $CASetID = $AkamaiDataCache.METS.CASets.$CASetName.CASetID

                $AkamaiDataCache.METS.CASets.$CASetName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.METS.CASets.$CASetName.CASetID | Should -Be $CASetID
                
                Clear-AkamaiDataCache -METSCaSetName $CASetName
                $AkamaiDataCache.METS.CASets.$CASetName | Should -BeNullOrEmpty
            }
            It 'clears a METS CA Set from the cache by ID' {
                # Populate the cache with a single item
                Get-METSCASet -CASetName $METSCASets[0].caSetName @CommonParams
                $CASetName = $AkamaiDataCache.METS.CASets.Keys | Select-Object -First 1
                $CASetID = $AkamaiDataCache.METS.CASets.$CASetName.CASetID

                $AkamaiDataCache.METS.CASets.$CASetName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.METS.CASets.$CASetName.CASetID | Should -Be $CASetID
                
                Clear-AkamaiDataCache -METSCaSetID $CASetID
                $AkamaiDataCache.METS.CASets.$CASetName | Should -BeNullOrEmpty
            }

            ## MOKS
            It 'clears a MOKS Client Cert from the cache by name' {
                # Populate the cache with a single item
                Get-MOKSClientCert -CertificateName $MOKSClientCerts[0].certificateName @CommonParams
                $ClientCertName = $AkamaiDataCache.MOKS.ClientCerts.Keys | Select-Object -First 1
                $ClientCertID = $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName.CertificateID

                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName.CertificateID | Should -Be $ClientCertID
                
                Clear-AkamaiDataCache -MOKSClientCertName $ClientCertName
                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName | Should -BeNullOrEmpty
            }
            It 'clears a MOKS Client Cert from the cache by ID' {
                # Populate the cache with a single item
                Get-MOKSClientCert -CertificateName $MOKSClientCerts[0].certificateName @CommonParams
                $ClientCertName = $AkamaiDataCache.MOKS.ClientCerts.Keys | Select-Object -First 1
                $ClientCertID = $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName.CertificateID

                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName.CertificateID | Should -Be $ClientCertID
                
                Clear-AkamaiDataCache -MOKSClientCertID $ClientCertID
                $AkamaiDataCache.MOKS.ClientCerts.$ClientCertName | Should -BeNullOrEmpty
            }

            ## Property
            It 'clears a property from the cache by name' {
                # Populate the cache with a single item
                Get-Property -PropertyName $Properties[0].propertyName @CommonParams
                $PropertyName = $AkamaiDataCache.Property.Properties.Keys | Select-Object -First 1
                $PropertyID = $AkamaiDataCache.Property.Properties.$PropertyName.propertyId

                $AkamaiDataCache.Property.Properties.$PropertyName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.Property.Properties.$PropertyName.propertyID | Should -Be $PropertyID
                
                Clear-AkamaiDataCache -PropertyName $PropertyName
                $AkamaiDataCache.Property.Properties.$PropertyName | Should -BeNullOrEmpty
            }
            It 'clears a property from the cache by ID' {
                # Populate the cache with a single item
                Get-Property -PropertyName $Properties[0].propertyName @CommonParams
                $PropertyName = $AkamaiDataCache.Property.Properties.Keys | Select-Object -First 1
                $PropertyID = $AkamaiDataCache.Property.Properties.$PropertyName.propertyId

                $AkamaiDataCache.Property.Properties.$PropertyName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.Property.Properties.$PropertyName.propertyID | Should -Be $PropertyID
                
                Clear-AkamaiDataCache -PropertyID $PropertyID
                $AkamaiDataCache.Property.Properties.$PropertyName | Should -BeNullOrEmpty
            }
            It 'clears an include from the cache by name' {
                # Populate the cache with a single item
                Get-PropertyInclude -IncludeName $Includes[0].includeName @CommonParams
                $IncludeName = $AkamaiDataCache.Property.Includes.Keys | Select-Object -First 1
                $IncludeID = $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID

                $AkamaiDataCache.Property.Includes.$IncludeName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID | Should -Be $IncludeID
                
                Clear-AkamaiDataCache -IncludeName $IncludeName
                $AkamaiDataCache.Property.Includes.$IncludeName | Should -BeNullOrEmpty
            }
            It 'clears an include from the cache by ID' {
                # Populate the cache with a single item
                Get-PropertyInclude -IncludeName $Includes[0].includeName @CommonParams
                $IncludeName = $AkamaiDataCache.Property.Includes.Keys | Select-Object -First 1
                $IncludeID = $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID

                $AkamaiDataCache.Property.Includes.$IncludeName | Should -Not -BeNullOrEmpty
                $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID | Should -Be $IncludeID
                
                Clear-AkamaiDataCache -IncludeID $IncludeID
                $AkamaiDataCache.Property.Includes.$IncludeName | Should -BeNullOrEmpty
            }

            AfterAll {
                Remove-Item -Path $env:AkamaiOptionsPath -Force
                $env:AkamaiOptionsPath = $PreviousOptionsPath
            }
        }
        

        Context 'Set-AkamaiDataCache' -Tag 'Set-AkamaiDataCache' {
            # API Endpoint
            It 'adds an API endpoint to the cache' {
                Set-AkamaiDataCache -APIEndpointName test -APIEndpointID 12345
                $AkamaiDataCache.APIDefinitions.APIEndpoints.test.APIEndpointID | Should -Be 12345
            }
            # AppSec Config
            It 'adds an appsec config to the cache' {
                Set-AkamaiDataCache -AppSecConfigName test -AppSecConfigID 12345
                $AkamaiDataCache.AppSec.Configs.test.ConfigID | Should -Be 12345
            }
            # AppSec Policy
            It 'adds an appsec policy to the cache' {
                Set-AkamaiDataCache -AppSecConfigName test -AppSecPolicyName test -AppSecPolicyID plc_12345
                $AkamaiDataCache.AppSec.Configs.test.Policies.test.PolicyID | Should -Be plc_12345
            }
            # Client List
            It 'adds a client list to the cache' {
                Set-AkamaiDataCache -ClientListName test -ClientListID 12345_TEST
                $AkamaiDataCache.ClientLists.Lists.test.ListID | Should -Be 12345_TEST
            }
            # EdgeWorkers
            It 'adds an edgeworker to the cache' {
                Set-AkamaiDataCache -EdgeWorkerName test -EdgeWorkerID 12345
                $AkamaiDataCache.EdgeWorkers.EdgeWorkers.test.EdgeWorkerID | Should -Be 12345
            }
            # METS
            It 'adds a METS CA set to the cache' {
                Set-AkamaiDataCache -METSCaSetName test -METSCaSetID 12345
                $AkamaiDataCache.METS.CASets.test.CASetID | Should -Be 12345
            }
            # MOKS
            It 'adds a MOKS client cert to the cache' {
                Set-AkamaiDataCache -MOKSClientCertName test -MOKSClientCertID 12345
                $AkamaiDataCache.MOKS.ClientCerts.test.CertificateID | Should -Be 12345
            }
            # Property
            It 'adds a property to the cache' {
                Set-AkamaiDataCache -PropertyName test -PropertyID 12345
                $AkamaiDataCache.Property.Properties.test.PropertyID | Should -Be 12345
            }
            It 'adds an include to the cache' {
                Set-AkamaiDataCache -IncludeName test -IncludeID 12345
                $AkamaiDataCache.Property.Includes.test.IncludeID | Should -Be 12345
            }
            AfterAll {
                Clear-AkamaiDataCache
            }
        }
    }

    Context 'Uninstall-Akamai' -Tag 'Uninstall-Akamai' {
        # -------------------------------------------------------------------------------------------------------
        #  This context must go LAST as it performs a global Remove-Module Akamai* after the uninstall completes 
        # -------------------------------------------------------------------------------------------------------
        BeforeAll {
            $OldProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue'

            $ModuleName = 'Akamai.Common'
            $OldModuleName = 'AkamaiPowershell'
            $ModuleInstallVersions = '2.1.0', '2.0' # Make sure these are in descending order
            $ModuleCheckVersions = '2.1.0', '2.0.0' # Versions to check need 3rd element, as this is always included in the release
            $OldModuleInstallVersions = '1.13', '1.12', '1.8.0' # Make sure these are in descending order
            $OldModuleCheckVersions = '1.13.0', '1.12', '1.8.0' # Versions to check need 3rd element, as this is always included in the release
            New-Item -ItemType Directory -Path 'TestDrive:/Modules'
        }
        It 'Removes only the oldest version of v1' {
            $OldModuleInstallVersions | ForEach-Object {
                Find-Module -Name $OldModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            Uninstall-Akamai -ModulePath 'TestDrive:/Modules' -AllButLatest -Confirm:$false
            $OldModuleNotLatest = $OldModuleCheckVersions[1..($OldModuleCheckVersions.Count - 1)]
            $OldModuleNotLatest | ForEach-Object {
                "TestDrive:/Modules/$OldModuleName/$_" | Should -Not -Exist
            }
        }
        It 'Removes all older versions when v1 and 2 are present' {
            $ModuleInstallVersions | ForEach-Object {
                Find-Module -Name $ModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            $OldModuleInstallVersions | ForEach-Object {
                Find-Module -Name $OldModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            Uninstall-Akamai -ModulePath 'TestDrive:/Modules' -AllButLatest -Confirm:$false
            $OldModuleNotLatest = $OldModuleCheckVersions[1..($OldModuleCheckVersions.Count - 1)]
            $OldModuleNotLatest | ForEach-Object {
                "TestDrive:/Modules/$OldModuleName/$_" | Should -Not -Exist
            }
            $ModuleNotLatest = $ModuleCheckVersions[1..($ModuleCheckVersions.Count - 1)]
            $ModuleNotLatest | ForEach-Object {
                "TestDrive:/Modules/$ModuleName/$_" | Should -Not -Exist
            }
        }
        It 'Removes all versions of v1' {
            $ModuleInstallVersions | ForEach-Object {
                Find-Module -Name $ModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            $OldModuleInstallVersions | ForEach-Object {
                Find-Module -Name $OldModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            Uninstall-Akamai -ModulePath 'TestDrive:/Modules' -AllV1 -Confirm:$false
            "TestDrive:/Modules/$OldModuleName" | Should -Not -Exist
            $ModuleCheckVersions | ForEach-Object {
                "TestDrive:/Modules/$ModuleName/$_" | Should -Exist
            }
        }
        It 'Removes only the the specified version' {
            $ModuleInstallVersions | ForEach-Object {
                Find-Module -Name $ModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            Uninstall-Akamai -ModulePath 'TestDrive:/Modules' -Version $ModuleInstallVersions[0] -Confirm:$false
            "TestDrive:/Modules/$ModuleName/$($ModuleCheckVersions[0])" | Should -Not -Exist
            $ModuleCheckVersions[1..($ModuleCheckVersions.Count - 1)] | ForEach-Object {
                "TestDrive:/Modules/$ModuleName/$_" | Should -Exist
            }
        }
        It 'Removes all versions' {
            $ModuleInstallVersions | ForEach-Object {
                Find-Module -Name $ModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            $OldModuleInstallVersions | ForEach-Object {
                Find-Module -Name $OldModuleName -Repository PSGallery -MaximumVersion $_ | Save-Module -Path 'TestDrive:/Modules'
            }
            Uninstall-Akamai -ModulePath 'TestDrive:/Modules' -All -Confirm:$false
            "TestDrive:/Modules/$OldModuleName" | Should -Not -Exist
            "TestDrive:/Modules/$ModuleName" | Should -Not -Exist
        }
        AfterEach {
            Get-ChildItem -Path 'TestDrive:/Modules' | Remove-Item -Recurse -Force
        }
        AfterAll {
            Remove-Item -Path 'TestDrive:/Modules' -Force -Recurse
            $ProgressPreference = $OldProgressPreference
        }
    }

    Context 'Aliases' -Tag 'Aliases' {
        It 'has an alias for Invoke-AkamaiRequest' {
            $Alias = Get-Alias -Definition Invoke-AkamaiRequest
            $Alias.name | Should -Be 'iar'
        }
        
        It 'has an alias for Invoke-AkamaiRestMethod' {
            $Alias = Get-Alias -Definition Invoke-AkamaiRestMethod
            $Alias.name | Should -Be 'iarm'
        }
    }


    AfterAll {
        ## Clean up env variables
        if ($Env:AKAMAI_HOST) {
            Remove-Item -Path env:\AKAMAI_HOST
        }
        if ($Env:AKAMAI_CLIENT_TOKEN) {
            Remove-Item -Path env:\AKAMAI_CLIENT_TOKEN
        }
        if ($Env:AKAMAI_ACCESS_TOKEN) {
            Remove-Item -Path env:\AKAMAI_ACCESS_TOKEN
        }
        if ($Env:AKAMAI_CLIENT_SECRET) {
            Remove-Item -Path env:\AKAMAI_CLIENT_SECRET
        }
        if ($Env:AKAMAI_PESTER_HOST) {
            Remove-Item -Path env:\AKAMAI_PESTER_HOST
        }
        if ($Env:AKAMAI_PESTER_CLIENT_TOKEN) {
            Remove-Item -Path env:\AKAMAI_PESTER_CLIENT_TOKEN
        }
        if ($Env:AKAMAI_PESTER_ACCESS_TOKEN) {
            Remove-Item -Path env:\AKAMAI_PESTER_ACCESS_TOKEN
        }
        if ($Env:AKAMAI_PESTER_CLIENT_SECRET) {
            Remove-Item -Path env:\AKAMAI_PESTER_CLIENT_SECRET
        }
        if ($Env:NETSTORAGE_CPCODE) {
            Remove-Item -Path env:\NETSTORAGE_CPCODE
        }
        if ($Env:NETSTORAGE_GROUP) {
            Remove-Item -Path env:\NETSTORAGE_GROUP
        }
        if ($Env:NETSTORAGE_KEY) {
            Remove-Item -Path env:\NETSTORAGE_KEY
        }
        if ($Env:NETSTORAGE_ID) {
            Remove-Item -Path env:\NETSTORAGE_ID
        }
        if ($Env:NETSTORAGE_HOST) {
            Remove-Item -Path env:\NETSTORAGE_HOST
        }
    }
}
