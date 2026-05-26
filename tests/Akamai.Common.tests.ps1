BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Common Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'

        # Load modules
        $TestModules = 'Akamai.Common'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }

        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestNSRCFile = $env:PesterNSRCFile
        $TestClearTextString = 'This is my test string!'
        $TestBase64EncodedString = 'VGhpcyBpcyBteSB0ZXN0IHN0cmluZyE='
        $TestURLEncodedString = 'This%20is%20my%20test%20string!'
        $TestEncryptionKey = '0123456789abcdef0123456789abcdef'
        $TestCipherText = 'qKaQxHwOUbrI/9v6MX2Z26oiu7ZO0H+bTd5b8udS71I='
        $TestUnsanitizedQuery = 'one=1&two=&three=3&four='
        $TestSanitisedQuery = 'one=1&three=3'
        $TestUnsanitizedFileName = 'This\looks!Kinda<"bad">.txt'
        $TestSanitizedFileName = 'This%5Clooks!Kinda%3C%22bad%22%3E.txt'
        $TestContractID = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID

        # Remove unneeded type data for PS5.1. Fixes array-based object conversion to JSON
        Remove-TypeData -ErrorAction Ignore System.Array

        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'Invoke-AkamaiRequest' -Tag 'Invoke-AkamaiRequest' {
        BeforeAll {
            $PropertyName = "pester-akamai.common-$Timestamp"
            $NewPropertyBody = @{
                'productId'    = 'Fresca'
                'propertyName' = $PropertyName
            }
            $NewPropertyBodyString = $NewPropertyBody | ConvertTo-Json
            $NewPropertyBody.propertyName += "-2"
        }
        Context 'Methods' -Tag 'IAR Methods' {
            Context 'GET' {
                It 'succeeds to a simple endpoint' {
                    $TestParams = @{
                        'Path' = '/papi/v1/contracts'
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
                It 'succeeds to a simple endpoint with method specified' {
                    $TestParams = @{
                        'Path'   = '/papi/v1/contracts'
                        'Method' = 'GET'
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
            }
            Context 'POST' {
                It 'Create property with string body' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'POST'
                        'Body'   = $NewPropertyBodyString
                    }
                    $PD.NewProperty1 = Invoke-AkamaiRequest @TestParams @CommonParams
                    $PD.NewProperty1.body | Should -BeOfType PSCustomObject
                    $PD.NewProperty1.body.propertyLink | Should -Not -BeNullOrEmpty
                    $PD.NewProperty1.status | Should -Be 201
                    $PD.NewProperty1.headers | Should -Not -BeNullOrEmpty

                    $PD.PropertyID1 = $PD.NewProperty1.body.propertyLink.Split('/')[-1].Split('?')[0]
                }
                It 'Create property with object body' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'POST'
                        'Body'   = $NewPropertyBody
                    }
                    $PD.NewProperty2 = Invoke-AkamaiRequest @TestParams @CommonParams
                    $PD.NewProperty2.body | Should -BeOfType PSCustomObject
                    $PD.NewProperty2.body.propertyLink | Should -Not -BeNullOrEmpty
                    $PD.NewProperty2.status | Should -Be 201
                    $PD.NewProperty2.headers | Should -Not -BeNullOrEmpty

                    $PD.PropertyID2 = $PD.NewProperty2.body.propertyLink.Split('/')[-1].Split('?')[0]
                }
            }
            Context 'PUT' {
                BeforeAll {
                    $TestParams = @{
                        'Path' = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                    }
                    $PD.RulesResponse = Invoke-AkamaiRequest @TestParams @CommonParams
                }
                It 'Updates Property 1 by Object' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'PUT'
                        'Body'   = $PD.RulesResponse.body
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.rules | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
                It 'Updates Property 1 by string' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'PUT'
                        'Body'   = $PD.RulesResponse.body | ConvertTo-Json -Depth 100
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.rules | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
            }
            Context 'PATCH' {
                BeforeAll {
                    $PatchBody = [PSCustomObject] @(
                        @{
                            'op'    = 'replace'
                            'path'  = '/rules/children/0'
                            'value' = $PD.RulesResponse.body.rules.children[0]
                        }
                    )
                    $PatchBodyString = ConvertTo-Json -Depth 100 -InputObject $PatchBody
                }
                It 'Patches Property 1 by Object' {
                    $TestParams = @{
                        'Path'              = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method'            = 'PATCH'
                        'Body'              = $PatchBody
                        'AdditionalHeaders' = @{ 'content-type' = 'application/json-patch+json' }
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.rules | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
                It 'Patches Property 1 by string' {
                    $TestParams = @{
                        'Path'              = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method'            = 'PATCH'
                        'Body'              = $PatchBodyString
                        'AdditionalHeaders' = @{ 'content-type' = 'application/json-patch+json' }
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.rules | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
            }
            Context 'HEAD' {
                It 'HEADs Property 1' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties/$($PD.PropertyID1)/versions/1/rules?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'HEAD'
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.status | Should -Be 204
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
            }
            Context 'DELETE' {
                It 'Deletes Property 1' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties/$($PD.PropertyID1)?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'DELETE'
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.message | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
                It 'Deletes Property 2' {
                    $TestParams = @{
                        'Path'   = "/papi/v1/properties/$($PD.PropertyID2)?contractId=$TestContractID&groupId=$TestGroupID"
                        'Method' = 'DELETE'
                    }
                    $Response = Invoke-AkamaiRequest @TestParams @CommonParams
                    $Response.body | Should -BeOfType PSCustomObject
                    $Response.body.message | Should -Not -BeNullOrEmpty
                    $Response.status | Should -Be 200
                    $Response.headers | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'Error Handling' -Tag 'IAR Error Handling' {
            It 'handles a 404 error' {
                $TestParams = @{
                    'Path' = '/papi/v1/contracts/bananas'
                }
                { Invoke-AkamaiRequest @TestParams @CommonParams } | Should -Throw '*HTTP 404 - Not Found - The system was unable to locate the requested resource.*'
            }
            It 'handles a 500 error' {
                Mock -CommandName Invoke-WebRequest -ModuleName Akamai.Common -MockWith {
                    Invoke-WebRequest -Uri "https://httpbun.com/status/500" -Method GET
                }
                $TestParams = @{
                    'Path' = '/papi/v1/contracts'
                }
                { Invoke-AkamaiRequest @TestParams @CommonParams } | Should -Throw 'HTTP 500 - . *'
            }
            It 'handles a total failure' {
                Mock -CommandName Invoke-WebRequest -ModuleName Akamai.Common -MockWith {
                    throw 'Dang it!'
                }
                $TestParams = @{
                    'Path' = '/papi/v1/contracts'
                }
                { Invoke-AkamaiRequest @TestParams @CommonParams } | Should -Throw 'Dang it!'
            }
        }
    }

    Context 'Invoke-NetstorageRequest' -Tag 'Invoke-NetstorageRequest' {
        BeforeAll {
            Import-Module $PSScriptRoot/../dist/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force -Function New-NetstorageCredentials
            $NSCreds = New-NetstorageCredentials -UploadAccountID 'pester' @CommonParams
            $NSCreds | Export-NetstorageCredentials -NSRCFile 'TestDrive:/.nsrc' -Section pester
        }
        It 'make a successful request' {
            $TestParams = @{
                'Path'              = '/'
                'Action'            = 'dir'
                'AdditionalOptions' = @{
                    'format' = 'sql'
                }
                'NSRCFile'          = 'TestDrive:/.nsrc'
                'Section'           = 'pester'
            }
            $Response = Invoke-NetstorageRequest @TestParams
            $Response.xml | Should -Not -BeNullOrEmpty
            $Response.stat.directory | Should -Be "/$($NSCreds.cpcode)"
            $Response.stat.file.count | Should -BeGreaterThan 0
            $Response.stat.file[0].type | Should -Not -BeNullOrEmpty
            $Response.stat.file[0].name | Should -Not -BeNullOrEmpty
            $Response.stat.file[0].bytes | Should -Not -BeNullOrEmpty
        }
        AfterAll {
            Remove-Module Akamai.Netstorage
        }
    }

    Context 'ConvertFrom-Base64' -Tag 'ConvertFrom-Base64', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/ConvertFrom-Base64.ps1
        }
        It 'decodes successfully' {
            $TestParams = @{
                'EncodedString' = $TestBase64EncodedString
            }
            $PD.Bas64Decode = ConvertFrom-Base64 @TestParams
            $PD.Bas64Decode | Should -Be $TestClearTextString
        }
        AfterAll {
            Remove-Item Function:/ConvertFrom-Base64
        }
    }

    Context 'ConvertTo-Base64' -Tag 'ConvertTo-Base64', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/ConvertTo-Base64.ps1
        }
        It 'encodes successfully' {
            $TestParams = @{
                'UnencodedString' = $TestClearTextString
            }
            $PD.Base64Encode = ConvertTo-Base64 @TestParams
            $PD.Base64Encode | Should -Be $TestBase64EncodedString
        }
        AfterAll {
            Remove-Item Function:/ConvertTo-Base64
        }
    }

    Context 'Get-EncryptedMessage' -Tag 'Get-EncryptedMessage', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-EncryptedMessage.ps1
        }
        It 'encrypts correctly' {
            $TestParams = @{
                'secret'  = $TestEncryptionKey
                'message' = $TestClearTextString
            }
            $CipherText = Get-EncryptedMessage @TestParams
            $CipherText | Should -Be $TestCipherText
        }
        AfterAll {
            Remove-Item Function:/Get-EncryptedMessage
        }
    }

    Context 'Get-EdgegridAuthHeader' -Tag 'Get-EdgegridAuthHeader', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-EdgegridAuthHeader.ps1
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-EncryptedMessage.ps1
            $Credentials = Get-EdgegridCredentials @CommonParams
        }
        It 'retrieves a header matching the right format' {
            $TestParams = @{
                'Credentials'  = $Credentials
                'Method'       = 'GET'
                'ExpandedPath' = '/papi/v1/contracts'
            }
            $AuthHeader = Get-EdgegridAuthHeader @TestParams
            $AuthHeader | Should -Match "EG1-HMAC-SHA256 client_token=.*;access_token=.*;timestamp=.*;nonce=.*;signature=.*"
        }
        AfterAll {
            Remove-Item Function:/Get-EdgegridAuthHeader
            Remove-Item Function:/Get-EncryptedMessage
        }
    }

    Context 'Set-NetstorageAuthHeaders' -Tag 'Set-NetstorageAuthHeaders', 'private' {
        BeforeAll {
            Import-Module $PSScriptRoot/../dist/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force -Function New-NetstorageCredentials
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Set-NetstorageAuthHeaders.ps1
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-EncryptedMessage.ps1
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-RandomString.ps1
            $Credentials = New-NetstorageCredentials -UploadAccountID 'pester' @CommonParams
        }
        It 'retrieves auth headers matching the right format' {
            $Headers = @{
                "Host" = "example-nsu.akamaihd.net"
            }
            $TestParams = @{
                'Headers'     = $Headers
                'Credentials' = $Credentials
            }
            $Headers = Set-NetstorageAuthHeaders @TestParams
            $Headers['X-Akamai-ACS-Auth-Data'] | Should -Match "5, 0.0.0.0, 0.0.0.0, *"
            $Headers['X-Akamai-ACS-Auth-Sign'] | Should -Not -BeNullOrEmpty
        }
        AfterAll {
            Remove-Item Function:/Set-NetstorageAuthHeaders
            Remove-Item Function:/Get-EncryptedMessage
            Remove-Item Function:/Get-RandomString
            Remove-Module Akamai.Netstorage
        }
    }

    Context 'Get-RandomString' -Tag 'Get-RandomString', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-RandomString.ps1
        }
        It 'produces alphabetical string' {
            $PD.RandomAlphabetical = Get-RandomString -Length 16 -Alphabetical
            $PD.RandomAlphabetical | Should -Match "[a-z]{16}"
        }
        It 'produces alphanumeric string' {
            $PD.RandomAlphaNumeric = Get-RandomString -Length 16 -AlphaNumeric
            $PD.RandomAlphaNumeric | Should -Match "[a-z0-9]{16}"
        }
        It 'produces numeric string' {
            $PD.RandomNumeric = Get-RandomString -Length 16 -Numeric
            $PD.RandomNumeric | Should -Match "[0-9]{16}"
        }
        It 'produces hex string' {
            $PD.RandomHex = Get-RandomString -Length 16 -Hex
            $PD.RandomHex | Should -Match "[a-f0-9]{16}"
        }
        AfterAll {
            Remove-Item Function:/Get-RandomString
        }
    }

    Context 'Format-QueryString' -Tag 'Format-QueryString', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Format-QueryString.ps1
        }
        It 'strips empty query params' {
            $PD.ParsedQuery = Format-QueryString -QueryString $TestUnsanitizedQuery
            $PD.ParsedQuery | Should -Be $TestSanitisedQuery
        }
        AfterAll {
            Remove-Item Function:/Format-QueryString
        }
    }


    Context 'Format-Filename' -Tag 'Format-Filename', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Format-Filename.ps1
        }
        It 'encodes invalid characters' {
            $PD.ParsedFileName = Format-Filename -Filename $TestUnsanitizedFileName
            $PD.ParsedFileName | Should -Be $TestSanitizedFilename
        }
        AfterAll {
            Remove-Item Function:/Format-Filename
        }
    }

    Context 'Get-AkamaiUserAgent' -Tag 'Get-AkamaiUserAgent', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-AkamaiUserAgent.ps1
        }
        It 'returns a user agent string' {
            $PD.UserAgent = Get-AkamaiUserAgent
            $PD.UserAgent | Should -BeLike "AkamaiPowershell/*"
        }
        AfterAll {
            Remove-Item Function:/Get-AkamaiUserAgent
        }
    }

    Context 'Get-BodyObject' -Tag 'Get-BodyObject', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Get-BodyObject.ps1
        }
        It 'converts a json string to an object' {
            $JsonBody = '{"name":"test","value":123}'
            $TestParams = @{
                'Source' = $JsonBody
            }
            $BodyObject = Get-BodyObject @TestParams
            $BodyObject | Should -BeOfType PSCustomObject
            $BodyObject.name | Should -Be 'test'
            $BodyObject.value | Should -Be 123
        }
        It 'converts a hashtable to an object' {
            $HashTableBody = @{
                'name'  = 'test'
                'value' = 123
            }
            $TestParams = @{
                'Source' = $HashTableBody
            }
            $BodyObject = Get-BodyObject @TestParams
            $BodyObject | Should -BeOfType PSCustomObject
            $BodyObject.name | Should -Be 'test'
            $BodyObject.value | Should -Be 123
        }
        It 'does not alter PSCustomObject sources' {
            $PSCustomObjectBody = [PSCustomObject] @{
                'name'  = 'test'
                'value' = 123
            }
            $TestParams = @{
                'Source' = $PSCustomObjectBody
            }
            $BodyObject = Get-BodyObject @TestParams
            $BodyObject | Should -BeOfType PSCustomObject
            $BodyObject.name | Should -Be 'test'
            $BodyObject.value | Should -Be 123
        }
        AfterAll {
            Remove-Item Function:/Get-BodyObject
        }
    }

    Context 'New-EdgeAuthToken' -Tag 'New-EdgeAuthToken' {
        BeforeAll {
            $Date = Get-Date
            $Now = ([DateTimeOffset]$Date).ToUnixTimeSeconds()
            $15MinutesFromNow = $Now + 900
            $HourFromNow = $Now + 3600
            $Secret = '123456abcdef'
            $Salt = 'sodiumchloride'
            $Data = 'android'
            $ID = 'hellomynameis'
            $IP = '1.2.3.4'
        }
        It 'generates a token with start and end' {
            $TestParams = @{
                'Secret'    = $Secret
                'StartTime' = $Now
                'EndTime'   = $HourFromNow
                'IP'        = $IP
                'Data'      = $Data
                'ID'        = $ID
            }
            $AuthToken = New-EdgeAuthToken @TestParams
            $AuthToken | Should -BeLike "*st=$Now~*"
            $AuthToken | Should -BeLike "*exp=$HourFromNow~*"
            $AuthToken | Should -BeLike "*ip=$IP~*"
            $AuthToken | Should -BeLike "*data=$data~*"
            $AuthToken | Should -BeLike "*id=$ID~*"
        }
        It 'generates a token with duration in seconds' {
            $TestParams = @{
                'Secret'            = $Secret
                'Start'             = $Now
                'DurationInSeconds' = 900
                'URL'               = $URL
                'IP'                = $IP
                'Data'              = $Data
                'ID'                = $ID
            }
            $AuthToken = New-EdgeAuthToken @TestParams
            $AuthToken | Should -BeLike "*exp=$15MinutesFromNow~*"
        }
        It 'generates a token with duration in minutes' {
            $TestParams = @{
                'Secret'            = $Secret
                'Start'             = $Now
                'DurationInMinutes' = 60
            }
            $AuthToken = New-EdgeAuthToken @TestParams
            $AuthToken | Should -BeLike "*exp=$HourFromNow~*"
        }
        It 'generates a token with duration in hours' {
            $TestParams = @{
                'Secret'          = $Secret
                'Start'           = $Now
                'DurationInHours' = 1
            }
            $AuthToken = New-EdgeAuthToken @TestParams
            $AuthToken | Should -BeLike "*exp=$HourFromNow~*"
        }
        It 'fails if the secret has invalid characters' {
            $TestParams = @{
                'Secret'          = '123456abcdeg'
                'Start'           = $Now
                'DurationInHours' = 1
            }
            { New-EdgeAuthToken @TestParams } | Should -Throw "Cannot validate argument on parameter 'Secret'*"
        }
        It 'fails if the secret has an odd number of characters' {
            $TestParams = @{
                'Secret'          = '123456abcdeff'
                'Start'           = $Now
                'DurationInHours' = 1
            }
            { New-EdgeAuthToken @TestParams } | Should -Throw "Secret must have an even number of hexadecimal characters"
        }
    }

    Context 'Test-ISO8601' -Tag 'Test-ISO8601', 'private' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.Common/Functions/Private/Test-ISO8601.ps1
        }
        It 'validates correct ISO8601 strings' {
            $ValidDates = @(
                '2024-06-01T12:00:00Z'
                '2024-06-01T12:00:00+00:00'
                '2024-06-01T08:00:00-04:00'
            )
            foreach ($Date in $ValidDates) {
                $TestParams = @{
                    'DateTime' = $Date
                }
                $Result = Test-ISO8601 @TestParams
                $Result | Should -BeNullOrEmpty
            }
        }
        It 'invalidates incorrect ISO8601 strings' {
            $InvalidDates = @(
                '2024/06/01 12:00:00'
                'June 1, 2024 12:00 PM'
            )
            foreach ($Date in $InvalidDates) {
                $TestParams = @{
                    'DateTime' = $Date
                }
                { Test-ISO8601 @TestParams } | Should -Throw "* is not a valid ISO 8601 datetime. Please ensure that the parameter is of the format 'YYYY-MM-DDThh:mm:ss(Z|+-HH)'"
            }
        }
        AfterAll {
            Remove-Item Function:/Test-ISO8601
        }
    }

    Context 'Test-OpenAPI' {
        It 'returns data successfully' {
            $PD.APIResult = Test-OpenAPI -Path '/papi/v1/contracts' @CommonParams
            $PD.APIResult.count | Should -Not -Be 0
        }
    }

    Context 'Edgegrid Credentials' -Tag 'Edgegrid Credentials' {
        Context 'Get-EdgegridCredentials' -Tag 'Get-EdgegridCredentials' {
            Context 'from edgerc' {
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
                        'EdgeRCFile' = $TestEdgeRCFile
                        'Section'    = 'not-default'
                    }
                }
                It 'reads an edgerc file correctly' {
                    $PD.Credentials = Get-EdgegridCredentials @TestParams
                    $PD.Credentials.ClientToken | Should -Be $TestClientToken
                    $PD.Credentials.AccessToken | Should -Be $TestAccessToken
                    $PD.Credentials.ClientSecret | Should -Be $TestClientSecret
                    $PD.Credentials.Host | Should -Be $TestHost
                    $PD.Credentials.AccountKey | Should -Be $TestASK
                }
                It 'overrides the account switch key when provided' {
                    $OverrideASK = Get-EdgegridCredentials @TestParams -AccountSwitchKey 'Pester'
                    $OverrideASK.ClientToken | Should -Be $TestClientToken
                    $OverrideASK.AccessToken | Should -Be $TestAccessToken
                    $OverrideASK.ClientSecret | Should -Be $TestClientSecret
                    $OverrideASK.Host | Should -Be $TestHost
                    $OverrideASK.AccountKey | Should -Be 'Pester'
                }
                It 'does not contain an account switch key when input is set to none' {
                    $TestParams.AccountSwitchKey = 'none'
                    $NoAsk = Get-EdgegridCredentials @TestParams
                    $NoAsk.ClientToken | Should -Be $TestClientToken
                    $NoAsk.AccessToken | Should -Be $TestAccessToken
                    $NoAsk.ClientSecret | Should -Be $TestClientSecret
                    $NoAsk.Host | Should -Be $TestHost
                    $NoAsk.AccountKey | Should -BeNullOrEmpty
                }
            }

            Context 'from environment, default section' {
                It 'parses correctly' {
                    $env:AKAMAI_HOST = 'env-host'
                    $env:AKAMAI_CLIENT_TOKEN = 'env-client_token'
                    $env:AKAMAI_ACCESS_TOKEN = 'env-access_token'
                    $env:AKAMAI_CLIENT_SECRET = 'env-client_secret'
                    $env:AKAMAI_ACCOUNT_KEY = 'env-account_key'
                    $PD.DefaultEnvAuth = Get-EdgegridCredentials
                    $PD.DefaultEnvAuth.ClientToken | Should -Be 'env-client_token'
                    $PD.DefaultEnvAuth.AccessToken | Should -Be 'env-access_token'
                    $PD.DefaultEnvAuth.ClientSecret | Should -Be 'env-client_secret'
                    $PD.DefaultEnvAuth.Host | Should -Be 'env-host'
                    $PD.DefaultEnvAuth.AccountKey | Should -Be 'env-account_key'
                }
                It 'overrides an account switch key when provided' {
                    $env:AKAMAI_HOST = 'env-host'
                    $env:AKAMAI_CLIENT_TOKEN = 'env-client_token'
                    $env:AKAMAI_ACCESS_TOKEN = 'env-access_token'
                    $env:AKAMAI_CLIENT_SECRET = 'env-client_secret'
                    $env:AKAMAI_ACCOUNT_KEY = 'env-account_key'
                    $PD.DefaultEnvAuth = Get-EdgegridCredentials -AccountSwitchKey 'provided-ask'
                    $PD.DefaultEnvAuth.ClientToken | Should -Be 'env-client_token'
                    $PD.DefaultEnvAuth.AccessToken | Should -Be 'env-access_token'
                    $PD.DefaultEnvAuth.ClientSecret | Should -Be 'env-client_secret'
                    $PD.DefaultEnvAuth.Host | Should -Be 'env-host'
                    $PD.DefaultEnvAuth.AccountKey | Should -Be 'provided-ask'
                }
            }

            Context 'from environment, custom section' {
                It 'parses correctly' {
                    $env:AKAMAI_PESTER_HOST = 'customenv-host'
                    $env:AKAMAI_PESTER_CLIENT_TOKEN = 'customenv-client_token'
                    $env:AKAMAI_PESTER_ACCESS_TOKEN = 'customenv-access_token'
                    $env:AKAMAI_PESTER_CLIENT_SECRET = 'customenv-client_secret'
                    $env:AKAMAI_PESTER_ACCOUNT_KEY = 'customenv-account_key'
                    $PD.CustomEnvAuth = Get-EdgegridCredentials -Section Pester
                    $PD.CustomEnvAuth.ClientToken | Should -Be 'customenv-client_token'
                    $PD.CustomEnvAuth.AccessToken | Should -Be 'customenv-access_token'
                    $PD.CustomEnvAuth.ClientSecret | Should -Be 'customenv-client_secret'
                    $PD.CustomEnvAuth.Host | Should -Be 'customenv-host'
                    $PD.CustomEnvAuth.AccountKey | Should -Be 'customenv-account_key'
                }
                It 'overrides an account switch key when provided' {
                    $env:AKAMAI_PESTER_HOST = 'customenv-host'
                    $env:AKAMAI_PESTER_CLIENT_TOKEN = 'customenv-client_token'
                    $env:AKAMAI_PESTER_ACCESS_TOKEN = 'customenv-access_token'
                    $env:AKAMAI_PESTER_CLIENT_SECRET = 'customenv-client_secret'
                    $env:AKAMAI_PESTER_ACCOUNT_KEY = 'provided-ask'
                    $PD.CustomEnvAuth = Get-EdgegridCredentials -Section Pester
                    $PD.CustomEnvAuth.ClientToken | Should -Be 'customenv-client_token'
                    $PD.CustomEnvAuth.AccessToken | Should -Be 'customenv-access_token'
                    $PD.CustomEnvAuth.ClientSecret | Should -Be 'customenv-client_secret'
                    $PD.CustomEnvAuth.Host | Should -Be 'customenv-host'
                    $PD.CustomEnvAuth.AccountKey | Should -Be 'provided-ask'
                }
            }

            AfterAll {
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

        Context 'Export-EdgegridCredentials' -Tag 'Export-EdgegridCredentials' {
            BeforeAll {
                $TargetEdgeRC = 'TestDrive:/test.edgerc'
                $Credentials = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8+RN='
                }
                $CredentialsWithASK = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8+RN='
                    'AccountKey'   = '1-2A345B:1-2ABC'
                }
            }
            It 'exports credentials to .edgerc file by pipeline' {
                $TargetEdgeRC = 'TestDrive:/test1.edgerc'
                $TestParams = @{
                    'EdgeRCFile' = $TargetEdgeRC
                }
                # Piping the object uses the AccountKey alias of AccountSwitchKey
                $Credentials | Export-EdgegridCredentials @TestParams
                $TargetEdgeRC | Should -FileContentMatch '[default]'
                $TargetEdgeRC | Should -FileContentMatch "host = $($Credentials.Host)"
                $TargetEdgeRC | Should -FileContentMatch "client_token = $($Credentials.ClientToken)"
                $TargetEdgeRC | Should -FileContentMatch "access_token = $($Credentials.AccessToken)"
                $TargetEdgeRC | Should -FileContentMatch "client_secret = $([Regex]::Escape($Credentials.ClientSecret))"
            }
            It 'exports credentials to .edgerc file by pipeline with ASK' {
                $TargetEdgeRC = 'TestDrive:/test2.edgerc'
                $TestParams = @{
                    'EdgeRCFile' = $TargetEdgeRC
                }
                $CredentialsWithASK | Export-EdgegridCredentials @TestParams
                $TargetEdgeRC | Should -FileContentMatch '[default]'
                $TargetEdgeRC | Should -FileContentMatch "host = $($CredentialsWithASK.Host)"
                $TargetEdgeRC | Should -FileContentMatch "client_token = $($CredentialsWithASK.ClientToken)"
                $TargetEdgeRC | Should -FileContentMatch "access_token = $($CredentialsWithASK.AccessToken)"
                $TargetEdgeRC | Should -FileContentMatch "client_secret = $([Regex]::Escape($Credentials.ClientSecret))"
                $TargetEdgeRC | Should -FileContentMatch "account_key = $($CredentialsWithASK.AccountKey)"
            }
            It 'exports credentials to .edgerc file by parameter' {
                $TargetEdgeRC = 'TestDrive:/test3.edgerc'
                $TestParams = @{
                    'EdgeRCFile'   = $TargetEdgeRC
                    'Host'         = $Credentials.Host
                    'ClientToken'  = $Credentials.ClientToken
                    'AccessToken'  = $Credentials.AccessToken
                    'ClientSecret' = $Credentials.ClientSecret
                }
                Export-EdgegridCredentials @TestParams
                $TargetEdgeRC | Should -FileContentMatch '[default]'
                $TargetEdgeRC | Should -FileContentMatch "host = $($Credentials.Host)"
                $TargetEdgeRC | Should -FileContentMatch "client_token = $($Credentials.ClientToken)"
                $TargetEdgeRC | Should -FileContentMatch "access_token = $($Credentials.AccessToken)"
                $TargetEdgeRC | Should -FileContentMatch "client_secret = $([Regex]::Escape($Credentials.ClientSecret))"
            }
            It 'exports credentials to .edgerc file by parameter with ASK' {
                $TargetEdgeRC = 'TestDrive:/test4.edgerc'
                $TestParams = @{
                    'EdgeRCFile'   = $TargetEdgeRC
                    'Host'         = $CredentialsWithASK.Host
                    'ClientToken'  = $CredentialsWithASK.ClientToken
                    'AccessToken'  = $CredentialsWithASK.AccessToken
                    'ClientSecret' = $CredentialsWithASK.ClientSecret
                    'AccountKey'   = $CredentialsWithASK.AccountKey
                }
                Export-EdgegridCredentials @TestParams
                $TargetEdgeRC | Should -FileContentMatch '[default]'
                $TargetEdgeRC | Should -FileContentMatch "host = $($CredentialsWithASK.Host)"
                $TargetEdgeRC | Should -FileContentMatch "client_token = $($CredentialsWithASK.ClientToken)"
                $TargetEdgeRC | Should -FileContentMatch "access_token = $($CredentialsWithASK.AccessToken)"
                $TargetEdgeRC | Should -FileContentMatch "client_secret = $([Regex]::Escape($CredentialsWithASK.ClientSecret))"
                $TargetEdgeRC | Should -FileContentMatch "account_key = $($CredentialsWithASK.AccountKey)"
            }

            It 'exports credentials to .edgerc file to new section by pipeline' {
                $TargetEdgeRC = 'TestDrive:/test1.edgerc'
                $TestParams = @{
                    'EdgeRCFile' = $TargetEdgeRC
                    'Section'    = 'new'
                }
                $Credentials | Export-EdgegridCredentials @TestParams
                $ExpectedEdgeRCSection = "\[new\]\naccess_token = $($Credentials.AccessToken)\nclient_secret = $([Regex]::Escape($Credentials.ClientSecret))\nclient_token = $($Credentials.ClientToken)\nhost = $($Credentials.Host)"
                $TargetEdgeRC | Should -FileContentMatchMultiline $ExpectedEdgeRCSection
            }

            It 'fails when exporting to existing section without -Force' {
                $TargetEdgeRC = 'TestDrive:/test1.edgerc'
                $TestParams = @{
                    'EdgeRCFile' = $TargetEdgeRC
                    'Section'    = 'new'
                }
                { $Credentials | Export-EdgegridCredentials @TestParams } | Should -Throw
            }

            It 'exports credentials to .edgerc file to existing section with -Force' {
                $TargetEdgeRC = 'TestDrive:/test1.edgerc'
                $TestParams = @{
                    'EdgeRCFile' = $TargetEdgeRC
                    'Section'    = 'new'
                    'Force'      = $true
                }
                $Credentials | Export-EdgegridCredentials @TestParams
                $ExpectedEdgeRCSection = "\[new\]\naccess_token = $($Credentials.AccessToken)\nclient_secret = $([Regex]::Escape($Credentials.ClientSecret))\nclient_token = $($Credentials.ClientToken)\nhost = $($Credentials.Host)"
                $TargetEdgeRC | Should -FileContentMatchMultiline $ExpectedEdgeRCSection
            }
        }

        Context 'Import-EdgegridCredentials' -Tag 'Import-EdgegridCredentials' {
            BeforeAll {
                $ImportEdgeRC = 'TestDrive:/import.edgerc'
                $ImportEdgeRCASK = 'TestDrive:/import-ask.edgerc'
                $Credentials = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                }
                $CredentialsWithASK = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                    'AccountKey'   = '1-2A345B:1-2ABC'
                }
                $Credentials | Export-EdgegridCredentials -EdgeRCFile $ImportEdgeRC -Section 'default'
                $CredentialsWithASK | Export-EdgegridCredentials -EdgeRCFile $ImportEdgeRC -Section 'ask'
                $CredentialsWithASK | Export-EdgegridCredentials -EdgeRCFile $ImportEdgeRCASK
            }
            It 'loads credentials from default section to standard prefix' {
                $TestParams = @{
                    'EdgeRCFile' = $ImportEdgeRC
                }
                Import-EdgegridCredentials @TestParams
                $env:AKAMAI_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
            }
            It 'loads credentials from default section of file with account_key' {
                $TestParams = @{
                    'EdgeRCFile' = $ImportEdgeRCASK
                }
                Import-EdgegridCredentials @TestParams
                $env:AKAMAI_HOST | Should -Be $CredentialsWithASK.Host
                $env:AKAMAI_CLIENT_TOKEN | Should -Be $CredentialsWithASK.ClientToken
                $env:AKAMAI_ACCESS_TOKEN | Should -Be $CredentialsWithASK.AccessToken
                $env:AKAMAI_CLIENT_SECRET | Should -Be $CredentialsWithASK.ClientSecret
                $env:AKAMAI_ACCOUNT_KEY | Should -Be $CredentialsWithASK.AccountKey
            }
            It 'loads credentials from default section to standard prefix with custom ASK' {
                $TestParams = @{
                    'EdgeRCFile'       = $ImportEdgeRC
                    'AccountSwitchKey' = 'CustomASK'
                }
                Import-EdgegridCredentials @TestParams
                $env:AKAMAI_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
                $env:AKAMAI_ACCOUNT_KEY | Should -Be 'CustomASK'
            }
            It 'loads credentials from default section to custom prefix' {
                $TestParams = @{
                    'EdgeRCFile'        = $ImportEdgeRC
                    'EnvironmentPrefix' = 'pester'
                }
                Import-EdgegridCredentials @TestParams
                $env:AKAMAI_PESTER_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_PESTER_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_PESTER_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_PESTER_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
            }
            It 'loads credentials from custom section to custom prefix' {
                $TestParams = @{
                    'EdgeRCFile'        = $ImportEdgeRC
                    'Section'           = 'ask'
                    'EnvironmentPrefix' = 'pester'
                }
                Import-EdgegridCredentials @TestParams
                $env:AKAMAI_PESTER_HOST | Should -Be $CredentialsWithASK.Host
                $env:AKAMAI_PESTER_CLIENT_TOKEN | Should -Be $CredentialsWithASK.ClientToken
                $env:AKAMAI_PESTER_ACCESS_TOKEN | Should -Be $CredentialsWithASK.AccessToken
                $env:AKAMAI_PESTER_CLIENT_SECRET | Should -Be $CredentialsWithASK.ClientSecret
                $env:AKAMAI_PESTER_ACCOUNT_KEY | Should -Be $CredentialsWithASK.AccountKey
            }
            It 'loads credentials from input parameters to standard prefix' {
                $Credentials | Import-EdgegridCredentials
                $env:AKAMAI_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
            }
            It 'loads credentials from input parameters to custom prefix' {
                $TestParams = @{
                    'EnvironmentPrefix' = 'pester'
                }
                $Credentials | Import-EdgegridCredentials @TestParams
                $env:AKAMAI_PESTER_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_PESTER_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_PESTER_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_PESTER_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
            }
            It 'loads credentials from input parameters to standard prefix with custom ASK' {
                $TestParams = @{
                    'AccountSwitchKey' = 'CustomASK'
                }
                $Credentials | Import-EdgegridCredentials @TestParams
                $env:AKAMAI_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
                $env:AKAMAI_ACCOUNT_KEY | Should -Be 'CustomASK'
            }
            It 'loads credentials from input parameters to custom prefix with custom ask' {
                $TestParams = @{
                    'EnvironmentPrefix' = 'pester'
                    'AccountSwitchKey'  = 'CustomASK'
                }
                $Credentials | Import-EdgegridCredentials @TestParams
                $env:AKAMAI_PESTER_HOST | Should -Be $Credentials.Host
                $env:AKAMAI_PESTER_CLIENT_TOKEN | Should -Be $Credentials.ClientToken
                $env:AKAMAI_PESTER_ACCESS_TOKEN | Should -Be $Credentials.AccessToken
                $env:AKAMAI_PESTER_CLIENT_SECRET | Should -Be $Credentials.ClientSecret
                $env:AKAMAI_PESTER_ACCOUNT_KEY | Should -Be 'CustomASK'
            }

            AfterAll {
                Remove-Item -Path env:\AKAMAI_HOST
                Remove-Item -Path env:\AKAMAI_CLIENT_TOKEN
                Remove-Item -Path env:\AKAMAI_ACCESS_TOKEN
                Remove-Item -Path env:\AKAMAI_CLIENT_SECRET
                Remove-Item -Path env:\AKAMAI_ACCOUNT_KEY
                Remove-Item -Path env:\AKAMAI_PESTER_HOST
                Remove-Item -Path env:\AKAMAI_PESTER_CLIENT_TOKEN
                Remove-Item -Path env:\AKAMAI_PESTER_ACCESS_TOKEN
                Remove-Item -Path env:\AKAMAI_PESTER_CLIENT_SECRET
                Remove-Item -Path env:\AKAMAI_PESTER_ACCOUNT_KEY
            }
        }

        Context 'Clear-EdgegridCredentials' -Tag 'Clear-EdgegridCredentials' {
            BeforeAll {
                $ClearEdgeRC = 'TestDrive:/clear.edgerc'
                $ClearEdgeRCASK = 'TestDrive:/clear-ask.edgerc'
                $Credentials = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                }
                $CredentialsWithASK = [PSCustomObject] @{
                    'Host'         = 'akab-h05tnam3wl42son7nktnlnnx-kbob3i3v.luna.akamaiapis.net'
                    'ClientToken'  = 'akab-c113ntt0k3n4qtari252bfxxbsl-yvsdj'
                    'AccessToken'  = 'akab-acc35t0k3nodujqunph3w7hzp7-gtm6ij'
                    'ClientSecret' = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                    'AccountKey'   = '1-2A345B:1-2ABC'
                }
            }
            It 'clears default credentials' {
                $Credentials | Import-EdgegridCredentials
                Clear-EdgegridCredentials
                $env:AKAMAI_HOST | Should -BeNullOrEmpty
                $env:AKAMAI_CLIENT_TOKEN | Should -BeNullOrEmpty
                $env:AKAMAI_ACCESS_TOKEN | Should -BeNullOrEmpty
                $env:AKAMAI_CLIENT_SECRET | Should -BeNullOrEmpty
                $env:AKAMAI_ACCOUNT_KEY | Should -BeNullOrEmpty
            }
            It 'clears custom section credentials' {
                $CredentialsWithASK | Import-EdgegridCredentials -EnvironmentPrefix 'pester'
                Clear-EdgegridCredentials
                $env:AKAMAI_PESTER_HOST | Should -BeNullOrEmpty
                $env:AKAMAI_PESTER_CLIENT_TOKEN | Should -BeNullOrEmpty
                $env:AKAMAI_PESTER_ACCESS_TOKEN | Should -BeNullOrEmpty
                $env:AKAMAI_PESTER_CLIENT_SECRET | Should -BeNullOrEmpty
                $env:AKAMAI_PESTER_ACCOUNT_KEY | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Netstorage Credentials' -Tag 'Netstorage Credentials' {
        Context 'Get-NetstorageCredentials' -Tag 'Get-NetstorageCredentials' {
            BeforeAll {
                $Key = 'ab1cd2e3fgh46uhjk7l8mn90opq1rstu23vw4xyza5bc6d7'
                $ID = 'test1'
                $ID2 = 'test2'
                $Group = 'sample_group'
                $HostName = 'sample-nsu.akamaihd.net'
                $CPCode = 123456

                $Content = @"
[default]
key = $Key
id = $ID
group = $Group
host = $Hostname
cpcode = $CPCode

[two]
key = $Key
id = $ID2
group = $Group
host = $Hostname
cpcode = $CPCode
"@
                $NSRCFile = 'TestDrive:/test1.nsrc'
                $Content | Set-Content -Path $NSRCFile
            }
            Context 'from file' {
                It 'loads credentials from default section' {
                    $TestParams = @{
                        'NSRCFile' = $NSRCFile
                        'Section'  = 'default'
                    }
                    $Credentials = Get-NetstorageCredentials @TestParams
                    $Credentials.cpcode | Should -Be $CPCode
                    $Credentials.group | Should -Be $Group
                    $Credentials.key | Should -Be $Key
                    $Credentials.id | Should -Be $ID
                    $Credentials.host | Should -Be $Hostname
                }
                It 'loads credentials from custom section' {
                    $TestParams = @{
                        'NSRCFile' = $NSRCFile
                        'Section'  = 'two'
                    }
                    $Credentials = Get-NetstorageCredentials @TestParams
                    $Credentials.cpcode | Should -Be $CPCode
                    $Credentials.group | Should -Be $Group
                    $Credentials.key | Should -Be $Key
                    $Credentials.id | Should -Be $ID2
                    $Credentials.host | Should -Be $Hostname
                }
            }

            Context 'from default environment' {
                BeforeAll {
                    $env:NETSTORAGE_CPCODE = $CPCode
                    $env:NETSTORAGE_GROUP = $Group
                    $env:NETSTORAGE_KEY = $Key
                    $env:NETSTORAGE_ID = $ID
                    $env:NETSTORAGE_HOST = $Hostname
                }
                It 'parses correctly' {
                    $Credentials = Get-NetstorageCredentials
                    $Credentials.cpcode | Should -Be $CPCode
                    $Credentials.group | Should -Be $Group
                    $Credentials.key | Should -Be $Key
                    $Credentials.id | Should -Be $ID
                    $Credentials.host | Should -Be $Hostname
                }
            }

            Context 'from custom environment' {
                BeforeAll {
                    $env:NETSTORAGE_CUSTOM_CPCODE = $CPCode
                    $env:NETSTORAGE_CUSTOM_GROUP = $Group
                    $env:NETSTORAGE_CUSTOM_KEY = $Key
                    $env:NETSTORAGE_CUSTOM_ID = $ID
                    $env:NETSTORAGE_CUSTOM_HOST = $Hostname
                }
                It 'parses correctly' {
                    $TestParams = @{
                        'Section' = 'Custom'
                    }
                    $Credentials = Get-NetstorageCredentials @TestParams
                    $Credentials.cpcode | Should -Be $CPCode
                    $Credentials.group | Should -Be $Group
                    $Credentials.key | Should -Be $Key
                    $Credentials.id | Should -Be $ID
                    $Credentials.host | Should -Be $Hostname
                }
            }
            AfterAll {
                $env:NETSTORAGE_CPCODE = $null
                $env:NETSTORAGE_GROUP = $null
                $env:NETSTORAGE_KEY = $null
                $env:NETSTORAGE_ID = $null
                $env:NETSTORAGE_HOST = $null
                $env:NETSTORAGE_CUSTOM_CPCODE = $null
                $env:NETSTORAGE_CUSTOM_GROUP = $null
                $env:NETSTORAGE_CUSTOM_KEY = $null
                $env:NETSTORAGE_CUSTOM_ID = $null
                $env:NETSTORAGE_CUSTOM_HOST = $null
            }
        }

        Context 'Export-NetstorageCredentials' -Tag 'Export-NetstorageCredentials' {
            BeforeAll {
                $Credentials = [PSCustomObject] @{
                    'Key'    = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                    'ID'     = 'netstorage-id'
                    'Group'  = 'netstorage-group'
                    'Host'   = 'netstorage-host'
                    'cpcode' = 123456
                }
            }
            It 'exports credentials to .nsrc file in default section by pipeline' {
                $TargetNSRCFile = 'TestDrive:/export1.nsrc'
                $TestParams = @{
                    'NSRCFile' = $TargetNSRCFile
                }
                # Piping the object uses the Host alias of Hostname, which we need because you can't set a param named 'host' in a function
                $Credentials | Export-NetstorageCredentials @TestParams
                $TargetNSRCFile | Should -FileContentMatch '[default]'
                $TargetNSRCFile | Should -FileContentMatch "host = $($Credentials.Host)"
                $TargetNSRCFile | Should -FileContentMatch "group = $($Credentials.Group)"
                $TargetNSRCFile | Should -FileContentMatch "id = $($Credentials.ID)"
                $TargetNSRCFile | Should -FileContentMatch "key = $($Credentials.Key)"
                $TargetNSRCFile | Should -FileContentMatch "cpcode = $($Credentials.cpcode)"
            }

            It 'exports credentials to .nsrc file in default section by parameter' {
                $TargetNSRCFile = 'TestDrive:/export2.nsrc'
                $TestParams = @{
                    'NSRCFile' = $TargetNSRCFile
                    'Key'      = $Credentials.Key
                    'ID'       = $Credentials.ID
                    'Group'    = $Credentials.Group
                    'Host'     = $Credentials.Host
                    'cpcode'   = $Credentials.CPCode
                }
                Export-NetstorageCredentials @TestParams
                $TargetNSRCFile | Should -FileContentMatch '[default]'
                $TargetNSRCFile | Should -FileContentMatch "host = $($Credentials.Host)"
                $TargetNSRCFile | Should -FileContentMatch "group = $($Credentials.Group)"
                $TargetNSRCFile | Should -FileContentMatch "id = $($Credentials.ID)"
                $TargetNSRCFile | Should -FileContentMatch "key = $($Credentials.Key)"
                $TargetNSRCFile | Should -FileContentMatch "cpcode = $($Credentials.cpcode)"
            }

            It 'exports credentials to .nsrc file to new section by pipeline' {
                $TargetNSRCFile = 'TestDrive:/export1.nsrc'
                $TestParams = @{
                    'NSRCFile' = $TargetNSRCFile
                    'Section'  = 'new'
                }
                $Credentials | Export-NetstorageCredentials @TestParams
                $ExpectedAuthSection = "\[new\]\ncpcode = $($Credentials.cpcode)\ngroup = $($Credentials.Group)\nhost = $($Credentials.Host)\nid = $($Credentials.ID)\nkey = $($Credentials.Key)"
                $TargetNSRCFile | Should -FileContentMatchMultiline $ExpectedAuthSection
            }

            It 'fails when exporting to existing section without -Force' {
                $TargetNSRCFile = 'TestDrive:/export1.nsrc'
                $TestParams = @{
                    'NSRCFile' = $TargetNSRCFile
                    'Section'  = 'new'
                }
                { $Credentials | Export-NetstorageCredentials @TestParams } | Should -Throw
            }

            It 'exports credentials to .nsrc file to existing section with -Force' {
                $TargetNSRCFile = 'TestDrive:/export1.nsrc'
                $TestParams = @{
                    'NSRCFile' = $TargetNSRCFile
                    'Section'  = 'new'
                    'Force'    = $true
                }
                $Credentials | Export-NetstorageCredentials @TestParams
                $ExpectedAuthSection = "\[new\]\ncpcode = $($Credentials.cpcode)\ngroup = $($Credentials.Group)\nhost = $($Credentials.Host)\nid = $($Credentials.ID)\nkey = $($Credentials.Key)"
                $TargetNSRCFile | Should -FileContentMatchMultiline $ExpectedAuthSection
            }
        }

        Context 'Import-NetstorageCredentials' -Tag 'Import-NetstorageCredentials' {
            BeforeAll {
                $ImportNSRCFile = 'TestDrive:/import.nsrc'
                $Credentials = [PSCustomObject] @{
                    'Key'    = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                    'ID'     = 'netstorage-id'
                    'Group'  = 'netstorage-group'
                    'Host'   = 'netstorage-host'
                    'cpcode' = 123456
                }
                $Credentials2 = [PSCustomObject] @{
                    'Key'    = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN=2'
                    'ID'     = 'netstorage-id2'
                    'Group'  = 'netstorage-group2'
                    'Host'   = 'netstorage-host2'
                    'cpcode' = 123457
                }

                $Credentials | Export-NetstorageCredentials -NSRCFile $ImportNSRCFile -Section 'default'
                $Credentials2 | Export-NetstorageCredentials -NSRCFile $ImportNSRCFile -Section 'two'
            }
            It 'loads credentials from default section to standard prefix' {
                $TestParams = @{
                    'NSRCFile' = $ImportNSRCFile
                }
                Import-NetstorageCredentials @TestParams
                $env:NETSTORAGE_GROUP | Should -Be $Credentials.Group
                $env:NETSTORAGE_HOST | Should -Be $Credentials.Host
                $env:NETSTORAGE_ID | Should -Be $Credentials.ID
                $env:NETSTORAGE_KEY | Should -Be $Credentials.Key
                $env:NETSTORAGE_CPCODE | Should -Be $Credentials.CPCode
            }
            It 'loads credentials from default section to custom prefix' {
                $TestParams = @{
                    'NSRCFile'          = $ImportNSRCFile
                    'EnvironmentPrefix' = 'pester'
                }
                Import-NetstorageCredentials @TestParams
                $env:NETSTORAGE_PESTER_CPCODE | Should -Be $Credentials.CPCode
                $env:NETSTORAGE_PESTER_GROUP | Should -Be $Credentials.Group
                $env:NETSTORAGE_PESTER_HOST | Should -Be $Credentials.Host
                $env:NETSTORAGE_PESTER_ID | Should -Be $Credentials.ID
                $env:NETSTORAGE_PESTER_KEY | Should -Be $Credentials.Key
            }
            It 'loads credentials from custom section to standard prefix' {
                $TestParams = @{
                    'NSRCFile' = $ImportNSRCFile
                    'Section'  = 'two'
                }
                Import-NetstorageCredentials @TestParams
                $env:NETSTORAGE_CPCODE | Should -Be $Credentials2.CPCode
                $env:NETSTORAGE_GROUP | Should -Be $Credentials2.Group
                $env:NETSTORAGE_HOST | Should -Be $Credentials2.Host
                $env:NETSTORAGE_ID | Should -Be $Credentials2.ID
                $env:NETSTORAGE_KEY | Should -Be $Credentials2.Key
            }
            It 'loads credentials from custom section to custom prefix' {
                $TestParams = @{
                    'NSRCFile'          = $ImportNSRCFile
                    'Section'           = 'two'
                    'EnvironmentPrefix' = 'pester'
                }
                Import-NetstorageCredentials @TestParams
                $env:NETSTORAGE_PESTER_CPCODE | Should -Be $Credentials2.CPCode
                $env:NETSTORAGE_PESTER_GROUP | Should -Be $Credentials2.Group
                $env:NETSTORAGE_PESTER_HOST | Should -Be $Credentials2.Host
                $env:NETSTORAGE_PESTER_ID | Should -Be $Credentials2.ID
                $env:NETSTORAGE_PESTER_KEY | Should -Be $Credentials2.Key
            }

            AfterEach {
                $env:NETSTORAGE_CPCODE = $null
                $env:NETSTORAGE_GROUP = $null
                $env:NETSTORAGE_KEY = $null
                $env:NETSTORAGE_ID = $null
                $env:NETSTORAGE_HOST = $null
                $env:NETSTORAGE_CUSTOM_CPCODE = $null
                $env:NETSTORAGE_CUSTOM_GROUP = $null
                $env:NETSTORAGE_CUSTOM_KEY = $null
                $env:NETSTORAGE_CUSTOM_ID = $null
                $env:NETSTORAGE_CUSTOM_HOST = $null
            }
        }

        Context 'Clear-NetstorageCredentials' -Tag 'Clear-NetstorageCredentials' {
            BeforeAll {
                $Credentials = [PSCustomObject] @{
                    'Key'    = 'C113nt53KR3TN6N90yVuAgICxIRwsObLi0E67/N8eRN='
                    'ID'     = 'netstorage-id'
                    'Group'  = 'netstorage-group'
                    'Host'   = 'netstorage-host'
                    'cpcode' = 123456
                }
            }
            It 'clears default credentials' {
                $Credentials | Import-NetstorageCredentials
                Clear-NetstorageCredentials
                $env:NETSTORAGE_CPCODE | Should -BeNullOrEmpty
                $env:NETSTORAGE_GROUP | Should -BeNullOrEmpty
                $env:NETSTORAGE_HOST | Should -BeNullOrEmpty
                $env:NETSTORAGE_ID | Should -BeNullOrEmpty
                $env:NETSTORAGE_KEY | Should -BeNullOrEmpty
            }
            It 'clears custom section credentials' {
                $Credentials | Import-NetstorageCredentials -EnvironmentPrefix 'pester'
                Clear-NetstorageCredentials
                $env:NETSTORAGE_PESTER_CPCODE | Should -BeNullOrEmpty
                $env:NETSTORAGE_PESTER_GROUP | Should -BeNullOrEmpty
                $env:NETSTORAGE_PESTER_HOST | Should -BeNullOrEmpty
                $env:NETSTORAGE_PESTER_ID | Should -BeNullOrEmpty
                $env:NETSTORAGE_PESTER_KEY | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Test-EdgegridCredentials' -Tag 'Test-EdgegridCredentials' {
        BeforeAll {
            $BadCredentials = [PSCustomObject] @{
                'Host'         = 'akab-invalid.luna.akamaiapis.net'
                'ClientToken'  = 'invalid'
                'AccessToken'  = 'invalid'
                'ClientSecret' = 'invalid'
            }
            $GoodCredentials = Get-EdgegridCredentials @CommonParams
        }
        It 'reports on bad credentials' {
            $CredentialErrors = $BadCredentials | Test-EdgegridCredentials
            $CredentialErrors | Should -Not -BeNullOrEmpty
            $CredentialErrors | Should -Contain "The 'Host' attribute of your credentials appears to be invalid"
            $CredentialErrors | Should -Contain "The 'ClientToken' attribute of your credentials appears to be invalid"
            $CredentialErrors | Should -Contain "The 'AccessToken' attribute of your credentials appears to be invalid"
            $CredentialErrors | Should -Contain "The 'ClientSecret' attribute of your credentials appears to be invalid"
        }
        It 'reports nothing for good credentials' {
            $CredentialErrors = $GoodCredentials | Test-EdgegridCredentials
            $CredentialErrors | Should -BeNullOrEmpty
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
                $env:AkamaiOptionsPath | Should -Exist
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
                Import-Module $PSScriptRoot/../dist/Akamai.Property/Akamai.Property.psd1 -Force -Function Get-PropertyContract
            }
            It 'should update correctly' {
                $TestParams = @{
                    'EnableErrorRetries'         = $true
                    'InitialErrorWait'           = 2
                    'MaxErrorRetries'            = 10
                    'EnableRateLimitRetries'     = $true
                    'DisablePAPIPrefixes'        = $true
                    'EnableRateLimitWarnings'    = $true
                    'RateLimitWarningPercentage' = 12
                    'EnableDataCache'            = $true
                    'EnableRecommendedActions'   = $true
                }

                # Check defaults
                Get-AkamaiOptions
                $Global:AkamaiOptions.EnableErrorRetries | Should -Be $False
                $Global:AkamaiOptions.InitialErrorWait | Should -Be 1
                $Global:AkamaiOptions.MaxErrorRetries | Should -Be 5
                $Global:AkamaiOptions.EnableRateLimitRetries | Should -Be $False
                $Global:AkamaiOptions.DisablePapiPrefixes | Should -Be $False
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -Be $False
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 90
                $Global:AkamaiOptions.EnableDataCache | Should -Be $False
                $Global:AkamaiOptions.EnableRecommendedActions | Should -Be $False

                # Update
                Set-AkamaiOptions @TestParams | Out-Null

                # Check new values
                $Global:AkamaiOptions.EnableErrorRetries | Should -Be $true
                $Global:AkamaiOptions.InitialErrorWait | Should -Be 2
                $Global:AkamaiOptions.MaxErrorRetries | Should -Be 10
                $Global:AkamaiOptions.EnableRateLimitRetries | Should -Be $true
                $Global:AkamaiOptions.DisablePapiPrefixes | Should -Be $true
                $Global:AkamaiOptions.EnableRateLimitWarnings | Should -Be $true
                $Global:AkamaiOptions.RateLimitWarningPercentage | Should -Be 12
                $Global:AkamaiOptions.EnableDataCache | Should -Be $true
                $Global:AkamaiOptions.EnableRecommendedActions | Should -Be $true
            }
            It 'should create the data cache' {
                $TestParams = @{
                    'EnableDataCache' = $true
                }
                $SetOptions = Set-AkamaiOptions @TestParams
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
                Remove-Module Akamai.Property
            }
        }
        Context 'check options persist' {
            BeforeAll {
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
            }

            It 'should keep options beyond module re-import' {
                $OptionsParams = @{
                    'RateLimitWarningPercentage' = 12
                    'InitialErrorWait'           = 5
                    'MaxErrorRetries'            = 6
                }
                Set-AkamaiOptions @OptionsParams
                Import-Module $PSScriptRoot/../dist/Akamai.Common/Akamai.Common.psd1 -Force
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
                # Import additional modules
                Import-Module $PSScriptRoot/../dist/Akamai.APIDefinitions/Akamai.APIDefinitions.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.AppSec/Akamai.AppSec.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.ClientLists/Akamai.ClientLists.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.EdgeWorkers/Akamai.EdgeWorkers.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.METS/Akamai.METS.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.MOKS/Akamai.MOKS.psd1 -Force
                Import-Module $PSScriptRoot/../dist/Akamai.Property/Akamai.Property.psd1 -Force

                $Modules = Get-Module
                # Pull assets before enabling data cache
                $AppSecConfigs = Get-AppSecConfiguration @CommonParams
                $ClientLists = Get-ClientList @CommonParams
                $EdgeWorkers = Get-EdgeWorker @CommonParams
                $METSCASets = Get-METSCASet @CommonParams
                $MOKSClientCerts = Get-MOKSClientCert @CommonParams
                $TestParams = @{
                    'ContractID' = $TestContractID
                    'GroupID'    = $TestGroupID
                }
                $Includes = Get-PropertyInclude @TestParams @CommonParams
                $TestParams = @{
                    'ContractID' = $TestContractID
                    'GroupID'    = $TestGroupID
                }
                $Properties = Get-Property @TestParams @CommonParams
                $TestParams = @{
                    'PageSize' = 10
                }
                $APIEndpoints = Get-APIEndpoints @TestParams @CommonParams

                Clear-AkamaiDataCache
                $PreviousOptionsPath = $env:AkamaiOptionsPath
                $env:AkamaiOptionsPath = [System.Io.Path]::GetTempFileName()
                Set-AkamaiOptions -EnableDataCache $true
            }

            It 'populates the cache from Get- commands' {
                $TestParams = @{
                    'ContractID' = $TestContractID
                    'GroupID'    = $TestGroupID
                }
                $Properties = Get-Property @TestParams @CommonParams
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

                Remove-Module Akamai.APIDefinitions
                Remove-Module Akamai.AppSec
                Remove-Module Akamai.ClientLists
                Remove-Module Akamai.EdgeWorkers
                Remove-Module Akamai.METS
                Remove-Module Akamai.MOKS
                Remove-Module Akamai.Property
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

    Context 'Aliases' -Tag 'Aliases' {
        It 'has an alias for Invoke-AkamaiRequest' {
            $TestParams = @{
                'Definition' = 'Invoke-AkamaiRequest'
            }
            $Alias = Get-Alias @TestParams
            $Alias.name | Should -Be 'iar'
        }

        It 'has an alias for Invoke-AkamaiRestMethod' {
            $TestParams = @{
                'Definition' = 'Invoke-AkamaiRestMethod'
            }
            $Alias = Get-Alias @TestParams
            $Alias.name | Should -Be 'iarm'
        }
    }
}
