BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.APIDefinitions Tests' {

    BeforeAll {
        function ConvertTo-Base64 {
            [CmdletBinding()]
            Param(
                [Parameter(Mandatory)]
                [string]
                $UnencodedString
            )

            Write-Debug "Encoding '$UnencodedString'"
            try {
                $DecodedString = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($UnencodedString))
                return $DecodedString
            }
            catch {
                Write-Debug "Error encoding '$UnencodedString'"
                Write-Debug $_
                return $UnencodedString
            }
        }

        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.APIDefinitions'
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
        $TestEndpointName = "pester-$Timestamp"
        $TestEndpointName = "pester-$Timestamp"
        $TestEndpointNameClone1 = $TestEndpointName + '-clone1'
        $TestEndpointNameClone2 = $TestEndpointName + '-clone2'
        $TestFileEndpointName = $TestEndpointName + '-fromfile'
        $TestFileEndpointName2 = $TestEndpointName + '-fromfile2'
        $TestHostname = $env:PesterHostname
        $TestAPIDefinitionJSON = @"
{
    "apiEndPointName": "$TestEndpointName",
    "apiEndPointHosts": [
        "$TestHostname"
    ],
    "groupId": $TestGroupId,
    "contractId": "$TestContractID"
}
"@
        $TestAPIDefinition = $TestAPIDefinitionJSON | ConvertFrom-Json
        # Update name to avoid clash
        $TestAPIDefinition.apiEndpointName = $TestAPIDefinition.apiEndpointName + "2"
        # Clone
        $TestAPICloneJSON = @"
{
    "apiEndPointName": "$TestEndpointName",
    "apiEndPointHosts": [
        "$TestHostname"
    ],
    "groupId": $TestGroupId,
    "contractId": "$TestContractID",
    "basePath": "/api",
    "apiEndPointId": 0,
    "versionNumber": 1
}
"@
        $TestAPIDefinitionClone1 = $TestAPICloneJSON | ConvertFrom-Json
        $TestAPIDefinitionClone1.apiEndpointName = $TestEndpointNameClone1
        $TestAPIDefinitionClone2 = $TestAPICloneJSON | ConvertFrom-Json
        $TestAPIDefinitionClone2.apiEndpointName = $TestEndpointNameClone2
        $TestAPICategoryName = "pester-$Timestamp"
        $TestAPIResourceName1 = "resource1-$Timestamp"
        $TestAPIResourceName2 = "resource2-$Timestamp"
        $TestAPIResource1 = @"
{
    "apiResourceName": "$TestAPIResourceName1",
    "resourcePath": "/path1-$Timestamp",
    "apiResourceMethods": [
        {
            "apiResourceMethod": "POST",
            "apiParameters": [
                {
                    "apiParameterName": "username",
                    "apiParameterRequired": true,
                    "apiParameterType": "string",
                    "apiParameterLocation": "body"
                }
            ]
        }
    ]
}
"@
        $TestAPIResource2 = ConvertFrom-Json -InputObject $TestAPIResource1
        $TestAPIResource2.apiResourceName = $TestAPIResourceName2
        $TestAPIResource2.resourcePath = "/path2-$Timestamp"
        $TestAPIResourceOperationJSON = '{
            "apiResourceId": 0,
            "method": "POST",
            "operationName": "Test Operation",
            "operationPurpose": "login",
            "successConditions": [
                {
                    "positiveMatch": true,
                    "type": "http_status",
                    "values": [
                        "200"
                    ]
                }
            ],
            "operationParameter": {
                "username": {
                    "parameterId": 12345
                }
            }
        }'
        $TestAPIResourceOperation = ConvertFrom-Json -InputObject $TestAPIResourceOperationJSON
        $TestAPIRoutingJSON = '{
            "rules": [
              {
                "name": "Override",
                "forwardPath": "DEFAULT_PATH",
                "origin": "origin.pester.net",
                "conditions": [
                  {
                    "type": "METHOD",
                    "operator": "IS",
                    "value": "GET"
                  }
                ]
              }
            ],
            "sureRoute": []
        }'
        $TestAPIRouting = ConvertFrom-Json -InputObject $TestAPIRoutingJSON
        $TestAPIQuery = @"
{
    "queryType": "ACTIVE_IN_PRODUCTION",
    "includeDetails": true,
    "apiEndPointHosts" : [ "$TestHostname" ]
}
"@
        $TestAPIResponseType = '{
            "body": "{\"title\":\"The API key you provided does not exist.\" }",
            "headers": [
                {
                    "name": "Content-Type",
                    "value": "application/problem+json"
                }
            ],
            "statusCode": 401
        }'
        $TestSwaggerContent = @"
