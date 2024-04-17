Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.APIDefinitions/Akamai.APIDefinitions.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestGroupID = $env:PesterGroupID
$Script:TestEndpointName = "akamaipowershell"
$Script:TestEndpointNameClone1 = $TestEndpointName + "-clone1"
$Script:TestEndpointNameClone2 = $TestEndpointName + "-clone2"
$Script:TestHostname = $env:PesterHostname
$Script:TestAPIDefinitionJSON = @"
{
    "apiEndPointName": "$TestEndpointName",
    "apiEndPointHosts": [
        "$TestHostname"
    ],
    "groupId": $TestGroupId,
    "contractId": "$TestContract"
}
"@
$Script:TestAPIDefinition = $TestAPIDefinitionJSON | ConvertFrom-Json
# Update name to avoid clash
$TestAPIDefinition.apiEndpointName = $TestAPIDefinition.apiEndpointName + "2"
# Clone
$Script:TestAPICloneJSON = @"
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
$Script:TestAPIDefinitionClone1 = $TestAPICloneJSON | ConvertFrom-Json
$TestAPIDefinitionClone1.apiEndpointName = $TestEndpointNameClone1
$Script:TestAPIDefinitionClone2 = $TestAPICloneJSON | ConvertFrom-Json
$TestAPIDefinitionClone2.apiEndpointName = $TestEndpointNameClone2
$Script:TestAPICategoryName = 'akamaipowershell-testing'
$Script:TestAPIResourceName1 = "resource1"
$Script:TestAPIResourceName2 = "resource2"
$Script:TestAPIResource1 = @"
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
$Script:TestAPIResource2 = ConvertFrom-Json -InputObject $TestAPIResource1
$TestAPIResource2.apiResourceName = $TestAPIResourceName2
$TestAPIResource2.resourcePath = "/path2"
$Script:TestAPIResourceOperationJSON = '{
    "apiResourceId": 0,
    "method": "GET",
    "operationName": "Test Operation",
    "operationPurpose": "SEARCH"
}'
$script:TestAPIResourceOperation = ConvertFrom-Json -InputObject $TestAPIResourceOperationJSON
$Script:TestAPIRoutingJSON = '{
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
$Script:TestAPIRouting = ConvertFrom-Json -InputObject $TestAPIRoutingJSON
$Script:TestAPIQuery = '{
    "queryType": "ACTIVE_IN_PRODUCTION",
    "includeDetails": true
}'
$Script:TestAPIResponseType = '{
    "body": "{\"title\":\"The API key you provided does not exist.\" }",
    "headers": [
        {
            "name": "Content-Type",
            "value": "application/problem+json"
        }
    ],
    "statusCode": 401
}'
$Script:TestAPIActivationJSON = '{
    "networks": [
        "STAGING"
    ],
    "notes": "D - E - C - C(low) - G",
    "notificationRecipients": [
        "mail@example.com"
    ]
}'
$Script:TestAPIActivation = ConvertFrom-Json -InputObject $TestAPIActivationJSON
$Script:TestAPISecureJSON = '{
    "certChain": {
        "content": "-----BEGIN CERTIFICATE-----\nMIIFsDCCA5igAwIBAgIJAL7HIonYis0aMA0GCSqGSIb3DQEBCwUAMG0xCzAJBgNV\nBAYTAlVTMREwDwYDVQQIDAhyYXBpZHppazERMA8GA1UEBwwIcmFwaWR6aWsxETAP\nBgNVBAoMCHJhcGlkemlrMREwDwYDVQQLDAhyYXBpZHppazESMBAGA1UEAwwJbG9j\nYWxob3N0MB4XDTE5MDYxMTE0MzI0NloXDTI0MDYwOTE0MzI0NlowbTELMAkGA1UE\nBhMCVVMxETAPBgNVBAgMCHJhcGlkemlrMREwDwYDVQQHDAhyYXBpZHppazERMA8G\nA1UECgwIcmFwaWR6aWsxETAPBgNVBAsMCHJhcGlkemlrMRIwEAYDVQQDDAlsb2Nh\nbGhvc3QwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCua7kn9yrkpMMH\nT18yzPFK9LBPk4GzMX0BZfEi2jzKKoc00BtoU/zeS9ewj+2IdIoHa19GE7qnnMux\nkbwm6GNkFt4rzJsQ5ruMSKEqzd4I81HDmS5s2X3o4ZqYWVHAx/rqsh5EIt5qAjq4\njebXeMuhlnkx6jMs+4+ZFfATVvOJ78VnUGUheNTcTGgCvxU7ZZ3+IZubJ6BVdJjC\nwxM30eroVF3efX4HrRXhLtatQtxjX6g2qOUfFiuNNLcgx+4NPqbKpecqyUbopt18\n72MmohKy+YfVEk7OFWLyNPoL237KCznkCGwcQYrXTJzDVAN4NqQEo513nIHEC89F\nX/WomZWwLKVyQpiA1z/jUdYnSzsrPSuA+oP1WmfwVjtxeiwB7Asy/d/5OmOtID+a\nzT41irl1Dp5F6mgAI8CZ1LnzYIlvJAQS9+cpLG9rsyYDRr5+78TebiqP02CrRj9S\nstoam6WG21Z9fJ/aPKJ0ZQHkpXuHDy6RHJro+2wk0coWOyNT0UH6/7kuKHjEGaAG\nBXjElxZ8pJySwYXeeD5gmimQKPE/us1BD2jk0KWYxnwJ+jM4S7RipgTSGsy3Nw42\nvKnKw6FwOIoQqwTkiNF+p7EsjeciO09zLecXxlh3p8WREEZU5NICmGL7xItdD+7I\nVr/tn3XNbuSUu0IqdbhO19JoNXG/UwIDAQABo1MwUTAdBgNVHQ4EFgQUcXwqRZUC\nj9+VsyCfy4oIMN9u1V0wHwYDVR0jBBgwFoAUcXwqRZUCj9+VsyCfy4oIMN9u1V0w\nDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAgEAQgWlrEW+K3fCMO9K\n2TuxY6ruXbdekRv+nw+weXe9+GLlyvEFxktYTE/cN8pHrKOG6F/ea+CCHW4xenVp\npchFI8zPQ8kDEDUUrPaQLbw9kzXKLZwUs+KMZXEZJInxWrr1mWeP+lVSf6f4hwNd\nfvJ8SOPe3/IAE0C79JaclzYE3ErfTlBeouQ09jXbeHc0VvodFp7XcmIMA9e5zIzu\nCU1QOa1LRrn5+TI41BbjKypMl8EE7ZEoyWRj4sMQGfuh9/kmu9ZPINJ79/j22vZG\nVj72jKoIu01qI0esfL7GcE9gd9eWhDRuBYNCAfXWK7xvMwYIxeLgP9LJoeBCVMV+\n7k1AHGpgU4UYveu71VCUIlGIaL1t/DKHi8SqDaKV2eImurPp90eLWAU1V6b+UG5/\n+HoUI8Kd5KgfPprv4AKKOTse04xbFDehvgCpQpcwzoV0h2AQtHhsN65dXfO3XPnR\nYQka7OQcEJS/gLXl7FIcpfkNyvi8ompHVSGTnAEB4qAwazz3FWe6r7qbqty2n0Ye\nNTkylMbBMFpMZrP4BP6YFf3BnkzjFcffHvtVGGUbyebQazc+5HyZycabEhekETeS\nLUOCwFWH68wXI23eU5Z7mKAI+rwhqVuJZPzZFUWfNhj7Pt/aby+7SIZAQ9YCR2lk\n6IUdRIpisR9k478g/4pQYly6yN4=\n-----END CERTIFICATE-----",
        "name": "bookstore_cert.pem"
    },
    "hosts": [
        "bookstore.api.akamai.com"
    ]
}'
$Script:TestSwaggerContent = Get-Content -Raw $PSScriptRoot\swagger.yaml
$Script:TestEncodedSwaggerContent = ConvertTo-Base64 -UnencodedString $TestSwaggerContent
$Script:TestAPIFromFileJSON = @"
{
    "importFileFormat": "swagger",
    "importFileSource": "BODY_BASE64",
    "importFileContent": "$TestEncodedSwaggerContent",
    "groupId": $TestGroupID,
    "contractId": "$TestContract"
}
"@
$Script:TestAPIFromFile = ConvertFrom-Json -InputObject $TestAPIFromFileJSON
$Script:TestPIIParamJSON = '[
    {
        "id": 1209248,
        "status": "DECLINED"
    }
]'

