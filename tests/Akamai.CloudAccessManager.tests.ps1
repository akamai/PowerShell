Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.CloudAccessManager/Akamai.CloudAccessManager.psd1 -Force
# Setup shared variables
$Script:EdgeRCFile = $env:PesterEdgeRCFile
$Script:SafeEdgeRCFile = $env:PesterSafeEdgeRCFile
$Script:Section = $env:PesterEdgeRCSection
$Script:TestContract = $env:PesterContractID
$Script:TestKeyName = 'AkamaiPowershell'
$Script:TestKeyVersion = 1
$Script:TestNewKeyBody = '{
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
$Script:TestNewKeyObject = ConvertFrom-Json $TestNewKeyBody

Describe 'Safe Cloud Access Manager Tests' {

    BeforeDiscovery {

    }

    ### Get-CloudAccessKeys, all
    $Script:Keys = Get-CloudAccessKey -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessKeys, all returns a list' {
        $Keys.count | Should -Not -BeNullOrEmpty
    }

    # Find test key
    $Script:KeyUID = ($Keys | Where-Object accessKeyName -eq $TestKeyName).accessKeyUid
    if ($null -eq $KeyUID) {
        throw "Unable to find key $TestKeyName. Bailing out"
    }

    ### Get-CloudAccessKey, single
    $Script:Key = Get-CloudAccessKey -AccessKeyUID $KeyUID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessKey, single returns the right key' {
        $Key.accessKeyName | Should -Be $TestKeyName
    }

    ### Get-CloudAccessKeyVersions, all
    $Script:Versions = Get-CloudAccessKeyVersion -AccessKeyUID $KeyUID -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessKeyVersions, all returns a list' {
        $Versions.count | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudAccessKeyVersion, single
    $Script:Version = Get-CloudAccessKeyVersion -AccessKeyUID $KeyUID -Version $TestKeyVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessKeyVersion, single returns the right version' {
        $Version.version | Should -Be $TestKeyVersion
    }

    ### Get-CloudAccessKeyVersionProperties
    $Script:Properties = Get-CloudAccessKeyVersionProperties -AccessKeyUID $KeyUID -Version $TestKeyVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessKeyVersionProperties returns a list' {
        $Properties[0].propertyId | Should -Not -BeNullOrEmpty
    }

    ### New-CloudAccessLookup
    $Script:Lookup = New-CloudAccessLookup -AccessKeyUID $KeyUID -Version $TestKeyVersion -EdgeRCFile $EdgeRCFile -Section $Section
    it 'New-CloudAccessLookup returns the corect data' {
        $Lookup.lookupId | Should -Not -BeNullOrEmpty
    }

    # Pause for long enough to allow the lookup to complete
    Start-Sleep -Seconds $Lookup.retryAfter

    ### Get-CloudAccessLookup
    $Script:LookupResult = Get-CloudAccessLookup -LookupID $Lookup.lookupId -EdgeRCFile $EdgeRCFile -Section $Section
    it 'Get-CloudAccessLookup returns the corect data' {
        $LookupResult.properties[0].accessKeyUid | Should -Be $KeyUID
    }

    AfterAll {
        
    }
    
}

Describe 'Unsafe Cloud Access Manager Tests' {
    ### New-CloudAccessKey by param
    $Script:NewKeyByParam = New-CloudAccessKey -Body $TestNewKeyBody -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudAccessKey by param completes successfully' {
        $NewKeyByParam.requestId | Should -Not -BeNullOrEmpty
    }

    ### New-CloudAccessKey by pipeline
    $Script:NewKeyByPipeline = $TestNewKeyObject | New-CloudAccessKey -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudAccessKey by pipeline completes successfully' {
        $NewKeyByPipeline.requestId | Should -Not -BeNullOrEmpty
    }

    ### Get-CloudAccessKeyCreateRequest
    $Script:CreateRequest = Get-CloudAccessKeyCreateRequest -RequestID 12345 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Get-CloudAccessKeyCreateRequest completes successfully' {
        $CreateRequest.accessKeyVersion.accessKeyUid | Should -Not -BeNullOrEmpty
    }

    ### New-CloudAccessKeyVersion
    $Script:NewVersion = New-CloudAccessKeyVersion -AccessKeyUID $KeyUID -CloudAccessKeyID 123456789 -CloudSecretAccessKey 123456789 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'New-CloudAccessKeyVersion completes successfully' {
        $NewVersion.requestId | Should -Not -BeNullOrEmpty
    }

    ### Remove-CloudAccessKeyVersion
    $Script:RemoveVersion = Remove-CloudAccessKeyVersion -AccessKeyUID $KeyUID -Version 2 -EdgeRCFile $SafeEdgeRCFile -Section $Section
    it 'Remove-CloudAccessKeyVersion completes successfully' {
        $RemoveVersion.deploymentStatus | Should -Not -BeNullOrEmpty
    }
    
}
