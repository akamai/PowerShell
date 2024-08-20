

Describe 'Safe Akamai.APIDefinitions Tests' {
    
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.APIDefinitions/Akamai.APIDefinitions.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestEndpointName = "akamaipowershell"
        $TestEndpointNameClone1 = $TestEndpointName + "-clone1"
        $TestEndpointNameClone2 = $TestEndpointName + "-clone2"
        $TestHostname = $env:PesterHostname
        $TestAPIDefinitionJSON = @"
{
    "apiEndPointName": "$TestEndpointName",
    "apiEndPointHosts": [
        "$TestHostname"
    ],
    "groupId": $TestGroupId,
    "contractId": "$TestContract"
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
    "contractId": "$TestContract",
    "basePath": "/api",
    "apiEndPointId": 0,
    "versionNumber": 1
}
"@
        $TestAPIDefinitionClone1 = $TestAPICloneJSON | ConvertFrom-Json
        $TestAPIDefinitionClone1.apiEndpointName = $TestEndpointNameClone1
        $TestAPIDefinitionClone2 = $TestAPICloneJSON | ConvertFrom-Json
        $TestAPIDefinitionClone2.apiEndpointName = $TestEndpointNameClone2
        $TestAPICategoryName = 'akamaipowershell-testing'
        $TestAPIResourceName1 = "resource1"
        $TestAPIResourceName2 = "resource2"
        $TestAPIResource1 = @"
{
    "apiResourceName": "$TestAPIResourceName1",
    "resourcePath": "/path1",
    "apiResourceMethods": [
        {
            "apiResourceMethod": "GET"
        }
    ]
}
"@
        $TestAPIResource2 = ConvertFrom-Json -InputObject $TestAPIResource1
        $TestAPIResource2.apiResourceName = $TestAPIResourceName2
        $TestAPIResource2.resourcePath = "/path2"
        $TestAPIResourceOperationJSON = '{
            "apiResourceId": 0,
            "method": "GET",
            "operationName": "Test Operation",
            "operationPurpose": "SEARCH"
        }'
        $TestAPIResourceOperation = ConvertFrom-Json -InputObject $TestAPIResourceOperationJSON
        $TestAPIRoutingJSON = '{
            "rules": [
              {
                "name": "Override",
                "forwardPath": "DEFAULT_PATH",
                "origin": "origin.akamaipowershell.net",
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
        $TestAPIQuery = '{
            "queryType": "ACTIVE_IN_PRODUCTION",
            "includeDetails": true
        }'
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
  title: akamaipowershell-fromfile
  description: Optional multiline or single-line description in [CommonMark](http://commonmark.org/help/) or HTML.
  version: 0.1.9

servers:
  - url: http://akamaipowershell-testing.edgesuite.net/v1
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
    "contractId": "$TestContract"
}
"@
        $TestAPIFromFile = ConvertFrom-Json -InputObject $TestAPIFromFileJSON
        
        $PD = @{}
        
    }

    AfterAll {
        
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
    #                 APIEndpoints                  
    #------------------------------------------------

    Context 'Get-APIEndpoints' {
        It 'returns the correct data' {
            $PD.GetAPIEndpoints = Get-APIEndpoints @CommonParams
            $PD.GetAPIEndpoints[0].apiEndPointId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpoint                  
    #------------------------------------------------

    Context 'New-APIEndpoint by parameter' {
        It 'New-APIEndpoint by param returns the correct data' {
            $PD.NewAPIEndpointByParam = New-APIEndpoint -Body $TestAPIDefinitionJSON @CommonParams
            $PD.NewAPIEndpointByParam.apiEndPointName | Should -Be $TestEndpointName
            # Update templates
            $TestAPIDefinitionClone1.apiEndpointId = $PD.NewAPIEndpointByParam.apiEndpointId
            $TestAPIDefinitionClone2.apiEndpointId = $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'New-APIEndpoint by pipeline' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointByPipeline = ($TestAPIDefinition | New-APIEndpoint @CommonParams)
            $PD.NewAPIEndpointByPipeline.apiEndPointName | Should -Be "$TestEndpointName`2"
        }
    }

    Context 'Copy-APIEndpoint by parameter' {
        It 'Copy-APIEndpoint by param returns the correct data' {
            $PD.CopyAPIEndpointByParam = Copy-APIEndpoint -Body $TestAPIDefinitionClone1 @CommonParams
            $PD.CopyAPIEndpointByParam.apiEndpointName | Should -Be $TestEndpointNameClone1
        }
    }

    Context 'Copy-APIEndpoint by pipeline' {
        It 'returns the correct data' {
            $PD.CopyAPIEndpointByPipeline = ($TestAPIDefinitionClone2 | Copy-APIEndpoint @CommonParams)
            $PD.CopyAPIEndpointByPipeline.apiEndpointName | Should -Be $TestEndpointNameClone2
        }
    }

    Context 'Hide-APIEndpoint - Parameter Set id' {
        It 'Hide-APIEndpoint (id) returns the correct data' {
            $PD.HideAPIEndpointId = Hide-APIEndpoint -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId @CommonParams
            $PD.HideAPIEndpointId.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'Hide-APIEndpoint - Parameter Set name' {
        It 'Hide-APIEndpoint (name) returns the correct data' {
            $PD.HideAPIEndpointName = Hide-APIEndpoint -APIEndpointName $PD.NewAPIEndpointByPipeline.apiEndpointName @CommonParams
            $PD.HideAPIEndpointName.apiEndpointId | Should -Be $PD.NewAPIEndpointByPipeline.apiEndpointId
        }
    }

    Context 'Show-APIEndpoint - Parameter Set id' {
        It 'Show-APIEndpoint (id) returns the correct data' {
            $PD.ShowAPIEndpointId = Show-APIEndpoint -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId @CommonParams
            $PD.ShowAPIEndpointId.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'Show-APIEndpoint - Parameter Set name' {
        It 'Show-APIEndpoint (name) returns the correct data' {
            $PD.ShowAPIEndpointName = Show-APIEndpoint -APIEndpointName $PD.NewAPIEndpointByPipeline.apiEndpointName @CommonParams
            $PD.ShowAPIEndpointName.apiEndpointId | Should -Be $PD.NewAPIEndpointByPipeline.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APIEndpointDetails                  
    #------------------------------------------------

    Context 'Expand-APIEndpointDetails' {
        It 'returns the correct data' {
            $ExpandAPIEndpointDetailsID, $ExpandAPIEndpointDetailsVersion = Expand-APIEndpointDetails -APIEndpointName $PD.NewAPIEndpointByParam.apiEndpointName -VersionNumber latest @CommonParams
            $ExpandAPIEndpointDetailsID | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
            $ExpandAPIEndpointDetailsVersion | Should -Be $PD.NewAPIEndpointByParam.versionNumber
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersion                  
    #------------------------------------------------

    Context 'New-APIEndpointVersion' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointVersion = New-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -CloneVersionNumber 1 @CommonParams
            $PD.NewAPIEndpointVersion.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'Get-APIEndpointVersion - All' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionIdAll = Get-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId @CommonParams
            $PD.GetAPIEndpointVersionIdAll[0].versionNumber | Should -Match '[\d]'
        }
    }

    Context 'Get-APIEndpointVersion - Single' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionSingle = Get-APIEndpointVersion -APIEndpointName $PD.NewAPIEndpointByParam.apiEndpointName -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionSingle.versionNumber | Should -Be 1 
        }
    }

    Context 'Set-APIEndpointVersion - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersion by param returns the correct data' {
            $PD.SetAPIEndpointVersionByParam = Set-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body ($PD.GetAPIEndpointVersionSingle | ConvertTo-Json -Depth 10) -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionByParam.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'Hide-APIEndpointVersion - Parameter Set id' {
        It 'Hide-APIEndpointVersion (id) returns the correct data' {
            $PD.HideAPIEndpointVersionId = Hide-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.HideAPIEndpointVersionId.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    Context 'Show-APIEndpointVersion - Parameter Set id' {
        It 'Show-APIEndpointVersion (id) returns the correct data' {
            $PD.ShowAPIEndpointVersionId = Show-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.ShowAPIEndpointVersionId.apiEndpointId | Should -Be $PD.NewAPIEndpointByParam.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionCache                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionCache' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionCache = Get-APIEndpointVersionCache -APIEndpointId $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionCache.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCache - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionCache by param returns the correct data' {
            $PD.SetAPIEndpointVersionCacheByParam = Set-APIEndpointVersionCache -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionCache -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionCacheByParam.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCache - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionCache by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionCacheByPipeline = ($PD.GetAPIEndpointVersionCache | Set-APIEndpointVersionCache -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionCacheByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionCORS                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionCORS' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionCORS = Get-APIEndpointVersionCORS -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionCORS.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCORS - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionCORS (id) by param returns the correct data' {
            $PD.SetAPIEndpointVersionCORSByParam = Set-APIEndpointVersionCORS -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionCORS -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionCORSByParam.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionCORS - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionCORS (id) by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionCORSByPipeline = ($PD.GetAPIEndpointVersionCORS | Set-APIEndpointVersionCORS -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionCORSByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionErrorResponses                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionErrorResponses - Parameter Set id' {
        It 'Get-APIEndpointVersionErrorResponses (id) returns the correct data' {
            $PD.GetAPIEndpointVersionErrorResponses = Get-APIEndpointVersionErrorResponses -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionErrorResponses.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionErrorResponses - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionErrorResponses (id) by param returns the correct data' {
            $PD.SetAPIEndpointVersionErrorResponsesByParam = Set-APIEndpointVersionErrorResponses -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionErrorResponses -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionErrorResponsesByParam.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionErrorResponses - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionErrorResponses (id) by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionErrorResponsesByPipeline = ($PD.GetAPIEndpointVersionErrorResponses | Set-APIEndpointVersionErrorResponses -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionErrorResponsesByPipeline.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionErrorResponseType                  
    #------------------------------------------------

    Context 'Set-APIEndpointVersionErrorResponseType - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionErrorResponseType returns the correct data' {
            $PD.SetAPIEndpointVersionErrorResponseType = Set-APIEndpointVersionErrorResponseType -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $TestAPIResponseType -Type "API_KEY_INVALID" -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionErrorResponseType.statusCode | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionGraphQL                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionGraphQL' {
        It '(id) returns the correct data' {
            $PD.GetAPIEndpointVersionGraphQL = Get-APIEndpointVersionGraphQL -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionGraphQL.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGraphQL by parameter' {
        It 'Set-APIEndpointVersionGraphQL (id) by param returns the correct data' {
            $PD.SetAPIEndpointVersionGraphQLByParam = Set-APIEndpointVersionGraphQL -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionGraphQL -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionGraphQLByParam.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGraphQL by pipeline' {
        It 'Set-APIEndpointVersionGraphQL (id) by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionGraphQLByPipeline = ($PD.GetAPIEndpointVersionGraphQL | Set-APIEndpointVersionGraphQL -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionGraphQLByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionGZip                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionGZip - Parameter Set id' {
        It 'Get-APIEndpointVersionGZip returns the correct data' {
            $PD.GetAPIEndpointVersionGZip = Get-APIEndpointVersionGZip -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionGZip.compressResponse | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGZip by parameter' {
        It 'Set-APIEndpointVersionGZip by param returns the correct data' {
            $PD.SetAPIEndpointVersionGZipByParam = Set-APIEndpointVersionGZip -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionGZip -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionGZipByParam.compressResponse | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionGZip by pipeline' {
        It 'returns the correct data' {
            $PD.SetAPIEndpointVersionGZipByPipeline = ($PD.GetAPIEndpointVersionGZip | Set-APIEndpointVersionGZip -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionGZipByPipeline.compressResponse | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionJWT                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionJWT - Parameter Set id' {
        It 'Get-APIEndpointVersionJWT (id) returns the correct data' {
            $PD.GetAPIEndpointVersionJWT = Get-APIEndpointVersionJWT -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionJWT.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionJWT by parameter' {
        It 'Set-APIEndpointVersionJWT by param returns the correct data' {
            $PD.SetAPIEndpointVersionJWTIdByParam = Set-APIEndpointVersionJWT -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionJWT -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionJWTIdByParam.enabled | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionJWT by pipeline' {
        It 'returns the correct data' {
            $PD.SetAPIEndpointVersionJWTIdByPipeline = ($PD.GetAPIEndpointVersionJWT | Set-APIEndpointVersionJWT -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionJWTIdByPipeline.enabled | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionPrivacy
    #------------------------------------------------

    Context 'Get-APIEndpointVersionPrivacy' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionPrivacy = Get-APIEndpointVersionPrivacy -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionPrivacy.public | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionPrivacy by parameter' {
        It 'Set-APIEndpointVersionPrivacy by param returns the correct data' {
            $PD.SetAPIEndpointVersionPrivacyByParam = Set-APIEndpointVersionPrivacy -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $PD.GetAPIEndpointVersionPrivacy -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionPrivacyByParam.public | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionPrivacy by pipeline' {
        It 'returns the correct data' {
            $PD.SetAPIEndpointVersionPrivacyByPipeline = ($PD.GetAPIEndpointVersionPrivacy | Set-APIEndpointVersionPrivacy -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionPrivacyByPipeline.public | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionResource
    #------------------------------------------------

    Context 'New-APIEndpointVersionResource by parameter' {
        It 'New-APIEndpointVersionResource by param returns the correct data' {
            $PD.NewAPIEndpointVersionResourceByParam = New-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $TestAPIResource1 -VersionNumber 1 @CommonParams
            $PD.NewAPIEndpointVersionResourceByParam.apiResourceName | Should -Be $TestAPIResourceName1
            # Set apiResourceId
            $TestAPIResourceOperation.apiResourceId = $PD.NewAPIEndpointVersionResourceByParam.apiResourceId
        }
    }

    Context 'New-APIEndpointVersionResource by pipeline' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointVersionResourceByPipeline = ($TestAPIResource2 | New-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.NewAPIEndpointVersionResourceByPipeline.apiResourceName | Should -Be $TestAPIResourceName2
        }
    }

    Context 'Get-APIEndpointVersionResource, all' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionResourceAll = Get-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionResourceAll[0].apiResourceName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionResource, single' {
        It 'returns the correct data' {
            $PD.GetAPIEndpointVersionResourceSingle = Get-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionResourceSingle.apiResourceId | Should -Be $PD.NewAPIEndpointVersionResourceByParam.apiResourceId
        }
    }

    Context 'Set-APIEndpointVersionResource by parameter' {
        It 'Set-APIEndpointVersionResource by param returns the correct data' {
            $PD.SetAPIEndpointVersionResourceByParam = Set-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceByParam.apiResourceId -Body $PD.NewAPIEndpointVersionResourceByParam -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionResourceByParam.apiResourceId | Should -Be $PD.NewAPIEndpointVersionResourceByParam.apiResourceId
        }
    }

    Context 'Set-APIEndpointVersionResource - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionResource by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionResourceByPipeline = ($PD.NewAPIEndpointVersionResourceByParam | Set-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionResourceByPipeline.apiResourceId | Should -Be $PD.NewAPIEndpointVersionResourceByParam.apiResourceId
        }
    }

    #------------------------------------------------
    #        APIEndpointVersionResourceOperation
    #------------------------------------------------

    Context 'New-APIEndpointVersionResourceOperation' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointVersionResourceOperation = New-APIEndpointVersionResourceOperation -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceByParam.apiResourceId -Body $TestAPIResourceOperation -VersionNumber 1 @CommonParams
            $PD.NewAPIEndpointVersionResourceOperation.operationId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionResourceOperation' {
        It '(id) returns the correct data' {
            $PD.GetAPIEndpointVersionResourceOperationId = Get-APIEndpointVersionResourceOperation -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $PD.NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionResourceOperationId.operationId | Should -Be $PD.NewAPIEndpointVersionResourceOperation.operationId
        }
    }

    Context 'Set-APIEndpointVersionResourceOperation by parameter' {
        It 'Set-APIEndpointVersionResourceOperation (id) by param returns the correct data' {
            $PD.SetAPIEndpointVersionResourceOperationIdByParam = Set-APIEndpointVersionResourceOperation -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceOperation.apiResourceId -Body $PD.GetAPIEndpointVersionResourceOperationId -OperationID $PD.NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionResourceOperationIdByParam.operationId | Should -Be $PD.NewAPIEndpointVersionResourceOperation.operationId
        }
    }

    Context 'Set-APIEndpointVersionResourceOperation by pipeline' {
        It 'Set-APIEndpointVersionResourceOperation (id) by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionResourceOperationIdByPipeline = ($PD.GetAPIEndpointVersionResourceOperationId | Set-APIEndpointVersionResourceOperation -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $PD.NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionResourceOperationIdByPipeline.operationId | Should -Be $PD.NewAPIEndpointVersionResourceOperation.operationId
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionRouting                  
    #------------------------------------------------

    Context 'Set-APIEndpointVersionRouting - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionRouting (id) by param returns the correct data' {
            $PD.SetAPIEndpointVersionRoutingIdByParam = Set-APIEndpointVersionRouting -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -Body $TestAPIRoutingJSON -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionRoutingIdByParam.rules | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Set-APIEndpointVersionRouting - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionRouting (id) by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionRoutingIdByPipeline = ($TestAPIRouting | Set-APIEndpointVersionRouting -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionRoutingIdByPipeline.rules | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-APIEndpointVersionRouting - Parameter Set id' {
        It 'Get-APIEndpointVersionRouting (id) returns the correct data' {
            $PD.GetAPIEndpointVersionRoutingId = Get-APIEndpointVersionRouting -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionRoutingId.rules | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionSummary                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionSummary - Parameter Set id' {
        It 'Get-APIEndpointVersionSummary (id) returns the correct data' {
            $PD.GetAPIEndpointVersionSummaryId = Get-APIEndpointVersionSummary -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionSummaryId.apiVersionId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-APIEndpointVersionSummary - Parameter Set name' {
        It 'Get-APIEndpointVersionSummary (name) returns the correct data' {
            $PD.GetAPIEndpointVersionSummaryName = Get-APIEndpointVersionSummary -APIEndpointName $PD.NewAPIEndpointByParam.apiEndpointName -VersionNumber 1 @CommonParams
            $PD.GetAPIEndpointVersionSummaryName.apiVersionId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIHostnames                  
    #------------------------------------------------

    Context 'Get-APIHostnames' {
        It 'returns the correct data' {
            $PD.GetAPIHostnames = Get-APIHostnames -ContractID $TestContract -GroupID $TestGroupID @CommonParams
            $PD.GetAPIHostnames.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 APIHostnamesAndGroups                  
    #------------------------------------------------

    Context 'Get-APIHostnamesAndGroups' {
        It 'returns the correct data' {
            $PD.GetAPIHostnamesAndGroups = Get-APIHostnamesAndGroups -ContractID $TestContract -GroupID $TestGroupID @CommonParams
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
                operations = @(
                    @{ 
                        apiEndPointId      = $PD.GetAPIOperations.operations[0].apiEndpointId
                        apiResourceLogicId = $PD.GetAPIOperations.operations[0].apiResourceLogicId
                        operationId        = $PD.GetAPIOperations.operations[0].operationId
                    }
                )
            }
        }
    }

    Context 'Test-APIOperations by parameter' {
        It 'Test-APIOperations by param returns the correct data' {
            $PD.TestAPIOperationsByParam = Test-APIOperations -Body $PD.TestAPIOperationsBody @CommonParams
            $PD.TestAPIOperationsByParam.apiEndPoints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-APIOperations by pipeline' {
        It 'returns the correct data' {
            $PD.TestAPIOperationsByPipeline = ($PD.TestAPIOperationsBody | Test-APIOperations @CommonParams)
            $PD.TestAPIOperationsByPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIUserEntitlements                  
    #------------------------------------------------

    Context 'Get-APIUserEntitlements' {
        It 'returns the correct data' {
            $PD.GetAPIUserEntitlements = Get-APIUserEntitlements -ContractID $TestContract -GroupID $TestGroupId @CommonParams
            $PD.GetAPIUserEntitlements.count | Should -BeGreaterThan 0
        }
    }

    #------------------------------------------------
    #                 APIOperationsQuery                  
    #------------------------------------------------

    Context 'New-APIOperationsQuery by parameter' {
        It 'New-APIOperationsQuery by param returns the correct data' {
            $PD.NewAPIOperationsQueryByParam = New-APIOperationsQuery -Body $TestAPIQuery @CommonParams
            $PD.NewAPIOperationsQueryByParam.apiEndPoints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIOperationsQuery by pipeline' {
        It 'returns the correct data' {
            $PD.NewAPIOperationsQueryByPipeline = ($TestAPIQuery | New-APIOperationsQuery @CommonParams)
            $PD.NewAPIOperationsQueryByPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointFromFile                  
    #------------------------------------------------
    
    Context 'New-APIEndpointFromFile by attributes' {
        It 'returns the correct data' {
            $PD.NewAPIEndpointFromFileByAttr = New-APIEndpointFromFile -ImportFileFormat swagger -ImportFileSource BODY_BASE64 -ImportFileContent $TestEncodedSwaggerContent -ContractID $TestContract -GroupID $TestGroupID @CommonParams
            $PD.NewAPIEndpointFromFileByAttr.apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionFromFile                  
    #------------------------------------------------

    Context 'Set-APIEndpointVersionFromFile by attributes' {
        It 'returns the correct data' {
            $PD.SetAPIEndpointVersionFromFileIdByAttr = Set-APIEndpointVersionFromFile -APIEndpointID $PD.NewAPIEndpointFromFileByAttr.apiEndpointId -VersionNumber 1 -ImportFileFormat swagger -ImportFileSource BODY_BASE64 -ImportFileContent $TestEncodedSwaggerContent -ContractID $TestContract -GroupID $TestGroupID @CommonParams
            $PD.SetAPIEndpointVersionFromFileIdByAttr.apiEndPointId | Should -Be $PD.NewAPIEndpointFromFileByAttr.apiEndpointId
        }
    }

    Context 'Set-APIEndpointVersionFromFile - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionFromFile by pipeline returns the correct data' {
            $PD.SetAPIEndpointVersionFromFileIdByPipeline = ($TestAPIFromFileJSON | Set-APIEndpointVersionFromFile -APIEndpointID $PD.NewAPIEndpointFromFileByAttr.apiEndpointId -VersionNumber 1 @CommonParams)
            $PD.SetAPIEndpointVersionFromFileIdByPipeline.apiEndPointId | Should -Be $PD.NewAPIEndpointFromFileByAttr.apiEndpointId
        }
    }

    Context 'Set-APIEndpointVersionFromFile - Parameter Set name, by parameter' {
        It 'Set-APIEndpointVersionFromFile by param returns the correct data' {
            $PD.SetAPIEndpointVersionFromFileNameByParam = Set-APIEndpointVersionFromFile -APIEndpointID $PD.NewAPIEndpointFromFileByAttr.apiEndpointId -Body $TestAPIFromFile -VersionNumber 1 @CommonParams
            $PD.SetAPIEndpointVersionFromFileNameByParam.apiEndPointId | Should -Be $PD.NewAPIEndpointFromFileByAttr.apiEndpointId
        }
    }

    #------------------------------------------------
    #                 APICategory                  
    #------------------------------------------------

    Context 'New-APICategory' {
        It 'returns the correct data' {
            $PD.NewAPICategory = New-APICategory -APICategoryName $TestAPICategoryName @CommonParams
            $PD.NewAPICategory.apiCategoryName | Should -Be $TestAPICategoryName
        }
    }

    Context 'Get-APICategory - Parameter Set single' {
        It 'Get-APICategory (single) returns the correct data' {
            $PD.GetAPICategorySingle = Get-APICategory -APICategoryID $PD.NewAPICategory.apiCategoryId @CommonParams
            $PD.GetAPICategorySingle.apiCategoryName | Should -Be $TestAPICategoryName
        }
    }

    Context 'Get-APICategory - Parameter Set all' {
        It 'Get-APICategory (all) returns the correct data' {
            $PD.GetAPICategoryAll = Get-APICategory @CommonParams
            $PD.GetAPICategoryAll[0].apiCategoryId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APICategory' {
        It 'returns the correct data' {
            $PD.SetAPICategory = Set-APICategory -APICategoryID $PD.NewAPICategory.apiCategoryId -APICategoryName $TestAPICategoryName @CommonParams
            $PD.SetAPICategory.apiCategoryId | Should -Be $PD.NewAPICategory.apiCategoryId
        }
    }

    Context 'Remove-APICategory' {
        It 'throws no errors' {
            Remove-APICategory -APICategoryID $PD.NewAPICategory.apiCategoryId @CommonParams 
        }
    }

    
    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    Context 'Remove-APIEndpointVersionResourceOperation' {
        It 'throws no errors' {
            Remove-APIEndpointVersionResourceOperation -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $PD.NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @CommonParams 
        }
    }

    Context 'Remove-APIEndpointVersionResource - Parameter Set id' {
        It 'Remove-APIEndpointVersionResource (id) throws no errors' {
            Remove-APIEndpointVersionResource -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -APIResourceID $PD.NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @CommonParams 
        }
    }

    Context 'Remove-APIEndpointVersionResource - Parameter Set name' {
        It 'Remove-APIEndpointVersionResource (name) returns the correct data' {
            Remove-APIEndpointVersionResource -APIEndpointName $PD.NewAPIEndpointByParam.apiEndpointName -APIResourceID $PD.NewAPIEndpointVersionResourceByPipeline.apiResourceId -VersionNumber 1 @CommonParams 
        }
    }

    Context 'Remove-APIEndpointVersion' {
        It 'throws no errors' {
            Remove-APIEndpointVersion -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId -VersionNumber latest @CommonParams 
        }
    }

    Context 'Remove-APIEndpoint' {
        It 'throws no errors' {
            Remove-APIEndpoint -APIEndpointID $PD.NewAPIEndpointByParam.apiEndpointId @CommonParams 
            Remove-APIEndpoint -APIEndpointID $PD.NewAPIEndpointByPipeline.apiEndpointId @CommonParams 
            Remove-APIEndpoint -APIEndpointID $PD.CopyAPIEndpointByParam.apiEndpointId @CommonParams 
            Remove-APIEndpoint -APIEndpointID $PD.CopyAPIEndpointByPipeline.apiEndpointId @CommonParams 
            Remove-APIEndpoint -APIEndpointID $PD.NewAPIEndpointFromFileByAttr.apiEndpointId @CommonParams 
        }
    }
}


Describe 'Unsafe Akamai.APIDefinitions Tests' {
    BeforeAll {
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.APIDefinitions/Akamai.APIDefinitions.psd1 -Force
        
        $TestPIIParamJSON = '[
            {
                "id": 1209248,
                "status": "DECLINED"
            }
        ]'
        # Remember to replace \r\n line breaks with \n, since the API grumbles
        $TestSwaggerContent = @"
openapi: 3.0.0
info:
    title: akamaipowershell-fromfile
    description: Optional multiline or single-line description in [CommonMark](http://commonmark.org/help/) or HTML.
    version: 0.1.9

servers:
    - url: http://akamaipowershell-testing.edgesuite.net/v1
    description: Optional server description, e.g. Main (production) server

paths:
    /users:
    get:
        summary: Returns a list of users.
        description: Optional extended description in CommonMark or HTML.
        responses:
        '200':    # status code
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
    "groupId": 123456,
    "contractId": "1-2AB34C"
}
"@
        $TestAPIFromFile = ConvertFrom-Json -InputObject $TestAPIFromFileJSON
        $TestAPISecureJSON = '{
            "certChain": {
                "content": "-----BEGIN CERTIFICATE-----\nMIIFsDCCA5igAwIBAgIJAL7HIonYis0aMA0GCSqGSIb3DQEBCwUAMG0xCzAJBgNV\nBAYTAlVTMREwDwYDVQQIDAhyYXBpZHppazERMA8GA1UEBwwIcmFwaWR6aWsxETAP\nBgNVBAoMCHJhcGlkemlrMREwDwYDVQQLDAhyYXBpZHppazESMBAGA1UEAwwJbG9j\nYWxob3N0MB4XDTE5MDYxMTE0MzI0NloXDTI0MDYwOTE0MzI0NlowbTELMAkGA1UE\nBhMCVVMxETAPBgNVBAgMCHJhcGlkemlrMREwDwYDVQQHDAhyYXBpZHppazERMA8G\nA1UECgwIcmFwaWR6aWsxETAPBgNVBAsMCHJhcGlkemlrMRIwEAYDVQQDDAlsb2Nh\nbGhvc3QwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCua7kn9yrkpMMH\nT18yzPFK9LBPk4GzMX0BZfEi2jzKKoc00BtoU/zeS9ewj+2IdIoHa19GE7qnnMux\nkbwm6GNkFt4rzJsQ5ruMSKEqzd4I81HDmS5s2X3o4ZqYWVHAx/rqsh5EIt5qAjq4\njebXeMuhlnkx6jMs+4+ZFfATVvOJ78VnUGUheNTcTGgCvxU7ZZ3+IZubJ6BVdJjC\nwxM30eroVF3efX4HrRXhLtatQtxjX6g2qOUfFiuNNLcgx+4NPqbKpecqyUbopt18\n72MmohKy+YfVEk7OFWLyNPoL237KCznkCGwcQYrXTJzDVAN4NqQEo513nIHEC89F\nX/WomZWwLKVyQpiA1z/jUdYnSzsrPSuA+oP1WmfwVjtxeiwB7Asy/d/5OmOtID+a\nzT41irl1Dp5F6mgAI8CZ1LnzYIlvJAQS9+cpLG9rsyYDRr5+78TebiqP02CrRj9S\nstoam6WG21Z9fJ/aPKJ0ZQHkpXuHDy6RHJro+2wk0coWOyNT0UH6/7kuKHjEGaAG\nBXjElxZ8pJySwYXeeD5gmimQKPE/us1BD2jk0KWYxnwJ+jM4S7RipgTSGsy3Nw42\nvKnKw6FwOIoQqwTkiNF+p7EsjeciO09zLecXxlh3p8WREEZU5NICmGL7xItdD+7I\nVr/tn3XNbuSUu0IqdbhO19JoNXG/UwIDAQABo1MwUTAdBgNVHQ4EFgQUcXwqRZUC\nj9+VsyCfy4oIMN9u1V0wHwYDVR0jBBgwFoAUcXwqRZUCj9+VsyCfy4oIMN9u1V0w\nDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAgEAQgWlrEW+K3fCMO9K\n2TuxY6ruXbdekRv+nw+weXe9+GLlyvEFxktYTE/cN8pHrKOG6F/ea+CCHW4xenVp\npchFI8zPQ8kDEDUUrPaQLbw9kzXKLZwUs+KMZXEZJInxWrr1mWeP+lVSf6f4hwNd\nfvJ8SOPe3/IAE0C79JaclzYE3ErfTlBeouQ09jXbeHc0VvodFp7XcmIMA9e5zIzu\nCU1QOa1LRrn5+TI41BbjKypMl8EE7ZEoyWRj4sMQGfuh9/kmu9ZPINJ79/j22vZG\nVj72jKoIu01qI0esfL7GcE9gd9eWhDRuBYNCAfXWK7xvMwYIxeLgP9LJoeBCVMV+\n7k1AHGpgU4UYveu71VCUIlGIaL1t/DKHi8SqDaKV2eImurPp90eLWAU1V6b+UG5/\n+HoUI8Kd5KgfPprv4AKKOTse04xbFDehvgCpQpcwzoV0h2AQtHhsN65dXfO3XPnR\nYQka7OQcEJS/gLXl7FIcpfkNyvi8ompHVSGTnAEB4qAwazz3FWe6r7qbqty2n0Ye\nNTkylMbBMFpMZrP4BP6YFf3BnkzjFcffHvtVGGUbyebQazc+5HyZycabEhekETeS\nLUOCwFWH68wXI23eU5Z7mKAI+rwhqVuJZPzZFUWfNhj7Pt/aby+7SIZAQ9YCR2lk\n6IUdRIpisR9k478g/4pQYly6yN4=\n-----END CERTIFICATE-----",
                "name": "bookstore_cert.pem"
            },
            "hosts": [
                "bookstore.api.akamai.com"
            ]
        }'
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
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.APIDefinitions"
        $PD = @{}
    }

    #------------------------------------------------
    #                 APIEndpointVersionPII                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionPII - Parameter Set id' {
        It 'Get-APIEndpointVersionPII (id) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-APIEndpointVersionPII.json"
                return $Response | ConvertFrom-Json
            }
            $PD.GetAPIEndpointVersionPII = Get-APIEndpointVersionPII -APIEndpointID 123456 -VersionNumber 1
            $PD.GetAPIEndpointVersionPII.constraints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionPII - Parameter Set id, by parameter' {
        It 'Set-APIEndpointVersionPII (id) by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-APIEndpointVersionPII.json"
                return $Response | ConvertFrom-Json
            }
            $SetAPIEndpointVersionPIIIdByParam = Set-APIEndpointVersionPII -APIEndpointID 123456 -Body $PD.GetAPIEndpointVersionPII -VersionNumber 1
            $SetAPIEndpointVersionPIIIdByParam.constraints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-APIEndpointVersionPII - Parameter Set id, by pipeline' {
        It 'Set-APIEndpointVersionPII (id) by pipeline returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-APIEndpointVersionPII.json"
                return $Response | ConvertFrom-Json
            }
            $SetAPIEndpointVersionPIIIdByPipeline = ($PD.GetAPIEndpointVersionPII | Set-APIEndpointVersionPII -APIEndpointID 123456 -VersionNumber 1)
            $SetAPIEndpointVersionPIIIdByPipeline.constraints | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Update-APIEndpointVersionPII - Parameter Set id' {
        It 'Update-APIEndpointVersionPII (id) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Update-APIEndpointVersionPII.json"
                return $Response | ConvertFrom-Json
            }
            $UpdateAPIEndpointVersionPIIId = Update-APIEndpointVersionPII -APIEndpointID 123456 -PIIID 123456 -Status DISCOVERED -VersionNumber 1
            $UpdateAPIEndpointVersionPIIId.id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-APIEndpointVersionPII' {
        It 'throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Remove-APIEndpointVersionPII.json"
                return $Response | ConvertFrom-Json
            }
            Remove-APIEndpointVersionPII -APIEndpointID 123456 -PIIID 123456 -VersionNumber 1
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionPIIParams                  
    #------------------------------------------------

    Context 'Get-APIEndpointVersionPIIParams - Parameter Set id' {
        It 'Get-APIEndpointVersionPIIParams (id) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-APIEndpointVersionPIIParams.json"
                return $Response | ConvertFrom-Json
            }
            $GetAPIEndpointVersionPIIParamsId = Get-APIEndpointVersionPIIParams -APIEndpointID 123456 -VersionNumber 1
            $GetAPIEndpointVersionPIIParamsId[0].id | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointVersionPIIParameters                  
    #------------------------------------------------

    Context 'Set-APIEndpointVersionPIIParameters - Parameter Set id' {
        It 'Set-APIEndpointVersionPIIParameters throws no errors' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Set-APIEndpointVersionPIIParameters.json"
                return $Response | ConvertFrom-Json
            }
            Set-APIEndpointVersionPIIParameters -APIEndpointID 123456 -VersionNumber 1 -Body $TestPIIParamJSON 
        }
    }

    #------------------------------------------------
    #                 APIEndpointActivation                  
    #------------------------------------------------

    Context 'New-APIEndpointActivation - Parameter' {
        It 'New-APIEndpointActivation by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = New-APIEndpointActivation -APIEndpointID 123456 -Body $TestAPIActivationJSON -VersionNumber 1
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIEndpointActivation - Pipeline' {
        It 'New-APIEndpointActivation by pipeline returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = ($TestAPIActivationJSON | New-APIEndpointActivation -APIEndpointID 123456 -VersionNumber 1)
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIEndpointActivation - Attributes' {
        It 'New-APIEndpointActivation by attributes returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointActivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = New-APIEndpointActivation -APIEndpointID 123456 -Networks Staging -Notes 'Some notes' -NotificationRecipients 'mail@example.com' -VersionNumber 1
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointDeactivation                  
    #------------------------------------------------

    Context 'New-APIEndpointDeactivation - Parameter Set id-body, name-body, by parameter' {
        It 'New-APIEndpointDeactivation (id-body, name-body) by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = New-APIEndpointDeactivation -APIEndpointID 123456 -Body $TestAPIActivationJSON -VersionNumber 1
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIEndpointDeactivation - Parameter Set id-body, name-body, by pipeline' {
        It 'New-APIEndpointDeactivation (id-body, name-body) by pipeline returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = ($TestAPIActivationJSON | New-APIEndpointDeactivation -APIEndpointID 123456 -VersionNumber 1)
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIEndpointDeactivation - Parameter Set id-attributes, name-attributes' {
        It 'New-APIEndpointDeactivation (id-attributes, name-attributes) returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointDeactivation.json"
                return $Response | ConvertFrom-Json
            }
            $Result = New-APIEndpointDeactivation -APIEndpointID 123456 -Networks Staging -Notes 'Some notes' -NotificationRecipients 'mail@example.com' -VersionNumber 1
            $Result.networks | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APISecureConnection                  
    #------------------------------------------------

    Context 'Test-APISecureConnection by parameter' {
        It 'Test-APISecureConnection by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-APISecureConnection.json"
                return $Response | ConvertFrom-Json
            }
            $TestAPISecureConnectionByParam = Test-APISecureConnection -Body $TestAPISecureJSON
            $TestAPISecureConnectionByParam.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-APISecureConnection by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Test-APISecureConnection.json"
                return $Response | ConvertFrom-Json
            }
            $TestAPISecureConnectionByPipeline = ($TestAPISecureJSON | Test-APISecureConnection)
            $TestAPISecureConnectionByPipeline.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
        }
    }

    #------------------------------------------------
    #                 APIEndpointFromFile                  
    #------------------------------------------------

    Context 'New-APIEndpointFromFile by parameter' {
        It 'New-APIEndpointFromFile by param returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointFromFile.json"
                return $Response | ConvertFrom-Json
            }
            $NewAPIEndpointFromFileByBody = New-APIEndpointFromFile -Body $TestAPIFromFileJSON
            $NewAPIEndpointFromFileByBody.apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-APIEndpointFromFile by pipeline' {
        It 'returns the correct data' {
            Mock -CommandName Invoke-AkamaiRestMethod -ModuleName Akamai.APIDefinitions -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/New-APIEndpointFromFile.json"
                return $Response | ConvertFrom-Json
            }
            $NewAPIEndpointFromFileByPipeline = ($TestAPIFromFile | New-APIEndpointFromFile)
            $NewAPIEndpointFromFileByPipeline.apiEndpointId | Should -Not -BeNullOrEmpty
        }
    }
}