# Set common params
$Script:SafeCommonParams = @{
    EdgeRCFile = $EdgeRCFile
    Section    = $Section
}
$Script:UnsafeCommonParams = @{
    EdgeRCFile = $SafeEdgeRCFile
    Section    = $Section
}


Describe 'Safe Akamai.APIDefinitions Tests' {

    BeforeDiscovery {
        
    }

    #------------------------------------------------
    #                 APIContractsAndGroups                  
    #------------------------------------------------

    ### Get-APIContractsAndGroups
    $Script:GetAPIContractsAndGroups = Get-APIContractsAndGroups @SafeCommonParams
    it 'Get-APIContractsAndGroups returns the correct data' {
        $GetAPIContractsAndGroups[0].groupId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpoints                  
    #------------------------------------------------

    ### Get-APIEndpoints
    $Script:GetAPIEndpoints = Get-APIEndpoints @SafeCommonParams
    it 'Get-APIEndpoints returns the correct data' {
        $GetAPIEndpoints[0].apiEndPointId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpoint                  
    #------------------------------------------------

    ### New-APIEndpoint by parameter
    $Script:NewAPIEndpointByParam = New-APIEndpoint -Body $TestAPIDefinitionJSON @SafeCommonParams
    it 'New-APIEndpoint by param returns the correct data' {
        $NewAPIEndpointByParam.apiEndPointName | Should -Be $TestEndpointName
    }

    ### New-APIEndpoint by pipeline
    $Script:NewAPIEndpointByPipeline = ($TestAPIDefinition | New-APIEndpoint @SafeCommonParams)
    it 'New-APIEndpoint by pipeline returns the correct data' {
        $NewAPIEndpointByPipeline.apiEndPointName | Should -Be "$TestEndpointName`2"
    }

    ### Copy-APIEndpoint by parameter
    $TestAPIDefinitionClone1.apiEndpointId = $NewAPIEndpointByParam.apiEndpointId
    $Script:CopyAPIEndpointByParam = Copy-APIEndpoint -Body $TestAPIDefinitionClone1 @SafeCommonParams
    it 'Copy-APIEndpoint by param returns the correct data' {
        $CopyAPIEndpointByParam.apiEndpointName | Should -Be $TestEndpointNameClone1
    }

    ### Copy-APIEndpoint by pipeline
    $TestAPIDefinitionClone2.apiEndpointId = $NewAPIEndpointByParam.apiEndpointId
    $Script:CopyAPIEndpointByPipeline = ($TestAPIDefinitionClone2 | Copy-APIEndpoint @SafeCommonParams)
    it 'Copy-APIEndpoint by pipeline returns the correct data' {
        $CopyAPIEndpointByPipeline.apiEndpointName | Should -Be $TestEndpointNameClone2
    }

    ### Hide-APIEndpoint - Parameter Set 'id'
    $Script:HideAPIEndpointId = Hide-APIEndpoint -APIEndpointID $NewAPIEndpointByParam.apiEndpointId @SafeCommonParams
    it 'Hide-APIEndpoint (id) returns the correct data' {
        $HideAPIEndpointId.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    ### Hide-APIEndpoint - Parameter Set 'name'
    $Script:HideAPIEndpointName = Hide-APIEndpoint -APIEndpointName $NewAPIEndpointByPipeline.apiEndpointName @SafeCommonParams
    it 'Hide-APIEndpoint (name) returns the correct data' {
        $HideAPIEndpointName.apiEndpointId | Should -Be $NewAPIEndpointByPipeline.apiEndpointId
    }

    ### Show-APIEndpoint - Parameter Set 'id'
    $Script:ShowAPIEndpointId = Show-APIEndpoint -APIEndpointID $NewAPIEndpointByParam.apiEndpointId @SafeCommonParams
    it 'Show-APIEndpoint (id) returns the correct data' {
        $ShowAPIEndpointId.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    ### Show-APIEndpoint - Parameter Set 'name'
    $Script:ShowAPIEndpointName = Show-APIEndpoint -APIEndpointName $NewAPIEndpointByPipeline.apiEndpointName @SafeCommonParams
    it 'Show-APIEndpoint (name) returns the correct data' {
        $ShowAPIEndpointName.apiEndpointId | Should -Be $NewAPIEndpointByPipeline.apiEndpointId
    }

    #------------------------------------------------
    #                 APIEndpointDetails                  
    #------------------------------------------------

    ### Expand-APIEndpointDetails
    $Script:ExpandAPIEndpointDetailsID, $Script:ExpandAPIEndpointDetailsVersion = Expand-APIEndpointDetails -APIEndpointName $NewAPIEndpointByParam.apiEndpointName -VersionNumber latest @SafeCommonParams
    it 'Expand-APIEndpointDetails returns the correct data' {
        $ExpandAPIEndpointDetailsID | Should -Be $NewAPIEndpointByParam.apiEndpointId
        $ExpandAPIEndpointDetailsVersion | Should -Be $NewAPIEndpointByParam.versionNumber
    }

    #------------------------------------------------
    #                 APIEndpointVersion                  
    #------------------------------------------------

    ### New-APIEndpointVersion
    $Script:NewAPIEndpointVersion = New-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -CloneVersionNumber 1 @SafeCommonParams
    it 'New-APIEndpointVersion returns the correct data' {
        $NewAPIEndpointVersion.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    ### Get-APIEndpointVersion - All'
    $Script:GetAPIEndpointVersionIdAll = Get-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId @SafeCommonParams
    it 'Get-APIEndpointVersion - All returns the correct data' {
        $GetAPIEndpointVersionIdAll[0].versionNumber | Should -Match '[\d]'
    }

    ### Get-APIEndpointVersion - Single'
    $Script:GetAPIEndpointVersionSingle = Get-APIEndpointVersion -APIEndpointName $NewAPIEndpointByParam.apiEndpointName -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersion - Single returns the correct data' {
        $GetAPIEndpointVersionSingle.versionNumber | Should -Be 1 
    }

    ### Set-APIEndpointVersion - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionByParam = Set-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body ($GetAPIEndpointVersionSingle | ConvertTo-Json -Depth 10) -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersion by param returns the correct data' {
        $SetAPIEndpointVersionByParam.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    ### Hide-APIEndpointVersion - Parameter Set 'id'
    $Script:HideAPIEndpointVersionId = Hide-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Hide-APIEndpointVersion (id) returns the correct data' {
        $HideAPIEndpointVersionId.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    ### Show-APIEndpointVersion - Parameter Set 'id'
    $Script:ShowAPIEndpointVersionId = Show-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Show-APIEndpointVersion (id) returns the correct data' {
        $ShowAPIEndpointVersionId.apiEndpointId | Should -Be $NewAPIEndpointByParam.apiEndpointId
    }

    #------------------------------------------------
    #                 APIEndpointVersionCache                  
    #------------------------------------------------

    ### Get-APIEndpointVersionCache
    $Script:GetAPIEndpointVersionCache = Get-APIEndpointVersionCache -APIEndpointId $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionCache returns the correct data' {
        $GetAPIEndpointVersionCache.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionCache - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionCacheByParam = Set-APIEndpointVersionCache -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionCache -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionCache by param returns the correct data' {
        $SetAPIEndpointVersionCacheByParam.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionCache - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionCacheByPipeline = ($GetAPIEndpointVersionCache | Set-APIEndpointVersionCache -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionCache by pipeline returns the correct data' {
        $SetAPIEndpointVersionCacheByPipeline.enabled | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionCORS                  
    #------------------------------------------------

    ### Get-APIEndpointVersionCORS
    $Script:GetAPIEndpointVersionCORS = Get-APIEndpointVersionCORS -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionCORS returns the correct data' {
        $GetAPIEndpointVersionCORS.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionCORS - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionCORSByParam = Set-APIEndpointVersionCORS -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionCORS -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionCORS (id) by param returns the correct data' {
        $SetAPIEndpointVersionCORSByParam.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionCORS - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionCORSByPipeline = ($GetAPIEndpointVersionCORS | Set-APIEndpointVersionCORS -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionCORS (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionCORSByPipeline.enabled | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionErrorResponses                  
    #------------------------------------------------

    ### Get-APIEndpointVersionErrorResponses - Parameter Set 'id'
    $Script:GetAPIEndpointVersionErrorResponses = Get-APIEndpointVersionErrorResponses -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionErrorResponses (id) returns the correct data' {
        $GetAPIEndpointVersionErrorResponses.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionErrorResponses - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionErrorResponsesByParam = Set-APIEndpointVersionErrorResponses -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionErrorResponses -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionErrorResponses (id) by param returns the correct data' {
        $SetAPIEndpointVersionErrorResponsesByParam.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionErrorResponses - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionErrorResponsesByPipeline = ($GetAPIEndpointVersionErrorResponses | Set-APIEndpointVersionErrorResponses -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionErrorResponses (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionErrorResponsesByPipeline.QUOTA_EXCEEDED | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionErrorResponseType                  
    #------------------------------------------------

    ### Set-APIEndpointVersionErrorResponseType - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionErrorResponseType = Set-APIEndpointVersionErrorResponseType -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $TestAPIResponseType -Type "API_KEY_INVALID" -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionErrorResponseType returns the correct data' {
        $SetAPIEndpointVersionErrorResponseType.statusCode | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionGraphQL                  
    #------------------------------------------------

    ### Get-APIEndpointVersionGraphQL
    $Script:GetAPIEndpointVersionGraphQL = Get-APIEndpointVersionGraphQL -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionGraphQL (id) returns the correct data' {
        $GetAPIEndpointVersionGraphQL.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionGraphQL by parameter
    $Script:SetAPIEndpointVersionGraphQLByParam = Set-APIEndpointVersionGraphQL -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionGraphQL -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionGraphQL (id) by param returns the correct data' {
        $SetAPIEndpointVersionGraphQLByParam.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionGraphQL by pipeline
    $Script:SetAPIEndpointVersionGraphQLByPipeline = ($GetAPIEndpointVersionGraphQL | Set-APIEndpointVersionGraphQL -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionGraphQL (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionGraphQLByPipeline.enabled | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionGZip                  
    #------------------------------------------------

    ### Get-APIEndpointVersionGZip - Parameter Set 'id'
    $Script:GetAPIEndpointVersionGZip = Get-APIEndpointVersionGZip -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionGZip returns the correct data' {
        $GetAPIEndpointVersionGZip.compressResponse | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionGZip by parameter
    $Script:SetAPIEndpointVersionGZipByParam = Set-APIEndpointVersionGZip -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionGZip -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionGZip by param returns the correct data' {
        $SetAPIEndpointVersionGZipByParam.compressResponse | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionGZip by pipeline
    $Script:SetAPIEndpointVersionGZipByPipeline = ($GetAPIEndpointVersionGZip | Set-APIEndpointVersionGZip -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionGZip by pipeline returns the correct data' {
        $SetAPIEndpointVersionGZipByPipeline.compressResponse | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionJWT                  
    #------------------------------------------------

    ### Get-APIEndpointVersionJWT - Parameter Set 'id'
    $Script:GetAPIEndpointVersionJWT = Get-APIEndpointVersionJWT -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionJWT (id) returns the correct data' {
        $GetAPIEndpointVersionJWT.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionJWT by parameter
    $Script:SetAPIEndpointVersionJWTIdByParam = Set-APIEndpointVersionJWT -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionJWT -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionJWT by param returns the correct data' {
        $SetAPIEndpointVersionJWTIdByParam.enabled | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionJWT by pipeline
    $Script:SetAPIEndpointVersionJWTIdByPipeline = ($GetAPIEndpointVersionJWT | Set-APIEndpointVersionJWT -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionJWT by pipeline returns the correct data' {
        $SetAPIEndpointVersionJWTIdByPipeline.enabled | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionPrivacy                  
    #------------------------------------------------

    ### Get-APIEndpointVersionPrivacy
    $Script:GetAPIEndpointVersionPrivacy = Get-APIEndpointVersionPrivacy -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionPrivacy returns the correct data' {
        $GetAPIEndpointVersionPrivacy.public | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionPrivacy by parameter
    $Script:SetAPIEndpointVersionPrivacyByParam = Set-APIEndpointVersionPrivacy -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $GetAPIEndpointVersionPrivacy -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionPrivacy by param returns the correct data' {
        $SetAPIEndpointVersionPrivacyByParam.public | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionPrivacy by pipeline
    $Script:SetAPIEndpointVersionPrivacyByPipeline = ($GetAPIEndpointVersionPrivacy | Set-APIEndpointVersionPrivacy -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionPrivacy by pipeline returns the correct data' {
        $SetAPIEndpointVersionPrivacyByPipeline.public | Should -Not -BeNullOrEmpty
    }

    # #------------------------------------------------
    # #                 APIEndpointVersionResource                  
    # #------------------------------------------------

    ### New-APIEndpointVersionResource by parameter
    $Script:NewAPIEndpointVersionResourceByParam = New-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $TestAPIResource1 -VersionNumber 1 @SafeCommonParams
    it 'New-APIEndpointVersionResource by param returns the correct data' {
        $NewAPIEndpointVersionResourceByParam.apiResourceName | Should -Be $TestAPIResourceName1
    }

    ### New-APIEndpointVersionResource by pipeline
    $Script:NewAPIEndpointVersionResourceByPipeline = ($TestAPIResource2 | New-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'New-APIEndpointVersionResource by pipeline returns the correct data' {
        $NewAPIEndpointVersionResourceByPipeline.apiResourceName | Should -Be $TestAPIResourceName2
    }

    ### Get-APIEndpointVersionResource, all
    $Script:GetAPIEndpointVersionResourceAll = Get-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionResource, all returns the correct data' {
        $GetAPIEndpointVersionResourceAll[0].apiResourceName | Should -Not -BeNullOrEmpty
    }

    ### Get-APIEndpointVersionResource, single
    $Script:GetAPIEndpointVersionResourceSingle = Get-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionResource, single returns the correct data' {
        $GetAPIEndpointVersionResourceSingle.apiResourceId | Should -Be $NewAPIEndpointVersionResourceByParam.apiResourceId
    }

    ### Set-APIEndpointVersionResource by parameter
    $Script:SetAPIEndpointVersionResourceByParam = Set-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceByParam.apiResourceId -Body $NewAPIEndpointVersionResourceByParam -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionResource by param returns the correct data' {
        $SetAPIEndpointVersionResourceByParam.apiResourceId | Should -Be $NewAPIEndpointVersionResourceByParam.apiResourceId
    }

    ### Set-APIEndpointVersionResource - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionResourceByPipeline = ($NewAPIEndpointVersionResourceByParam | Set-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionResource by pipeline returns the correct data' {
        $SetAPIEndpointVersionResourceByPipeline.apiResourceId | Should -Be $NewAPIEndpointVersionResourceByParam.apiResourceId
    }

    #------------------------------------------------
    #        APIEndpointVersionResourceOperation
    #------------------------------------------------

    # Set apiResourceId
    $TestAPIResourceOperation.apiResourceId = $NewAPIEndpointVersionResourceByParam.apiResourceId

    ### New-APIEndpointVersionResourceOperation
    $Script:NewAPIEndpointVersionResourceOperation = New-APIEndpointVersionResourceOperation -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceByParam.apiResourceId -Body $TestAPIResourceOperation -VersionNumber 1 @SafeCommonParams
    it 'New-APIEndpointVersionResourceOperation returns the correct data' {
        $NewAPIEndpointVersionResourceOperation.operationId | Should -Not -BeNullOrEmpty
    }

    ### Get-APIEndpointVersionResourceOperation
    $Script:GetAPIEndpointVersionResourceOperationId = Get-APIEndpointVersionResourceOperation -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionResourceOperation (id) returns the correct data' {
        $GetAPIEndpointVersionResourceOperationId.operationId | Should -Be $NewAPIEndpointVersionResourceOperation.operationId
    }

    ### Set-APIEndpointVersionResourceOperation by parameter
    $Script:SetAPIEndpointVersionResourceOperationIdByParam = Set-APIEndpointVersionResourceOperation -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceOperation.apiResourceId -Body $GetAPIEndpointVersionResourceOperationId -OperationID $NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionResourceOperation (id) by param returns the correct data' {
        $SetAPIEndpointVersionResourceOperationIdByParam.operationId | Should -Be $NewAPIEndpointVersionResourceOperation.operationId
    }

    ### Set-APIEndpointVersionResourceOperation by pipeline
    $Script:SetAPIEndpointVersionResourceOperationIdByPipeline = ($GetAPIEndpointVersionResourceOperationId | Set-APIEndpointVersionResourceOperation -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionResourceOperation (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionResourceOperationIdByPipeline.operationId | Should -Be $NewAPIEndpointVersionResourceOperation.operationId
    }

    #------------------------------------------------
    #                 APIEndpointVersionRouting                  
    #------------------------------------------------

    ### Set-APIEndpointVersionRouting - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionRoutingIdByParam = Set-APIEndpointVersionRouting -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -Body $TestAPIRoutingJSON -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionRouting (id) by param returns the correct data' {
        $SetAPIEndpointVersionRoutingIdByParam.rules | Should -Not -BeNullOrEmpty
    }
    
    ### Set-APIEndpointVersionRouting - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionRoutingIdByPipeline = ($TestAPIRouting | Set-APIEndpointVersionRouting -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionRouting (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionRoutingIdByPipeline.rules | Should -Not -BeNullOrEmpty
    }
    
    ### Get-APIEndpointVersionRouting - Parameter Set 'id'
    $Script:GetAPIEndpointVersionRoutingId = Get-APIEndpointVersionRouting -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionRouting (id) returns the correct data' {
        $GetAPIEndpointVersionRoutingId.rules | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionSummary                  
    #------------------------------------------------

    ### Get-APIEndpointVersionSummary - Parameter Set 'id'
    $Script:GetAPIEndpointVersionSummaryId = Get-APIEndpointVersionSummary -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionSummary (id) returns the correct data' {
        $GetAPIEndpointVersionSummaryId.apiVersionId | Should -Not -BeNullOrEmpty
    }

    ### Get-APIEndpointVersionSummary - Parameter Set 'name'
    $Script:GetAPIEndpointVersionSummaryName = Get-APIEndpointVersionSummary -APIEndpointName $NewAPIEndpointByParam.apiEndpointName -VersionNumber 1 @SafeCommonParams
    it 'Get-APIEndpointVersionSummary (name) returns the correct data' {
        $GetAPIEndpointVersionSummaryName.apiVersionId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIHostnames                  
    #------------------------------------------------

    ### Get-APIHostnames
    $Script:GetAPIHostnames = Get-APIHostnames -ContractID $TestContract -GroupID $TestGroupID @SafeCommonParams
    it 'Get-APIHostnames returns the correct data' {
        $GetAPIHostnames.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 APIHostnamesAndGroups                  
    #------------------------------------------------

    ### Get-APIHostnamesAndGroups
    $Script:GetAPIHostnamesAndGroups = Get-APIHostnamesAndGroups -ContractID $TestContract -GroupID $TestGroupID @SafeCommonParams
    it 'Get-APIHostnamesAndGroups returns the correct data' {
        $GetAPIHostnamesAndGroups[0].acgId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIOperations                  
    #------------------------------------------------

    ### Get-APIOperations
    $Script:GetAPIOperations = Get-APIOperations @SafeCommonParams
    it 'Get-APIOperations returns the correct data' {
        $GetAPIOperations.apiEndPoints | Should -Not -BeNullOrEmpty
    }

    $TestAPIOperationsBody = @{
        operations = @(
            @{ 
                apiEndPointId      = $GetAPIOperations.operations[0].apiEndpointId
                apiResourceLogicId = $GetAPIOperations.operations[0].apiResourceLogicId
                operationId        = $GetAPIOperations.operations[0].operationId
            }
        )
    }

    ### Test-APIOperations by parameter
    $Script:TestAPIOperationsByParam = Test-APIOperations -Body $TestAPIOperationsBody @SafeCommonParams
    it 'Test-APIOperations by param returns the correct data' {
        $TestAPIOperationsByParam.apiEndPoints | Should -Not -BeNullOrEmpty
    }

    ### Test-APIOperations by pipeline
    $Script:TestAPIOperationsByPipeline = ($TestAPIOperationsBody | Test-APIOperations @SafeCommonParams)
    it 'Test-APIOperations by pipeline returns the correct data' {
        $TestAPIOperationsByPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIUserEntitlements                  
    #------------------------------------------------

    ### Get-APIUserEntitlements
    $Script:GetAPIUserEntitlements = Get-APIUserEntitlements -ContractID $TestContract -GroupID $TestGroupId @SafeCommonParams
    it 'Get-APIUserEntitlements returns the correct data' {
        $GetAPIUserEntitlements.count | Should -BeGreaterThan 0
    }

    #------------------------------------------------
    #                 APIOperationsQuery                  
    #------------------------------------------------

    ### New-APIOperationsQuery by parameter
    $Script:NewAPIOperationsQueryByParam = New-APIOperationsQuery -Body $TestAPIQuery @SafeCommonParams
    it 'New-APIOperationsQuery by param returns the correct data' {
        $NewAPIOperationsQueryByParam.apiEndPoints | Should -Not -BeNullOrEmpty
    }

    ### New-APIOperationsQuery by pipeline
    $Script:NewAPIOperationsQueryByPipeline = ($TestAPIQuery | New-APIOperationsQuery @SafeCommonParams)
    it 'New-APIOperationsQuery by pipeline returns the correct data' {
        $NewAPIOperationsQueryByPipeline.apiEndPoints | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointFromFile                  
    #------------------------------------------------
    
    ### New-APIEndpointFromFile by attributes
    $Script:NewAPIEndpointFromFileByAttr = New-APIEndpointFromFile -ImportFileFormat swagger -ImportFileSource BODY_BASE64 -ImportFileContent $TestEncodedSwaggerContent -ContractID $TestContract -GroupID $TestGroupID @SafeCommonParams
    it 'New-APIEndpointFromFile by attributes returns the correct data' {
        $NewAPIEndpointFromFileByAttr.apiEndpointId | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionFromFile                  
    #------------------------------------------------

    ### Set-APIEndpointVersionFromFile by attributes
    $Script:SetAPIEndpointVersionFromFileIdByAttr = Set-APIEndpointVersionFromFile -APIEndpointID $NewAPIEndpointFromFileByAttr.apiEndpointId -VersionNumber 1 -ImportFileFormat swagger -ImportFileSource BODY_BASE64 -ImportFileContent $TestEncodedSwaggerContent -ContractID $TestContract -GroupID $TestGroupID @SafeCommonParams
    it 'Set-APIEndpointVersionFromFile by attributes returns the correct data' {
        $SetAPIEndpointVersionFromFileIdByAttr.apiEndPointId | Should -Be $NewAPIEndpointFromFileByAttr.apiEndpointId
    }

    ### Set-APIEndpointVersionFromFile - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionFromFileIdByPipeline = ($TestAPIFromFileJSON | Set-APIEndpointVersionFromFile -APIEndpointID $NewAPIEndpointFromFileByAttr.apiEndpointId -VersionNumber 1 @SafeCommonParams)
    it 'Set-APIEndpointVersionFromFile by pipeline returns the correct data' {
        $SetAPIEndpointVersionFromFileIdByPipeline.apiEndPointId | Should -Be $NewAPIEndpointFromFileByAttr.apiEndpointId
    }

    ### Set-APIEndpointVersionFromFile - Parameter Set 'name', by parameter
    $Script:SetAPIEndpointVersionFromFileNameByParam = Set-APIEndpointVersionFromFile -APIEndpointID $NewAPIEndpointFromFileByAttr.apiEndpointId -Body $TestAPIFromFile -VersionNumber 1 @SafeCommonParams
    it 'Set-APIEndpointVersionFromFile by param returns the correct data' {
        $SetAPIEndpointVersionFromFileNameByParam.apiEndPointId | Should -Be $NewAPIEndpointFromFileByAttr.apiEndpointId
    }

    #------------------------------------------------
    #                 APICategory                  
    #------------------------------------------------

    ### New-APICategory
    $Script:NewAPICategory = New-APICategory -APICategoryName $TestAPICategoryName @SafeCommonParams
    it 'New-APICategory returns the correct data' {
        $NewAPICategory.apiCategoryName | Should -Be $TestAPICategoryName
    }

    ### Get-APICategory - Parameter Set 'single'
    $Script:GetAPICategorySingle = Get-APICategory -APICategoryID $NewAPICategory.apiCategoryId @SafeCommonParams
    it 'Get-APICategory (single) returns the correct data' {
        $GetAPICategorySingle.apiCategoryName | Should -Be $TestAPICategoryName
    }

    ### Get-APICategory - Parameter Set 'all'
    $Script:GetAPICategoryAll = Get-APICategory @SafeCommonParams
    it 'Get-APICategory (all) returns the correct data' {
        $GetAPICategoryAll[0].apiCategoryId | Should -Not -BeNullOrEmpty
    }

    ### Set-APICategory
    $Script:SetAPICategory = Set-APICategory -APICategoryID $NewAPICategory.apiCategoryId -APICategoryName $TestAPICategoryName @SafeCommonParams
    it 'Set-APICategory returns the correct data' {
        $SetAPICategory.apiCategoryId | Should -Be $NewAPICategory.apiCategoryId
    }

    ### Remove-APICategory
    it 'Remove-APICategory throws no errors' {
        { Remove-APICategory -APICategoryID $NewAPICategory.apiCategoryId @SafeCommonParams } | Should -Not -Throw
    }

    
    #------------------------------------------------
    #                 Removals                  
    #------------------------------------------------

    ### Remove-APIEndpointVersionResourceOperation
    it 'Remove-APIEndpointVersionResourceOperation throws no errors' {
        { Remove-APIEndpointVersionResourceOperation -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceOperation.apiResourceId -OperationID $NewAPIEndpointVersionResourceOperation.operationId -VersionNumber 1 @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-APIEndpointVersionResource - Parameter Set 'id'
    it 'Remove-APIEndpointVersionResource (id) throws no errors' {
        { Remove-APIEndpointVersionResource -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -APIResourceID $NewAPIEndpointVersionResourceByParam.apiResourceId -VersionNumber 1 @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-APIEndpointVersionResource - Parameter Set 'name'
    it 'Remove-APIEndpointVersionResource (name) returns the correct data' {
        { Remove-APIEndpointVersionResource -APIEndpointName $NewAPIEndpointByParam.apiEndpointName -APIResourceID $NewAPIEndpointVersionResourceByPipeline.apiResourceId -VersionNumber 1 @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-APIEndpointVersion
    it 'Remove-APIEndpointVersion throws no errors' {
        { Remove-APIEndpointVersion -APIEndpointID $NewAPIEndpointByParam.apiEndpointId -VersionNumber latest @SafeCommonParams } | Should -Not -Throw
    }

    ### Remove-APIEndpoint
    it 'Remove-APIEndpoint throws no errors' {
        { Remove-APIEndpoint -APIEndpointID $NewAPIEndpointByParam.apiEndpointId @SafeCommonParams } | Should -Not -Throw
        { Remove-APIEndpoint -APIEndpointID $NewAPIEndpointByPipeline.apiEndpointId @SafeCommonParams } | Should -Not -Throw
        { Remove-APIEndpoint -APIEndpointID $CopyAPIEndpointByParam.apiEndpointId @SafeCommonParams } | Should -Not -Throw
        { Remove-APIEndpoint -APIEndpointID $CopyAPIEndpointByPipeline.apiEndpointId @SafeCommonParams } | Should -Not -Throw
        { Remove-APIEndpoint -APIEndpointID $NewAPIEndpointFromFileByAttr.apiEndpointId @SafeCommonParams } | Should -Not -Throw
    }

    AfterAll {
        
    }

}


Describe 'Unsafe Akamai.APIDefinitions Tests' {

    #------------------------------------------------
    #                 APIEndpointVersionPII                  
    #------------------------------------------------

    ### Get-APIEndpointVersionPII - Parameter Set 'id'
    $Script:GetAPIEndpointVersionPII = Get-APIEndpointVersionPII -APIEndpointID 123456 -VersionNumber 1 @UnsafeCommonParams
    it 'Get-APIEndpointVersionPII (id) returns the correct data' {
        $GetAPIEndpointVersionPII.constraints | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionPII - Parameter Set 'id', by parameter
    $Script:SetAPIEndpointVersionPIIIdByParam = Set-APIEndpointVersionPII -APIEndpointID 123456 -Body $GetAPIEndpointVersionPII -VersionNumber 1 @UnsafeCommonParams
    it 'Set-APIEndpointVersionPII (id) by param returns the correct data' {
        $SetAPIEndpointVersionPIIIdByParam.constraints | Should -Not -BeNullOrEmpty
    }

    ### Set-APIEndpointVersionPII - Parameter Set 'id', by pipeline
    $Script:SetAPIEndpointVersionPIIIdByPipeline = ($GetAPIEndpointVersionPII | Set-APIEndpointVersionPII -APIEndpointID 123456 -VersionNumber 1 @UnsafeCommonParams)
    it 'Set-APIEndpointVersionPII (id) by pipeline returns the correct data' {
        $SetAPIEndpointVersionPIIIdByPipeline.constraints | Should -Not -BeNullOrEmpty
    }

    ### Update-APIEndpointVersionPII - Parameter Set 'id'
    $Script:UpdateAPIEndpointVersionPIIId = Update-APIEndpointVersionPII -APIEndpointID 123456 -PIIID 123456 -Status DISCOVERED -VersionNumber 1 @UnsafeCommonParams
    it 'Update-APIEndpointVersionPII (id) returns the correct data' {
        $UpdateAPIEndpointVersionPIIId.id | Should -Not -BeNullOrEmpty
    }

    ### Remove-APIEndpointVersionPII
    it 'Remove-APIEndpointVersionPII throws no errors' {
        { Remove-APIEndpointVersionPII -APIEndpointID 123456 -PIIID 123456 -VersionNumber 1 @UnsafeCommonParams } | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionPIIParams                  
    #------------------------------------------------

    ### Get-APIEndpointVersionPIIParams - Parameter Set 'id'
    $Script:GetAPIEndpointVersionPIIParamsId = Get-APIEndpointVersionPIIParams -APIEndpointID 123456 -VersionNumber 1 @UnsafeCommonParams
    it 'Get-APIEndpointVersionPIIParams (id) returns the correct data' {
        $GetAPIEndpointVersionPIIParamsId[0].id | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointVersionPIIParameters                  
    #------------------------------------------------

    ### Set-APIEndpointVersionPIIParam - Parameter Set 'id'
    it 'Set-APIEndpointVersionPIIParam throws no errors' {
        { Set-APIEndpointVersionPIIParameters -APIEndpointID 123456 -VersionNumber 1 -Body $TestPIIParamJSON @UnsafeCommonParams } | Should -Not -Throw
    }

    #------------------------------------------------
    #                 APIEndpointActivation                  
    #------------------------------------------------

    ### New-APIEndpointActivation - Parameter
    $Script:NewAPIEndpointActivationByParam = New-APIEndpointActivation -APIEndpointID 123456 -Body $TestAPIActivationJSON -VersionNumber 1 @UnsafeCommonParams
    it 'New-APIEndpointActivation by param returns the correct data' {
        $NewAPIEndpointActivationByParam.networks | Should -Not -BeNullOrEmpty
    }

    ### New-APIEndpointActivation - Pipeline
    $Script:NewAPIEndpointActivationByPipeline = ($TestAPIActivationJSON | New-APIEndpointActivation -APIEndpointID 123456 -VersionNumber 1 @UnsafeCommonParams)
    it 'New-APIEndpointActivation by pipeline returns the correct data' {
        $NewAPIEndpointActivationByPipeline.networks | Should -Not -BeNullOrEmpty
    }

    ### New-APIEndpointActivation - Attributes
    $Script:NewAPIEndpointActivationByAttributes = New-APIEndpointActivation -APIEndpointID 123456 -Networks Staging -Notes 'Some notes' -NotificationRecipients 'mail@example.com' -VersionNumber 1 @UnsafeCommonParams
    it 'New-APIEndpointActivation by attributes returns the correct data' {
        $NewAPIEndpointActivationByAttributes.networks | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointDeactivation                  
    #------------------------------------------------

    ### New-APIEndpointDeactivation - Parameter Set 'id-body, name-body', by parameter
    $Script:NewAPIEndpointDeactivationIdBodynameBodyByParam = New-APIEndpointDeactivation -APIEndpointID 123456 -Body $TestAPIActivationJSON -VersionNumber 1 @UnsafeCommonParams
    it 'New-APIEndpointDeactivation (id-body, name-body) by param returns the correct data' {
        $NewAPIEndpointDeactivationIdBodynameBodyByParam.networks | Should -Not -BeNullOrEmpty
    }

    ### New-APIEndpointDeactivation - Parameter Set 'id-body, name-body', by pipeline
    $Script:NewAPIEndpointDeactivationIdBodynameBodyByPipeline = ($TestAPIActivationJSON | New-APIEndpointDeactivation -APIEndpointID 123456 -VersionNumber 1 @UnsafeCommonParams)
    it 'New-APIEndpointDeactivation (id-body, name-body) by pipeline returns the correct data' {
        $NewAPIEndpointDeactivationIdBodynameBodyByPipeline.networks | Should -Not -BeNullOrEmpty
    }

    ### New-APIEndpointDeactivation - Parameter Set 'id-attributes, name-attributes'
    $Script:NewAPIEndpointDeactivationIdAttributesnameAttributes = New-APIEndpointDeactivation -APIEndpointID 123456 -Networks Staging -Notes 'Some notes' -NotificationRecipients 'mail@example.com' -VersionNumber 1 @UnsafeCommonParams
    it 'New-APIEndpointDeactivation (id-attributes, name-attributes) returns the correct data' {
        $NewAPIEndpointDeactivationIdAttributesnameAttributes.networks | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APISecureConnection                  
    #------------------------------------------------

    ### Test-APISecureConnection by parameter
    $Script:TestAPISecureConnectionByParam = Test-APISecureConnection -Body $TestAPISecureJSON @UnsafeCommonParams
    it 'Test-APISecureConnection by param returns the correct data' {
        $TestAPISecureConnectionByParam.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
    }

    ### Test-APISecureConnection by pipeline
    $Script:TestAPISecureConnectionByPipeline = ($TestAPISecureJSON | Test-APISecureConnection @UnsafeCommonParams)
    it 'Test-APISecureConnection by pipeline returns the correct data' {
        $TestAPISecureConnectionByPipeline.'bookstore.api.akamai.com'.Title | Should -Not -BeNullOrEmpty
    }

    #------------------------------------------------
    #                 APIEndpointFromFile                  
    #------------------------------------------------

    ### New-APIEndpointFromFile by parameter
    $Script:NewAPIEndpointFromFileByBody = New-APIEndpointFromFile -Body $TestAPIFromFileJSON @UnsafeCommonParams
    it 'New-APIEndpointFromFile by param returns the correct data' {
        $NewAPIEndpointFromFileByBody.apiEndpointId | Should -Not -BeNullOrEmpty
    }

    ### New-APIEndpointFromFile by pipeline
    $Script:NewAPIEndpointFromFileByPipeline = ($TestAPIFromFile | New-APIEndpointFromFile @UnsafeCommonParams)
    it 'New-APIEndpointFromFile by pipeline returns the correct data' {
        $NewAPIEndpointFromFileByPipeline.apiEndpointId | Should -Not -BeNullOrEmpty
    }
}