openapi: 3.0.0
info:
  title: $TestFileEndpointName
  description: Optional multiline or single-line description in [CommonMark](http://commonmark.org/help/) or HTML.
  version: 0.1.9

servers:
  - url: http://$TestHostname/v1
    description: Optional server description, e.g. Main (production) server

paths:
  /users:
    get:
      summary: Returns a list of users.
      description: Optional extended description in CommonMark or HTML.
      responses:
        '200':
          description: A JSON array of user names
          content:
            application/json:
              schema:
                type: array
                items:
                  type: string
"@.Replace("`r`n", "`n")
        $TestEncodedSwaggerContent = ConvertTo-Base64 -UnencodedString $TestSwaggerContent
        $TestAPIFromFileJSON = @"
{
    "importFileFormat": "swagger",
    "importFileSource": "BODY_BASE64",
    "importFileContent": "$TestEncodedSwaggerContent",
    "groupId": $TestGroupID,
    "contractId": "$TestContractID"
}
"@
        $TestAPIFromFile = ConvertFrom-Json -InputObject $TestAPIFromFileJSON
        $TestAPIActivationJSON = '{
            "networks": [
                "STAGING"
            ],
            "notes": "D - E - C - C(low) - G",
            "notificationRecipients": [
                "mail@example.com"
            ]
        }'
        $TestAPIActivation = ConvertFrom-Json -InputObject $TestAPIActivationJSON
        $TestAPISecureJSON = '{
            "certChain": {
                "content": "-----BEGIN CERTIFICATE-----\nMIIFsDCCA5igAwIBAgIJAL7HIonYis0aMA0GCSqGSIb3DQEBCwUAMG0xCzAJBgNV\nBAYTAlVTMREwDwYDVQQIDAhyYXBpZHppazERMA8GA1UEBwwIcmFwaWR6aWsxETAP\nBgNVBAoMCHJhcGlkemlrMREwDwYDVQQLDAhyYXBpZHppazESMBAGA1UEAwwJbG9j\nYWxob3N0MB4XDTE5MDYxMTE0MzI0NloXDTI0MDYwOTE0MzI0NlowbTELMAkGA1UE\nBhMCVVMxETAPBgNVBAgMCHJhcGlkemlrMREwDwYDVQQHDAhyYXBpZHppazERMA8G\nA1UECgwIcmFwaWR6aWsxETAPBgNVBAsMCHJhcGlkemlrMRIwEAYDVQQDDAlsb2Nh\nbGhvc3QwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCua7kn9yrkpMMH\nT18yzPFK9LBPk4GzMX0BZfEi2jzKKoc00BtoU/zeS9ewj+2IdIoHa19GE7qnnMux\nkbwm6GNkFt4rzJsQ5ruMSKEqzd4I81HDmS5s2X3o4ZqYWVHAx/rqsh5EIt5qAjq4\njebXeMuhlnkx6jMs+4+ZFfATVvOJ78VnUGUheNTcTGgCvxU7ZZ3+IZubJ6BVdJjC\nwxM30eroVF3efX4HrRXhLtatQtxjX6g2qOUfFiuNNLcgx+4NPqbKpecqyUbopt18\n72MmohKy+YfVEk7OFWLyNPoL237KCznkCGwcQYrXTJzDVAN4NqQEo513nIHEC89F\nX/WomZWwLKVyQpiA1z/jUdYnSzsrPSuA+oP1WmfwVjtxeiwB7Asy/d/5OmOtID+a\nzT41irl1Dp5F6mgAI8CZ1LnzYIlvJAQS9+cpLG9rsyYDRr5+78TebiqP02CrRj9S\nstoam6WG21Z9fJ/aPKJ0ZQHkpXuHDy6RHJro+2wk0coWOyNT0UH6/7kuKHjEGaAG\nBXjElxZ8pJySwYXeeD5gmimQKPE/us1BD2jk0KWYxnwJ+jM4S7RipgTSGsy3Nw42\nvKnKw6FwOIoQqwTkiNF+p7EsjeciO09zLecXxlh3p8WREEZU5NICmGL7xItdD+7I\nVr/tn3XNbuSUu0IqdbhO19JoNXG/UwIDAQABo1MwUTAdBgNVHQ4EFgQUcXwqRZUC\nj9+VsyCfy4oIMN9u1V0wHwYDVR0jBBgwFoAUcXwqRZUCj9+VsyCfy4oIMN9u1V0w\nDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAgEAQgWlrEW+K3fCMO9K\n2TuxY6ruXbdekRv+nw+weXe9+GLlyvEFxktYTE/cN8pHrKOG6F/ea+CCHW4xenVp\npchFI8zPQ8kDEDUUrPaQLbw9kzXKLZwUs+KMZXEZJInxWrr1mWeP+lVSf6f4hwNd\nfvJ8SOPe3/IAE0C79JaclzYE3ErfTlBeouQ09jXbeHc0VvodFp7XcmIMA9e5zIzu\nCU1QOa1LRrn5+TI41BbjKypMl8EE7ZEoyWRj4sMQGfuh9/kmu9ZPINJ79/j22vZG\nVj72jKoIu01qI0esfL7GcE9gd9eWhDRuBYNCAfXWK7xvMwYIxeLgP9LJoeBCVMV+\n7k1AHGpgU4UYveu71VCUIlGIaL1t/DKHi8SqDaKV2eImurPp90eLWAU1V6b+UG5/\n+HoUI8Kd5KgfPprv4AKKOTse04xbFDehvgCpQpcwzoV0h2AQtHhsN65dXfO3XPnR\nYQka7OQcEJS/gLXl7FIcpfkNyvi8ompHVSGTnAEB4qAwazz3FWe6r7qbqty2n0Ye\nNTkylMbBMFpMZrP4BP6YFf3BnkzjFcffHvtVGGUbyebQazc+5HyZycabEhekETeS\nLUOCwFWH68wXI23eU5Z7mKAI+rwhqVuJZPzZFUWfNhj7Pt/aby+7SIZAQ9YCR2lk\n6IUdRIpisR9k478g/4pQYly6yN4=\n-----END CERTIFICATE-----",
                "name": "bookstore_cert.pem"
            },
            "hosts": [
                "bookstore.api.akamai.com"
            ]
        }'

        $TestMultistepGroupName = "multistep-group-1"
        $TestMultistepGroupName2 = "multistep-group-2"
        $TestMultistepGroupName3 = "multistep-group-3"

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.APIDefinitions"

        $PD = @{}

    }

    AfterAll {
        $TestEndpointName, "$TestEndpointName`2", $TestEndpointNameClone1, $TestEndpointNameClone2, $TestFileEndpointName | foreach-object {
            Try {
                Show-APIEndpoint -APIEndpointName $_ @CommonParams
            }
            Catch {}

            try {
                Remove-APIEndpoint -APIEndpointName $_ @CommonParams
            }
            catch {}
        }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    #------------------------------------------------
    #                 APIContractsAndGroups
    #------------------------------------------------

    Context 'Get-APIContractsAndGroups' {
        It 'returns the correct data' {
            $PD.GetAPIContractsAndGroups = Get-APIContractsAndGroups @CommonParams
            $PD.GetAPIContractsAndGroups[0].groupId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpoint
    #------------------------------------------------

    Context 'New-APIEndpoint by parameter' {
        It 'completes successfully by body' {
            $TestParams = @{
                'Body' = $TestAPIDefinitionJSON
            }
            $PD.NewEndpointParam = New-APIEndpoint @TestParams @CommonParams
            $PD.NewEndpointParam.apiEndPointName | Should -Be $TestEndpointName
            # Update templates
            $TestAPIDefinitionClone1.apiEndpointId = $PD.NewEndpointParam.apiEndpointId
            $TestAPIDefinitionClone2.apiEndpointId = $PD.NewEndpointParam.apiEndpointId
        }
        It 'completes successfully by pipeline' {
            $PD.NewEndpointPipeline = $TestAPIDefinition | New-APIEndpoint @CommonParams
            $PD.NewEndpointPipeline.apiEndPointName | Should -Be "$TestEndpointName`2"
        }
    }

    Context 'Get-APIEndpoint' {
        It 'returns a list' {
            $PD.Endpoints = Get-APIEndpoint @CommonParams
            $PD.Endpoints[0].apiEndPointId | Should -Not -BeNullOrEmpty
        }
        It 'returns a list with the old alias' {
            $PD.EndpointsAlias = Get-APIEndpoints @CommonParams
            $PD.EndpointsAlias[0].apiEndPointId | Should -Not -BeNullOrEmpty
        }
        It 'returns a single endpoint by name' {
            $TestParams = @{
                'APIEndpointName' = $TestEndpointName
            }
            $PD.Endpoint = Get-APIEndpoint @TestParams @CommonParams
            $PD.Endpoint.apiEndpointName | Should -Be $TestEndpointName
            $PD.Endpoint.apiEndpointId | Should -Not -BeNullOrEmpty
        }
        It 'returns a single endpoint by ID' {
            $PD.EndpointByID = $PD.Endpoint.apiEndpointId | Get-APIEndpoint @CommonParams
            $PD.EndpointByID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Copy-APIEndpoint' {
        It 'completes successfully by body' {
            $TestParams = @{
                'Body' = $TestAPIDefinitionClone1
            }
            $PD.CopyEndpointParam = Copy-APIEndpoint @TestParams @CommonParams
            $PD.CopyEndpointParam.apiEndpointName | Should -Be $TestEndpointNameClone1
        }
        It 'completes successfully by pipeline' {
            $PD.CopyEndpointPipeline = $TestAPIDefinitionClone2 | Copy-APIEndpoint @CommonParams
            $PD.CopyEndpointPipeline.apiEndpointName | Should -Be $TestEndpointNameClone2
        }
    }

    Context 'Hide-APIEndpoint' {
        It 'completes successfully by pipeline (id)' {
            $PD.HideAPIEndpointId = $PD.NewEndpointParam | Hide-APIEndpoint @CommonParams
            $PD.HideAPIEndpointId.apiEndpointId | Should -Be $PD.NewEndpointParam.apiEndpointId
        }
        It 'completes successfully by name' {
            $TestParams = @{
                'APIEndpointName' = $PD.NewEndpointPipeline.apiEndpointName
            }
            $PD.HideAPIEndpointName = Hide-APIEndpoint @TestParams @CommonParams
            $PD.HideAPIEndpointName.apiEndpointId | Should -Be $PD.NewEndpointPipeline.apiEndpointId
        }
    }

    Context 'Show-APIEndpoint' {
        It 'completes successfully by pipeline (id)' {
            $PD.ShowAPIEndpointId = $PD.NewEndpointParam | Show-APIEndpoint @CommonParams
            $PD.ShowAPIEndpointId.apiEndpointId | Should -Be $PD.NewEndpointParam.apiEndpointId
        }
        It 'completes successfully by name' {
            $TestParams = @{
                'APIEndpointName' = $PD.NewEndpointPipeline.apiEndpointName
            }
            $PD.ShowAPIEndpointName = Show-APIEndpoint @TestParams @CommonParams
            $PD.ShowAPIEndpointName.apiEndpointId | Should -Be $PD.NewEndpointPipeline.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APIEndpointDetails
    #------------------------------------------------

    Context 'Expand-APIEndpointDetails' {
        BeforeAll {
            . $PSScriptRoot/../src/Akamai.APIDefinitions/Functions/Private/Expand-APIEndpointDetails.ps1

            $PreviousOptionsPath = $env:AkamaiOptionsPath
            $env:AkamaiOptionsPath = "TestDrive:/options.json"
            # Creat options
            New-AkamaiOptions
            # Enable data cache
            Set-AkamaiOptions -EnableDataCache $true | Out-Null
            Clear-AkamaiDataCache
        }
        It 'returns the correct data' {
            $Name = $PD.NewEndpointParam.apiEndpointName
            $TestParams = @{
                'APIEndpointName' = $Name
                'VersionNumber'   = 'latest'
            }
            $ExpandAPIEndpointDetailsID, $ExpandAPIEndpointDetailsVersion = Expand-APIEndpointDetails @TestParams @CommonParams
            $ExpandAPIEndpointDetailsID | Should -Be $PD.NewEndpointParam.apiEndpointId
            $ExpandAPIEndpointDetailsVersion | Should -Be $PD.NewEndpointParam.versionNumber
            $AkamaiDataCache.APIDefinitions.APIEndpoints.$Name.APIEndpointID | Should -Be $ExpandAPIEndpointDetailsID
        }
        AfterAll {
            Remove-Item -Path $env:AkamaiOptionsPath -Force
            $env:AkamaiOptionsPath = $PreviousOptionsPath
            Clear-AkamaiDataCache

            Remove-Item -Path Function:/Expand-APIEndpointDetails -Force
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersion
    #------------------------------------------------

    Context 'Get-APIEndpointVersion' {
        It 'returns all versions' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
            }
            $PD.EndpointVersions = Get-APIEndpointVersion @TestParams @CommonParams
            $PD.EndpointVersions[0].versionNumber | Should -Match '[\d]'
        }
        It 'returns a specific version by number' {
            $TestParams = @{
                'APIEndpointName' = $PD.NewEndpointParam.apiEndpointName
                'VersionNumber'   = 1
            }
            $PD.EndpointVersion = Get-APIEndpointVersion @TestParams @CommonParams
            $PD.EndpointVersion.apiEndPointId | Should -Be $PD.NewEndpointParam.apiEndPointId
            $PD.EndpointVersion.apiEndPointName | Should -Be $PD.NewEndpointParam.apiEndpointName
            $PD.EndpointVersion.versionNumber | Should -Be 1
        }
    }

    Context 'New-APIEndpointVersion' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointVersion = $PD.EndpointVersion | New-APIEndpointVersion @CommonParams
            $PD.NewAPIEndpointVersion.apiEndpointId | Should -Be $PD.NewEndpointParam.apiEndpointId
        }
    }

    Context 'Set-APIEndpointVersion' {
        It 'updates correctly' {
            $PD.SetAPIEndpointVersionByPipeline = $PD.EndpointVersion | Set-APIEndpointVersion @CommonParams
            $PD.SetAPIEndpointVersionByPipeline.apiEndpointId | Should -Be $PD.EndpointVersion.apiEndpointId
        }
    }

    Context 'Hide-APIEndpointVersion' {
        It 'updates successfully' {
            $PD.HideAPIEndpointVersionId = $PD.EndpointVersion | Hide-APIEndpointVersion @CommonParams
            $PD.HideAPIEndpointVersionId.apiEndpointId | Should -Be $PD.NewEndpointParam.apiEndpointId
        }
    }

    Context 'Show-APIEndpointVersion' {
        It 'updates successfully' {
            $PD.ShowAPIEndpointVersionId = $PD.EndpointVersion | Show-APIEndpointVersion @CommonParams
            $PD.ShowAPIEndpointVersionId.apiEndpointId | Should -Be $PD.NewEndpointParam.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionCache
    #------------------------------------------------

    Context 'Get-APIEndpointVersionCache' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionCache = $PD.EndpointVersion | Get-APIEndpointVersionCache @CommonParams
            $PD.GetAPIEndpointVersionCache.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCache' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.GetAPIEndpointVersionCache
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionCacheByParam = Set-APIEndpointVersionCache @TestParams @CommonParams
            $PD.SetAPIEndpointVersionCacheByParam.enabled | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionCacheByPipeline = $PD.GetAPIEndpointVersionCache | Set-APIEndpointVersionCache @TestParams @CommonParams
            $PD.SetAPIEndpointVersionCacheByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionCORS
    #------------------------------------------------

    Context 'Get-APIEndpointVersionCORS' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionCORS = $PD.EndpointVersion | Get-APIEndpointVersionCORS @CommonParams
            $PD.GetAPIEndpointVersionCORS.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCORS' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.GetAPIEndpointVersionCORS
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionCORSByParam = Set-APIEndpointVersionCORS @TestParams @CommonParams
            $PD.SetAPIEndpointVersionCORSByParam.enabled | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionCORSByPipeline = $PD.GetAPIEndpointVersionCORS | Set-APIEndpointVersionCORS @TestParams @CommonParams
            $PD.SetAPIEndpointVersionCORSByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }


    #------------------------------------------------
    #          APIEndpointVersionErrorResponses
    #------------------------------------------------

    Context 'Get-APIEndpointVersionErrorResponses' {
        It 'returns the correct data' {
            $PD.ErrorResponses = $PD.EndpointVersion | Get-APIEndpointVersionErrorResponses @CommonParams
            $PD.ErrorResponses.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionErrorResponses' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.ErrorResponses
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionErrorResponsesByParam = Set-APIEndpointVersionErrorResponses @TestParams @CommonParams
            $PD.SetAPIEndpointVersionErrorResponsesByParam.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetAPIEndpointVersionErrorResponsesByPipeline = $PD.ErrorResponses | Set-APIEndpointVersionErrorResponses @TestParams @CommonParams
            $PD.SetAPIEndpointVersionErrorResponsesByPipeline.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #        APIEndpointVersionErrorResponseType
    #------------------------------------------------

    Context 'Set-APIEndpointVersionErrorResponseType' {
        It 'updates successfully' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $TestAPIResponseType
                'Type'          = "API_KEY_INVALID"
                'VersionNumber' = 1
            }
            $PD.SetErrorResponseType = Set-APIEndpointVersionErrorResponseType @TestParams @CommonParams
            $PD.SetErrorResponseType.statusCode | Should -Not -BeNullOrEmpty
            $PD.SetErrorResponseType.body | Should -Not -BeNullOrEmpty
            $PD.SetErrorResponseType.headers | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionErrorResponseType' {
        It 'returns the correct data' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
                'Type'          = "API_KEY_INVALID"
            }
            $PD.GetErrorResponseType = Get-APIEndpointVersionErrorResponseType @TestParams @CommonParams
            $PD.GetErrorResponseType.statusCode | Should -Not -BeNullOrEmpty
            $PD.GetErrorResponseType.body | Should -Not -BeNullOrEmpty
            $PD.GetErrorResponseType.headers | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #           APIEndpointVersionGraphQL
    #------------------------------------------------

    Context 'Get-APIEndpointVersionGraphQL' {
        It 'returns the correct data' {
            $PD.GraphQL = $PD.EndpointVersion | Get-APIEndpointVersionGraphQL @CommonParams
            $PD.GraphQL.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGraphQL' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.GraphQL
                'VersionNumber' = 1
            }
            $PD.SetGraphQLByParam = Set-APIEndpointVersionGraphQL @TestParams @CommonParams
            $PD.SetGraphQLByParam.enabled | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetGraphQLByPipeline = $PD.GraphQL | Set-APIEndpointVersionGraphQL @TestParams @CommonParams
            $PD.SetGraphQLByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #            APIEndpointVersionGZip
    #------------------------------------------------

    Context 'Get-APIEndpointVersionGZip' {
        It 'returns the correct data' {
            $PD.GZip = $PD.EndpointVersion | Get-APIEndpointVersionGZip @CommonParams
            $PD.GZip.compressResponse | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGZip' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.GZip
                'VersionNumber' = 1
            }
            $PD.SetGZipParam = Set-APIEndpointVersionGZip @TestParams @CommonParams
            $PD.SetGZipParam.compressResponse | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetGZipPipeline = $PD.GZip | Set-APIEndpointVersionGZip @TestParams @CommonParams
            $PD.SetGZipPipeline.compressResponse | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #            APIEndpointVersionJWT
    #------------------------------------------------

    Context 'Get-APIEndpointVersionJWT' {
        It 'returns the correct data' {
            $PD.JWT = $PD.EndpointVersion | Get-APIEndpointVersionJWT @CommonParams
            $PD.JWT.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionJWT' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.JWT
                'VersionNumber' = 1
            }
            $PD.SetJWTIdParam = Set-APIEndpointVersionJWT @TestParams @CommonParams
            $PD.SetJWTIdParam.enabled | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetJWTIdPipeline = $PD.JWT | Set-APIEndpointVersionJWT @TestParams @CommonParams
            $PD.SetJWTIdPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #           APIEndpointVersionPrivacy
    #------------------------------------------------

    Context 'Get-APIEndpointVersionPrivacy' {
        It 'returns the correct data' {
            $PD.Privacy = $PD.EndpointVersion | Get-APIEndpointVersionPrivacy @CommonParams
            $PD.Privacy.public | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionPrivacy' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $PD.Privacy
                'VersionNumber' = 1
            }
            $PD.SetPrivacyParam = Set-APIEndpointVersionPrivacy @TestParams @CommonParams
            $PD.SetPrivacyParam.public | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetPrivacyPipeline = $PD.Privacy | Set-APIEndpointVersionPrivacy @TestParams @CommonParams
            $PD.SetPrivacyPipeline.public | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #           APIEndpointVersionResource
    #------------------------------------------------

    Context 'New-APIEndpointVersionResource' {
        It 'creates a resource by parameter' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $TestAPIResource1
                'VersionNumber' = 1
            }
            $PD.NewResourceParam = New-APIEndpointVersionResource @TestParams @CommonParams
            $PD.NewResourceParam.apiResourceName | Should -Be $TestAPIResourceName1
            # Set apiResourceId
            $TestAPIResourceOperation.apiResourceId = $PD.NewResourceParam.apiResourceId
            $TestAPIResourceOperation.operationParameter.username.parameterId = $PD.NewResourceParam.apiResourceMethods[0].apiParameters[0].apiParameterId
        }
        It 'creates a resource by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.NewResourcePipeline = $TestAPIResource2 | New-APIEndpointVersionResource @TestParams @CommonParams
            $PD.NewResourcePipeline.apiResourceName | Should -Be $TestAPIResourceName2
        }
    }

    Context 'Get-APIEndpointVersionResource' {
        It 'returns a list' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.Resources = Get-APIEndpointVersionResource @TestParams @CommonParams
            $PD.Resources[0].apiResourceName | Should -Not -BeNullOrEmpty
        }
        It 'returns a single resource' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceParam.apiResourceId
                'VersionNumber' = 1
            }
            $PD.Resource = Get-APIEndpointVersionResource @TestParams @CommonParams
            $PD.Resource.apiResourceId | Should -Be $PD.NewResourceParam.apiResourceId
        }
    }

    Context 'Set-APIEndpointVersionResource' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceParam.apiResourceId
                'Body'          = $PD.NewResourceParam
                'VersionNumber' = 1
            }
            $PD.SetResourceParam = Set-APIEndpointVersionResource @TestParams @CommonParams
            $PD.SetResourceParam.apiResourceId | Should -Be $PD.NewResourceParam.apiResourceId
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceParam.apiResourceId
                'VersionNumber' = 1
            }
            $PD.SetResourcePipeline = $PD.NewResourceParam | Set-APIEndpointVersionResource @TestParams @CommonParams
            $PD.SetResourcePipeline.apiResourceId | Should -Be $PD.NewResourceParam.apiResourceId
        }
    }

    #------------------------------------------------
    #        APIEndpointVersionResourceOperation
    #------------------------------------------------

    Context 'New-APIEndpointVersionResourceOperation' {
        It 'returns the correct data' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceParam.apiResourceId
                'Body'          = $TestAPIResourceOperation
                'VersionNumber' = 1
            }
            $PD.NewResourceOperation = New-APIEndpointVersionResourceOperation @TestParams @CommonParams
            $PD.NewResourceOperation.operationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionResourceOperation' {
        It 'returns a list' {
            $TestParams = @{
                'APIResourceID' = $PD.NewResourceOperation.apiResourceId
            }
            $PD.ResourceOperations = $PD.EndpointVersion | Get-APIEndpointVersionResourceOperation @TestParams @CommonParams
            $PD.ResourceOperations[0].operationId | Should -Be $PD.NewResourceOperation.operationId
        }
        It 'returns a single resource operation' {
            $TestParams = @{
                'APIResourceID' = $PD.NewResourceOperation.apiResourceId
                'OperationID'   = $PD.NewResourceOperation.operationId
            }
            $PD.ResourceOperation = $PD.EndpointVersion | Get-APIEndpointVersionResourceOperation @TestParams @CommonParams
            $PD.ResourceOperation.operationId | Should -Be $PD.NewResourceOperation.operationId
        }
    }

    Context 'Set-APIEndpointVersionResourceOperation' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceOperation.apiResourceId
                'Body'          = $PD.ResourceOperation
                'OperationID'   = $PD.NewResourceOperation.operationId
                'VersionNumber' = 1
            }
            $PD.SetResourceOperationParam = Set-APIEndpointVersionResourceOperation @TestParams @CommonParams
            $PD.SetResourceOperationParam.operationId | Should -Be $PD.NewResourceOperation.operationId
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'APIResourceID' = $PD.NewResourceOperation.apiResourceId
                'OperationID'   = $PD.NewResourceOperation.operationId
                'VersionNumber' = 1
            }
            $PD.SetResourceOperationPipeline = $PD.ResourceOperation | Set-APIEndpointVersionResourceOperation @TestParams @CommonParams
            $PD.SetResourceOperationPipeline.operationId | Should -Be $PD.NewResourceOperation.operationId
        }
    }

    #------------------------------------------------
    #             APIMultistepGroup
    #------------------------------------------------

    Context 'New-APIEndpointMultistepGroup' {
        It 'creates a multistep group by parameter' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
                'Name'          = $TestMultistepGroupName
            }
            $PD.NewMultistepGroupParam = New-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.NewMultistepGroupParam.name | Should -Be $TestMultistepGroupName
            $PD.NewMultistepGroupParam.multistepGroupId | Should -Not -BeNullOrEmpty
        }
        It 'creates a multistep group by pipeline' {
            $TestParams = @{
                'name' = $TestMultistepGroupName2
            }
            $PD.NewMultistepGroupPipeline = $PD.EndpointVersion | New-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.NewMultistepGroupPipeline.name | Should -Be $TestMultistepGroupName2
            $PD.NewMultistepGroupPipeline.multistepGroupId | Should -Not -BeNullOrEmpty
        }
        It 'creates a third group so we can delete by all methods' {
            $TestParams = @{
                'name' = $TestMultistepGroupName3
            }
            $PD.ThirdMultistepGroup = $PD.EndpointVersion | New-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.ThirdMultistepGroup.name | Should -Be $TestMultistepGroupName3
            $PD.ThirdMultistepGroup.multistepGroupId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointMultistepGroup' {
        It 'returns a list by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.MultistepGroups = Get-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.MultistepGroups[0].name | Should -Not -BeNullOrEmpty
        }
        It 'returns a list by pipeline' {
            $MultistepGroups = $PD.EndpointVersion | Get-APIEndpointMultistepGroup @CommonParams
            $MultistepGroups[0].name | Should -Not -BeNullOrEmpty
        }
        It 'returns a single multistep group by param' {
            $TestParams = @{
                'APIEndpointID'    = $PD.NewEndpointParam.apiEndpointId
                'MultistepGroupID' = $PD.NewMultistepGroupParam.multistepGroupId
                'VersionNumber'    = 1
            }
            $PD.MultistepGroup = Get-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.MultistepGroup.multistepGroupId | Should -Be $PD.NewMultistepGroupParam.multistepGroupId
        }
        It 'returns a single multistep group by pipeline' {
            $TestParams = @{
                'MultistepGroupID' = $PD.NewMultistepGroupParam.multistepGroupId
            }
            $MultistepGroup = $PD.EndpointVersion | Get-APIEndpointMultistepGroup @TestParams @CommonParams
            $MultistepGroup.multistepGroupId | Should -Be $PD.NewMultistepGroupParam.multistepGroupId
        }
    }

    Context 'Rename-APIEndpointMultistepGroup' {
        It 'renames successfully by param' {
            $NewName = $PD.MultistepGroup.name + "-1"
            $TestParams = @{
                'APIEndpointID'    = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber'    = 1
                'MultistepGroupID' = $PD.MultistepGroup.multistepGroupId
                'NewName'          = $NewName
            }
            $PD.RenameMultistepGroup = Rename-APIEndpointMultistepGroup @TestParams @CommonParams
            $PD.RenameMultistepGroup.multistepGroupId | Should -Be $PD.MultistepGroup.multistepGroupId
            $PD.RenameMultistepGroup.name | Should -Be $NewName
        }
        It 'renames successfully by piped api version' {
            $NewName = $PD.MultistepGroup.name + "-2"
            $TestParams = @{
                'MultistepGroupID' = $PD.MultistepGroup.multistepGroupId
                'NewName'          = $NewName
            }
            $RenameMultistepGroup = $PD.EndpointVersion | Rename-APIEndpointMultistepGroup @TestParams @CommonParams
            $RenameMultistepGroup.multistepGroupId | Should -Be $PD.MultistepGroup.multistepGroupId
            $RenameMultistepGroup.name | Should -Be $NewName
        }
        It 'renames successfully by piped multistep group' {
            $NewName = $PD.MultistepGroup.name + "-3"
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
                'NewName'       = $NewName
            }
            $RenameMultistepGroup = $PD.MultistepGroup | Rename-APIEndpointMultistepGroup @TestParams @CommonParams
            $RenameMultistepGroup.multistepGroupId | Should -Be $PD.MultistepGroup.multistepGroupId
            $RenameMultistepGroup.name | Should -Be $NewName
        }
    }

    #------------------------------------------------
    #     APIEndpointVersionResourcesAndOperations
    #------------------------------------------------

    Context 'Get-APIEndpointVersionResourcesAndOperations' {
        It 'returns the correct data' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.ResourcesAndOperations = Get-APIEndpointVersionResourcesAndOperations @TestParams @CommonParams
            $PD.ResourcesAndOperations.apiEndpoints | Should -Not -BeNullOrEmpty
            $PD.ResourcesAndOperations.operations | Should -Not -BeNullOrEmpty
            $PD.ResourcesAndOperations.resources | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #          APIEndpointVersionRouting
    #------------------------------------------------

    Context 'Set-APIEndpointVersionRouting' {
        It 'updates successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'Body'          = $TestAPIRoutingJSON
                'VersionNumber' = 1
            }
            $PD.SetRoutingParam = Set-APIEndpointVersionRouting @TestParams @CommonParams
            $PD.SetRoutingParam.rules | Should -Not -BeNullOrEmpty
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetRoutingPipeline = $TestAPIRouting | Set-APIEndpointVersionRouting @TestParams @CommonParams
            $PD.SetRoutingPipeline.rules | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionRouting' {
        It 'returns the correct data' {
            $PD.Routing = $PD.EndpointVersion | Get-APIEndpointVersionRouting @CommonParams
            $PD.Routing.rules | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #           APIEndpointVersionSummary
    #------------------------------------------------

    Context 'Get-APIEndpointVersionSummary' {
        It 'returns the correct data by pipeline (id)' {
            $PD.VersionSummaryPipline = $PD.EndpointVersion | Get-APIEndpointVersionSummary @CommonParams
            $PD.VersionSummaryPipline.apiVersionId | Should -Not -BeNullOrEmpty
        }
        It 'returns the correct data by name' {
            $TestParams = @{
                'APIEndpointName' = $PD.NewEndpointParam.apiEndpointName
                'VersionNumber'   = 1
            }
            $PD.VersionSummaryName = Get-APIEndpointVersionSummary @TestParams @CommonParams
            $PD.VersionSummaryName.apiVersionId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIHostnames
    #------------------------------------------------

    Context 'Get-APIHostnames' {
        It 'returns the correct data' {
            $TestParams = @{
                'ContractID' = $TestContractID
                'GroupID'    = $TestGroupID
            }
            $PD.GetAPIHostnames = Get-APIHostnames @TestParams @CommonParams
            $PD.GetAPIHostnames.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 APIHostnamesAndGroups
    #------------------------------------------------

    Context 'Get-APIHostnamesAndGroups' {
        It 'returns the correct data' {
            $TestParams = @{
                'ContractID' = $TestContractID
                'GroupID'    = $TestGroupID
            }
            $PD.GetAPIHostnamesAndGroups = Get-APIHostnamesAndGroups @TestParams @CommonParams
            $PD.GetAPIHostnamesAndGroups[0].acgId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIOperations
    #------------------------------------------------

    Context 'Get-APIOperations' {
        It 'returns the correct data' {
            $PD.GetAPIOperations = Get-APIOperations @CommonParams
            $PD.GetAPIOperations.apiEndPoints | Should -Not -BeNullOrEmpty

            # Create body for later functions
            $PD.TestAPIOperationsBody = @{
                'operations' = @(
                    @{
                        'apiEndPointId'      = $PD.GetAPIOperations.operations[0].apiEndpointId
                        'apiResourceLogicId' = $PD.GetAPIOperations.operations[0].apiResourceLogicId
                        'operationId'        = $PD.GetAPIOperations.operations[0].operationId
                    }
                )
            }
        }
    }

    Context 'Test-APIOperations' {
        It 'completes successfully by param' {
            $TestParams = @{
                'Body' = $PD.TestAPIOperationsBody
            }
            $PD.TestAPIOperationsByParam = Test-APIOperations @TestParams @CommonParams
            $PD.TestAPIOperationsByParam.apiEndPoints | Should -Not -BeNullOrEmpty
        }
        It 'completes successfully by pipeline' {
            $PD.TestAPIOperationsByPipeline = $PD.TestAPIOperationsBody | Test-APIOperations @CommonParams
            $PD.TestAPIOperationsByPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIUserEntitlements
    #------------------------------------------------

    Context 'Get-APIUserEntitlements' {
        It 'returns the correct data' {
            $TestParams = @{
                'ContractID' = $TestContractID
                'GroupID'    = $TestGroupId
            }
            $PD.GetAPIUserEntitlements = Get-APIUserEntitlements @TestParams @CommonParams
            $PD.GetAPIUserEntitlements.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 API Operations
    #------------------------------------------------

    Context 'Find-APIOperation' {
        It 'creates successfully by attributes' {
            $TestParams = @{
                'QueryType'        = 'ACTIVE_IN_PRODUCTION'
                'IncludeDetails'   = $true
                'APIEndPointHosts' = $TestHostname
            }
            $PD.FoundOperationAttr = Find-APIOperation @TestParams @CommonParams
            $PD.FoundOperationAttr.apiEndPoints | Should -Not -BeNullOrEmpty
            $PD.FoundOperationAttr.apiEndPoints.apiEndPointHosts | Should -Contain $TestHostname
            $PD.FoundOperationAttr.operations | Should -Not -BeNullOrEmpty
            $PD.FoundOperationAttr.resources | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by pipeline' {
            $PD.FoundOperationPipeline = $TestAPIQuery | Find-APIOperation @CommonParams
            $PD.FoundOperationPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
            $PD.FoundOperationPipeline.operations | Should -Not -BeNullOrEmpty
            $PD.FoundOperationPipeline.resources | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #            APIEndpointFromFile
    #------------------------------------------------

    Context 'New-APIEndpointFromFile' {
        It 'creates successfully by file content' {
            $TestParams = @{
                'ImportFileFormat'  = 'swagger'
                'ImportFileContent' = $TestEncodedSwaggerContent
                'ContractID'        = $TestContractID
                'GroupID'           = $TestGroupID
            }
            $PD.NewEndpointFile = New-APIEndpointFromFile @TestParams @CommonParams
            $PD.NewEndpointFile.apiEndpointId | Should -Not -BeNullOrEmpty
            $PD.NewEndpointFile.apiEndpointName | Should -Be $TestFileEndpointName
        }
        It 'creates successfully by filename' {
            $APIFile = "TestDrive:/apispec.yaml"
            $TestSwaggerContent -Replace $TestFileEndpointName, $TestFileEndpointName2 | Out-File -FilePath $APIFile -Encoding utf8
            $TestParams = @{
                'ImportFileFormat' = 'swagger'
                'ImportFilename'   = $APIFile
                'ContractID'       = $TestContractID
                'GroupID'          = $TestGroupID
            }
            $PD.NewEndpointFile2 = New-APIEndpointFromFile @TestParams @CommonParams
            $PD.NewEndpointFile2.apiEndpointId | Should -Not -BeNullOrEmpty
            $PD.NewEndpointFile2.apiEndpointName | Should -Be $TestFileEndpointName2
        }
    }

    #------------------------------------------------
    #        APIEndpointVersionFromFile
    #------------------------------------------------

    Context 'Set-APIEndpointVersionFromFile' {
        It 'updates successfully by attributes' {
            $TestParams = @{
                'APIEndpointID'     = $PD.NewEndpointFile.apiEndpointId
                'VersionNumber'     = 1
                'ImportFileFormat'  = 'swagger'
                'ImportFileSource'  = 'BODY_BASE64'
                'ImportFileContent' = $TestEncodedSwaggerContent
                'ContractID'        = $TestContractID
                'GroupID'           = $TestGroupID
            }
            $PD.SetVersionFromFileAttr = Set-APIEndpointVersionFromFile @TestParams @CommonParams
            $PD.SetVersionFromFileAttr.apiEndPointId | Should -Be $PD.NewEndpointFile.apiEndpointId
        }
        It 'updates successfully by pipeline' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointFile.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.SetVersionFromFilePipeline = $TestAPIFromFileJSON | Set-APIEndpointVersionFromFile @TestParams @CommonParams
            $PD.SetVersionFromFilePipeline.apiEndPointId | Should -Be $PD.NewEndpointFile.apiEndpointId
        }
        It 'updates successfully by parameter' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointFile.apiEndpointId
                'Body'          = $TestAPIFromFile
                'VersionNumber' = 1
            }
            $PD.SetVersionFromFileParam = Set-APIEndpointVersionFromFile @TestParams @CommonParams
            $PD.SetVersionFromFileParam.apiEndPointId | Should -Be $PD.NewEndpointFile.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APICategory
    #------------------------------------------------

    Context 'New-APICategory' {
        It 'returns the correct data' {
            $TestParams = @{
                'APICategoryName' = $TestAPICategoryName
            }
            $PD.NewAPICategory = New-APICategory @TestParams @CommonParams
            $PD.NewAPICategory.apiCategoryName | Should -Be $TestAPICategoryName
        }
    }

    Context 'Get-APICategory' {
        It 'returns a single category' {
            $TestParams = @{
                'APICategoryID' = $PD.NewAPICategory.apiCategoryId
            }
            $PD.APICategory = Get-APICategory @TestParams @CommonParams
            $PD.APICategory.apiCategoryName | Should -Be $TestAPICategoryName
        }
        It 'returns a list' {
            $PD.APICategories = Get-APICategory @CommonParams
            $PD.APICategories[0].apiCategoryId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APICategory' {
        It 'returns the correct data' {
            $TestParams = @{
                'APICategoryID'   = $PD.NewAPICategory.apiCategoryId
                'APICategoryName' = $TestAPICategoryName
            }
            $PD.SetAPICategory = Set-APICategory @TestParams @CommonParams
            $PD.SetAPICategory.apiCategoryId | Should -Be $PD.NewAPICategory.apiCategoryId
        }
    }

    Context 'Remove-APICategory' {
        It 'throws no errors' {
            $TestParams = @{
                'APICategoryID' = $PD.NewAPICategory.apiCategoryId
            }
            Remove-APICategory @TestParams @CommonParams
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionPII
    #------------------------------------------------

    Context 'PII' {
        BeforeAll {
            $TestAPIParamID = $PD.Resource.apiResourceMethods[0].apiParameters[0].apiParameterId
        }
        Context 'New-APIEndpointVersionPII' {
            It 'creates successfully' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'ParamID'       = $TestAPIParamID
                    'Types'         = @('CREDIT_OR_DEBIT_CARD_NUMBER')
                }
                New-APIEndpointVersionPII @TestParams @CommonParams
            }
        }
    
        Context 'Get-APIEndpointVersionPII' {
            It 'returns the correct data' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                }
                $PD.PII = Get-APIEndpointVersionPII @TestParams @CommonParams
                $PD.PII.id | Should -Not -BeNullOrEmpty
                $PD.PII.parameterId | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Update-APIEndpointVersionPII' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Update-APIEndpointVersionPII.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'updates successfully' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'PIIID'         = $PD.PII[0].id
                    'Status'        = 'CONFIRMED'
                }
                $UpdatePII = Update-APIEndpointVersionPII @TestParams
                $UpdatePII.id | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Set-APIEndpointVersionPIIStatus' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Set-APIEndpointVersionPIIStatus.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'updates successfully by attributes (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'ParamID'       = $PD.PII[0].id
                    'Status'        = 'DECLINED'
                }
                Set-APIEndpointVersionPIIStatus @TestParams
            }
            It 'updates successfully by request body as parameter (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'Body'          = @(
                        @{
                            'id'     = $PD.PII[0].id
                            'status' = 'CONFIRMED'
                        }
                    )
                }
                Set-APIEndpointVersionPIIStatus @TestParams @CommonParams
            }
            It 'updates successfully by request body as piped body (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                }
                @{
                    'id'     = $PD.PII[0].id
                    'status' = 'DECLINED'
                } | Set-APIEndpointVersionPIIStatus @TestParams @CommonParams
            }
        }

        Context 'Get-APIEndpointVersionPIISettings' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Get-APIEndpointVersionPIISettings.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'returns the correct data (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                }
                $PD.PIISettings = Get-APIEndpointVersionPIISettings @TestParams
                $PD.PIISettings.constraints | Should -Not -BeNullOrEmpty
                $PD.PIISettings.exclusions | Should -Not -BeNullOrEmpty
            }
        }
    
        Context 'Set-APIEndpointVersionPIISettings' {
            BeforeAll {
                Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                    $Response = Get-Content -Raw "$ResponseLibrary/Set-APIEndpointVersionPIISettings.json"
                    return $Response | ConvertFrom-Json
                }
            }
            It 'updates successfully by param (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'Body'          = $PD.PIISettings
                }
                $SetPIIParam = Set-APIEndpointVersionPIISettings @TestParams
                $SetPIIParam.constraints | Should -Not -BeNullOrEmpty
                $SetPIIParam.exclusions | Should -Not -BeNullOrEmpty
            }
            It 'updates successfully by pipeline (Mocked)' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                }
                $SetPIIPipeline = $PD.PIISettings | Set-APIEndpointVersionPIISettings @TestParams @CommonParams
                $SetPIIPipeline.constraints | Should -Not -BeNullOrEmpty
            }
        }
    
        Context 'Remove-APIEndpointVersionPII' {
            It 'throws no errors' {
                $TestParams = @{
                    'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                    'VersionNumber' = 1
                    'PIIID'         = $PD.PII[0].id
                }
                Remove-APIEndpointVersionPII @TestParams @CommonParams
            }
        }
    }

    #------------------------------------------------
    #                 Removals
    #------------------------------------------------

    Context 'Remove-APIEndpointVersionResourceOperation' {
        It 'deletes successfully' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.NewResourceOperation | Remove-APIEndpointVersionResourceOperation @TestParams @CommonParams
        }
        It 'handles empty input' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith { return 'IAR executed' }
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
                'Debug'         = $true
            }
            $DebugOutput = & {} | Remove-APIEndpointVersionResourceOperation @TestParams
            $DebugOutput | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-APIEndpointMultistepGroup' {
        It 'deletes successfully by param' {
            $TestParams = @{
                'APIEndpointID'    = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber'    = 1
                'MultistepGroupID' = $PD.NewMultistepGroupParam.multistepGroupId
            }
            Remove-APIEndpointMultistepGroup @TestParams @CommonParams
        }
        It 'deletes successfully by piped multistep group' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.NewMultistepGroupPipeline | Remove-APIEndpointMultistepGroup @TestParams @CommonParams
        }
        It 'deletes successfully by piped endpoint version' {
            $TestParams = @{
                'MultistepGroupID' = $PD.ThirdMultistepGroup.multistepGroupId
            }
            $PD.EndpointVersion | Remove-APIEndpointMultistepGroup @TestParams @CommonParams
        }
    }

    Context 'Remove-APIEndpointVersionResource' {
        It 'deletes successfully' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
            }
            $PD.NewResourceParam | Remove-APIEndpointVersionResource @TestParams @CommonParams
            $PD.NewResourcePipeline | Remove-APIEndpointVersionResource @TestParams @CommonParams
        }
        It 'handles empty input' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith { return 'IAR executed' }
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
                'VersionNumber' = 1
                'Debug'         = $true
            }
            $DebugOutput = & {} | Remove-APIEndpointVersionResource @TestParams
            $DebugOutput | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-APIEndpointVersion' {
        It 'deletes successfully' {
            $PD.NewAPIEndpointVersion | Remove-APIEndpointVersion @CommonParams
        }
        It 'handles empty input' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith { return 'IAR executed' }
            $TestParams = @{
                'Debug' = $true
            }
            $DebugOutput = & {} | Remove-APIEndpointVersion @TestParams
            $DebugOutput | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-APIEndpoint' {
        It 'deletes successfully by param' {
            $TestParams = @{
                'APIEndpointID' = $PD.NewEndpointParam.apiEndpointId
            }
            Remove-APIEndpoint @TestParams @CommonParams
        }
        It 'deletes successfully by pipeline' {
            $PD.NewEndpointPipeline | Remove-APIEndpoint @CommonParams
            $PD.CopyEndpointParam | Remove-APIEndpoint @CommonParams
            $PD.CopyEndpointPipeline | Remove-APIEndpoint @CommonParams
            $PD.NewEndpointFile, $PD.NewEndpointFile2 | Remove-APIEndpoint @CommonParams
        }
        It 'handles empty input' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith { return 'IAR executed' }
            $TestParams = @{
                'Debug' = $true
            }
            $DebugOutput = & {} | Remove-APIEndpoint @TestParams
            $DebugOutput | Should -Not -Be 'IAR executed'
        }
    }

    #------------------------------------------------
    #             APIEndpointActivation
    #------------------------------------------------

    Context 'New-APIEndpointActivation' {
        It 'creates successfully by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID' = 123456
                'Body'          = $TestAPIActivationJSON
                'VersionNumber' = 1
            }
            $Result = New-APIEndpointActivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID' = 123456
                'VersionNumber' = 1
            }
            $Result = $TestAPIActivationJSON | New-APIEndpointActivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by attributes' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID'          = 123456
                'Networks'               = 'Staging'
                'Notes'                  = 'Some notes'
                'NotificationRecipients' = 'mail@example.com'
                'VersionNumber'          = 1
            }
            $Result = New-APIEndpointActivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointDeactivation
    #------------------------------------------------

    Context 'New-APIEndpointDeactivation' {
        It 'creates successfully by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID' = 123456
                'Body'          = $TestAPIActivationJSON
                'VersionNumber' = 1
            }
            $Result = New-APIEndpointDeactivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID' = 123456
                'VersionNumber' = 1
            }
            $Result = $TestAPIActivationJSON | New-APIEndpointDeactivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by attributes' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'APIEndpointID'          = 123456
                'Networks'               = 'Staging'
                'Notes'                  = 'Some notes'
                'NotificationRecipients' = 'mail@example.com'
                'VersionNumber'          = 1
            }
            $Result = New-APIEndpointDeactivation @TestParams
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APISecureConnection
    #------------------------------------------------

    Context 'Test-APISecureConnection' {
        It 'completes successfully by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-APISecureConnection.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestAPISecureJSON
            }
            $TestAPISecureConnectionByParam = Test-APISecureConnection @TestParams
            $TestAPISecureConnectionByParam.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
        }
        It 'completes successfully by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-APISecureConnection.json"
                return $Response | ConvertFrom-Json
            }
            $TestAPISecureConnectionByPipeline = $TestAPISecureJSON | Test-APISecureConnection
            $TestAPISecureConnectionByPipeline.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointFromFile
    #------------------------------------------------

    Context 'New-APIEndpointFromFile' {
        It 'creates successfully by param' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointFromFile.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'Body' = $TestAPIFromFileJSON
            }
            $NewEndpointFileByBody = New-APIEndpointFromFile @TestParams
            $NewEndpointFileByBody.apiEndpointId | Should -Not -BeNullOrEmpty
        }
        It 'creates successfully by pipeline' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointFromFile.json"
                return $Response | ConvertFrom-Json
            }
            $NewEndpointFileByPipeline = $TestAPIFromFile | New-APIEndpointFromFile
            $NewEndpointFileByPipeline.apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }
}
