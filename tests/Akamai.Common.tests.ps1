Describe 'Safe Shared Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestAuthFile = $env:PesterSafeAuthFile
        $TestClearTextString = 'This is my test string!'
        $TestBase64EncodedString = 'VGhpcyBpcyBteSB0ZXN0IHN0cmluZyE='
        $TestURLEncodedString = 'This%20is%20my%20test%20string!'
        $TestUnsanitizedQuery = 'one=1&two=&three=3&four='
        $TestSanitisedQuery = 'one=1&three=3'
        $TestUnsanitizedFileName = 'This\looks!Kinda<"bad">.txt'
        $TestSanitizedFileName = 'This%5Clooks!Kinda%3C%22bad%22%3E.txt'
        $PD = @{}
    }

    Context 'ConvertFrom-Base64' {
        It 'decodes successfully' {
            $PD.Bas64Decode = ConvertFrom-Base64 -EncodedString $TestBase64EncodedString
            $PD.Bas64Decode | Should -Be $TestClearTextString
        }
    }

    Context 'Convert-URL' {
        It 'decodes successfully' {
            $PD.URLDecode = Convert-URL -EncodedString $TestURLEncodedString
            $PD.URLDecode | Should -Be $TestClearTextString
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

    Context 'Get-AkamaiCredentials from edgerc' {
        It 'parses correctly' {
            $PD.Auth = Get-AkamaiCredentials @CommonParams
            $PD.Auth.client_token | Should -Not -BeNullOrEmpty
            $PD.Auth.access_token | Should -Not -BeNullOrEmpty
            $PD.Auth.client_secret | Should -Not -BeNullOrEmpty
            $PD.Auth.host | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Confirm-Auth' {
        It 'prints nothing' {
            $PD.AuthErrors = Confirm-Auth -Auth $PD.Auth
            $PD.AuthErrors | Should -BeNullOrEmpty
        }
    }

    Context 'Get-AkamaiCredentials from environment, default section' {
        It 'parses correctly' {
            $env:AKAMAI_HOST = 'env-host'
            $env:AKAMAI_CLIENT_TOKEN = 'env-client_token'
            $env:AKAMAI_ACCESS_TOKEN = 'env-access_token'
            $env:AKAMAI_CLIENT_SECRET = 'env-client_secret'
            $PD.DefaultEnvAuth = Get-AkamaiCredentials
            $PD.DefaultEnvAuth.client_token | Should -Be 'env-client_token'
            $PD.DefaultEnvAuth.access_token | Should -Be 'env-access_token'
            $PD.DefaultEnvAuth.client_secret | Should -Be 'env-client_secret'
            $PD.DefaultEnvAuth.host | Should -Be 'env-host'
        }
    }

    Context 'Get-AkamaiCredentials from environment, custom section' {
        $env:AKAMAI_CUSTOM_HOST = 'customenv-host'
        It 'parses correctly' {
            $env:AKAMAI_CUSTOM_CLIENT_TOKEN = 'customenv-client_token'
            $env:AKAMAI_CUSTOM_ACCESS_TOKEN = 'customenv-access_token'
            $env:AKAMAI_CUSTOM_CLIENT_SECRET = 'customenv-client_secret'
            $PD.CustomEnvAuth = Get-AkamaiCredentials -Section Custom
            $PD.CustomEnvAuth.client_token | Should -Be 'customenv-client_token'
            $PD.CustomEnvAuth.access_token | Should -Be 'customenv-access_token'
            $PD.CustomEnvAuth.client_secret | Should -Be 'customenv-client_secret'
            $PD.CustomEnvAuth.host | Should -Be 'customenv-host'
        }
    }

    Context 'Get-AkamaiCredentials from session' {
        It 'parses correctly' {
            New-AkamaiSession -ClientSecret 'session-client_secret' -HostName 'session-host' -ClientAccessToken 'session-access_token' -ClientToken 'session-client_token'
            $PD.SessionAuth = Get-AkamaiCredentials
            $PD.SessionAuth.client_token | Should -Be 'session-client_token'
            $PD.SessionAuth.access_token | Should -Be 'session-access_token'
            $PD.SessionAuth.client_secret | Should -Be 'session-client_secret'
            $PD.SessionAuth.host | Should -Be 'session-host'
        }
    }

    Context 'Get-NetstorageCredentials from file' {
        It 'parses correctly' {
            $PD.NSAuth = Get-NetstorageCredentials -AuthFile $TestAuthFile -Section $Section
            $PD.NSAuth.cpcode | Should -Not -BeNullOrEmpty
            $PD.NSAuth.group | Should -Not -BeNullOrEmpty
            $PD.NSAuth.key | Should -Not -BeNullOrEmpty
            $PD.NSAuth.id | Should -Not -BeNullOrEmpty
            $PD.NSAuth.host | Should -Not -BeNullOrEmpty
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

    AfterAll {
        ## Clean up env variables
        Remove-Item -Path env:\AKAMAI_HOST
        Remove-Item -Path env:\AKAMAI_CLIENT_TOKEN
        Remove-Item -Path env:\AKAMAI_ACCESS_TOKEN
        Remove-Item -Path env:\AKAMAI_CLIENT_SECRET
        Remove-Item -Path env:\AKAMAI_CUSTOM_HOST
        Remove-Item -Path env:\AKAMAI_CUSTOM_CLIENT_TOKEN
        Remove-Item -Path env:\AKAMAI_CUSTOM_ACCESS_TOKEN
        Remove-Item -Path env:\AKAMAI_CUSTOM_CLIENT_SECRET
        Remove-Item -Path env:\NETSTORAGE_CPCODE
        Remove-Item -Path env:\NETSTORAGE_GROUP
        Remove-Item -Path env:\NETSTORAGE_KEY
        Remove-Item -Path env:\NETSTORAGE_ID
        Remove-Item -Path env:\NETSTORAGE_HOST
    }
}