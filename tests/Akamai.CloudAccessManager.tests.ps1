BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Cloud Access Manager Tests' {

    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.CloudAccessManager'
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
        $TestKeyNameBody = "AkamaiPowershell-$Timestamp-body"
        $TestKeyNameAttr = "AkamaiPowershell-$Timestamp-attr"
        $TestKeyVersion = 1
        $TestNewKeyBody = @"
{
    "credentials": {
            "cloudAccessKeyId": "AKAMAICAMKEYID1EXAMPLE",
            "cloudSecretAccessKey": "cDblrAMtnIAxN/g7dF/bAxLfiANAXAMPLEKEY"
    },
    "authenticationMethod": "AWS4_HMAC_SHA256",
    "networkConfiguration": {
            "securityNetwork": "STANDARD_TLS"
    },
    "accessKeyName": "$TestKeyNameBody",
    "contractId": "$TestContractID",
    "groupId": $TestGroupID
}
"@ | ConvertFrom-Json
        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.CloudAccessManager"
        $PD = @{}
    }

    AfterAll {
        $KeysToDelete = Get-CloudAccessKey @CommonParams | Where-Object accessKeyName -in $TestKeyNameBody, $TestKeyNameAttr
        if ($KeysToDelete) {
            $VersionsToDelete = $KeysToDelete | Get-CloudAccessKeyVersion @CommonParams

            if ($VersionsToDelete) {
                while ('PENDING_ACTIVATION' -in $VersionsToDelete.deploymentStatus) {
                    Start-Sleep -s 30
                    $VersionsToDelete = $KeysToDelete | Get-CloudAccessKeyVersion @CommonParams
                    Write-Host -ForegroundColor Yellow "Waiting for PENDING_ACTIVATION versions to become ACTIVE before deletion..."
                }

                while ('PENDING_DELETION' -in $VersionsToDelete.deploymentStatus) {
                    Start-Sleep -s 30
                    $VersionsToDelete = $KeysToDelete | Get-CloudAccessKeyVersion @CommonParams
                    Write-Host -ForegroundColor Yellow "Waiting for PENDING_DELETION versions to be deleted..."
                }

                $VersionsToDelete | Remove-CloudAccessKeyVersion @CommonParams

                $VersionsRemain = $true
                while ($VersionsRemain) {
                    $VersionsRemain = $false
                    # Loop through keys and find versions. If none remain, we are done
                    $KeysToDelete | foreach-object {
                        $TestParams = @{
                            'AccessKeyUID' = $_.accessKeyUid
                        }
                        $Versions = Get-CloudAccessKeyVersion @TestParams @CommonParams
                        if ($Versions) { $VersionsRemain = $true }
                    }
                    Write-Host -ForegroundColor Yellow "Waiting for PENDING_DELETION versions to be deleted..."
                    Start-Sleep -s 30
                }

                $KeysToDelete | Remove-CloudAccessKey @CommonParams
                while ($KeysToDelete) {
                    Write-Host -ForegroundColor Yellow "Waiting for key deletion to complete..."
                    Start-Sleep -s 10
                    $KeysToDelete = Get-CloudAccessKey @CommonParams | Where-Object accessKeyName -in $TestKeyNameBody, $TestKeyNameAttr
                }
            }
        }
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-CloudAccessKey' {
        It 'creates a key by body' {
            $TestParams = @{
                'Body' = $TestNewKeyBody
            }
            $PD.NewKeyBody = New-CloudAccessKey @TestParams @CommonParams
            $PD.NewKeyBody.requestId | Should -Not -BeNullOrEmpty

            # Pause for a few seconds to stagger creation requests
            Start-Sleep -Seconds 5
        }
        It 'creates a key by attributes' {
            $TestParams = @{
                'AccessKeyName'        = $TestKeyNameAttr
                'AuthenticationMethod' = 'AWS4_HMAC_SHA256'
                'CloudAccessKeyId'     = 'AKAMAICAMKEYID1EXAMPLE'
                'CloudSecretAccessKey' = 'cDblrAMtnIAxN/g7dF/bAxLfiANAXAMPLEKEY'
                'ContractId'           = $TestContractID
                'GroupID'              = $TestGroupID
                'SecurityNetwork'      = 'STANDARD_TLS'
            }
            $PD.NewKeyAttr = New-CloudAccessKey @TestParams @CommonParams
            $PD.NewKeyAttr.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-CloudAccessKeyCreateRequest' {
        It 'completes successfully' {
            $TestParams = @{
                'RequestID' = $PD.NewKeyAttr.requestId
            }
            $PD.CreateRequest = Get-CloudAccessKeyCreateRequest @TestParams @CommonParams
            $PD.CreateRequest.requestId | Should -Be $PD.NewKeyAttr.requestId
            $PD.CreateRequest.request.accessKeyName | Should -Be $TestKeyNameAttr

            # Wait for request to complete
            while ($PD.CreateRequest.processingStatus -eq 'IN_PROGRESS') {
                Write-Host -ForegroundColor Yellow "Waiting for key creation to complete..."
                Start-Sleep -s 10
                $TestParams = @{
                    'RequestID' = $PD.NewKeyAttr.requestId
                }
                $PD.CreateRequest = Get-CloudAccessKeyCreateRequest @TestParams @CommonParams
            }

            # If creation has failed, panic.
            if ($PD.CreateRequest.processingStatus -ne 'DONE') {
                throw "Key creation did not complete successfully. Status: $($PD.CreateRequest.processingStatus)"
            }

            $PD.KeyUID = $PD.CreateRequest.accessKey.accessKeyUid
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CloudAccessKeyCreateRequest
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CloudAccessKey' {
        It 'returns a list' {
            $PD.Keys = Get-CloudAccessKey @CommonParams
            $PD.Keys.count | Should -Not -BeNullOrEmpty
        }
        It 'returns the right key by ID' {
            $PD.Key = $PD.KeyUID | Get-CloudAccessKey @CommonParams
            $PD.Key.accessKeyName | Should -Be $TestKeyNameAttr
        }
    }

    Context 'Get-CloudAccessKeyVersion' {
        It 'returns a list' {
            $PD.Versions = $PD.KeyUID | Get-CloudAccessKeyVersion @CommonParams
            $PD.Versions[0].version | Should -Be 1
            $PD.Versions[0].versionGuid | Should -Not -BeNullOrEmpty
        }
        It 'returns the right version' {
            $PD.Version = $PD.Versions[0] | Get-CloudAccessKeyVersion @CommonParams
            $PD.Version.version | Should -Be $PD.Versions[0].Version
            $PD.Version.versionGuid | Should -Be $PD.Versions[0].versionGuid
        }
        It 'pauses for version creation to complete before we create a new one' {
            while ($PD.Version.deploymentStatus -ne 'ACTIVE') {
                Write-Host -ForegroundColor Yellow "Waiting for version to become ACTIVE..."
                Start-Sleep -s 30
                $PD.Version = $PD.Version | Get-CloudAccessKeyVersion @CommonParams
            }
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CloudAccessKeyVersion
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Get-CloudAccessKeyVersionProperties' {
        It 'returns a list' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Get-CloudAccessKeyVersionProperties.json"
                return $Response | ConvertFrom-Json
            }
            $TestParams = @{
                'AccessKeyUID' = 12345
                'Version'      = 1
            }
            $PD.Properties = Get-CloudAccessKeyVersionProperties @TestParams
            $PD.Properties[0].propertyId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-CloudAccessLookup' {
        It 'returns the correct data' {
            $PD.Lookup = $PD.Version | New-CloudAccessLookup @CommonParams
            $PD.Lookup.lookupId | Should -Not -BeNullOrEmpty
            # Pause for long enough to allow the lookup to complete
            Start-Sleep -Seconds $PD.Lookup.retryAfter
        }
    }

    Context 'Get-CloudAccessLookup' {
        It 'returns the correct data' {
            $PD.LookupResult = $PD.Lookup | Get-CloudAccessLookup @CommonParams
            $PD.LookupResult.lookupId | Should -Be $PD.Lookup.lookupId
            $PD.LookupResult.lookupStatus | Should -BeIn 'IN_PROGRESS', 'COMPLETE'
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CloudAccessLookup
            $Result | Should -Not -Be 'IAR executed'
        }
    }


    Context 'New-CloudAccessKeyVersion' {
        It 'completes successfully' {
            $TestParams = @{
                'CloudAccessKeyID'     = 'AKAMAICAMKEYID2EXAMPLE2'
                'CloudSecretAccessKey' = 'cDdrcAMtrIAvN/h7dF/bAxLfiANAXAMPLEKEY'
            }
            $PD.NewVersion = $PD.Key | New-CloudAccessKeyVersion @TestParams @CommonParams
            $PD.NewVersion.requestId | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Rename-CloudAccessKey' {
        It 'renames successfully by parameter' {
            $TestParams = @{
                'AccessKeyUID'  = $PD.Key.accessKeyUid
                'AccessKeyName' = $TestKeyNameAttr
            }
            $PD.Rename = Rename-CloudAccessKey @TestParams @CommonParams
            $PD.Rename.accessKeyUID | Should -Be $PD.Key.accessKeyUid
            $PD.Rename.AccessKeyName | Should -Be $TestKeyNameAttr
        }
        It 'renames successfully by pipeline' {
            $TestParams = @{
                'AccessKeyName' = $TestKeyNameAttr
            }
            $Rename = $PD.Key | Rename-CloudAccessKey @TestParams @CommonParams
            $Rename.accessKeyUID | Should -Be $PD.Key.accessKeyUid
            $Rename.AccessKeyName | Should -Be $TestKeyNameAttr
        }
    }

    Context 'Get-CloudAccessKeyVersionCreateRequest' {
        It 'completes successfully' {
            $PD.VersionCreateRequest = $PD.NewVersion | Get-CloudAccessKeyVersionCreateRequest @CommonParams

            # Wait for request to complete
            while ($PD.VersionCreateRequest.processingStatus -ne 'DONE') {
                Start-Sleep -s 10
                $PD.VersionCreateRequest = $PD.NewVersion | Get-CloudAccessKeyVersionCreateRequest @CommonParams
            }

            $PD.VersionCreateRequest.accessKeyVersion.accessKeyUid | Should -Be $PD.Key.accessKeyUid
            $PD.VersionCreateRequest.accessKeyVersion.version | Should -Be 2
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Get-CloudAccessKeyVersionCreateRequest
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-CloudAccessKeyVersion' {
        It 'completes successfully' {
            $KeysToDelete = Get-CloudAccessKey @CommonParams | Where-Object accessKeyName -in $TestKeyNameBody, $TestKeyNameAttr
            $VersionsToDelete = $KeysToDelete | Get-CloudAccessKeyVersion @CommonParams
            while ('PENDING_ACTIVATION' -in $VersionsToDelete.deploymentStatus) {
                Start-Sleep -s 30
                $VersionsToDelete = $KeysToDelete | Get-CloudAccessKeyVersion @CommonParams
                Write-Host -ForegroundColor Yellow "Waiting for PENDING_ACTIVATION versions to become ACTIVE before deletion..."
            }

            $RemoveVersions = $VersionsToDelete | Remove-CloudAccessKeyVersion @CommonParams
            $RemoveVersions.deploymentStatus | Get-Unique | Should -Be 'PENDING_DELETION'

            $VersionsRemain = $true
            while ($VersionsRemain) {
                $VersionsRemain = $false
                # Loop through keys and find versions. If none remain, we are done
                $KeysToDelete | foreach-object {
                    $TestParams = @{
                        'AccessKeyUID' = $_.accessKeyUid
                    }
                    $Versions = Get-CloudAccessKeyVersion @TestParams @CommonParams
                    if ($Versions) { $VersionsRemain = $true }
                }

                if (-not $VersionsRemain) { break }

                Write-Host -ForegroundColor Yellow "Waiting for all versions to be deleted..."
                Start-Sleep -s 30
            }
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-CloudAccessKeyVersion
            $Result | Should -Not -Be 'IAR executed'
        }
    }

    Context 'Remove-CloudAccessKey' {
        It 'deletes successfully' {
            $KeysToDelete = Get-CloudAccessKey @CommonParams | Where-Object accessKeyName -in $TestKeyNameBody, $TestKeyNameAttr
            $KeysToDelete | Remove-CloudAccessKey @CommonParams
            while ($KeysToDelete) {
                Write-Host -ForegroundColor Yellow "Waiting for key deletion to complete..."
                Start-Sleep -s 10
                $KeysToDelete = Get-CloudAccessKey @CommonParams | Where-Object accessKeyName -in $TestKeyNameBody, $TestKeyNameAttr
            }
        }
        It 'handles empty input correctly' {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.CloudAccessManager -MockWith { return 'IAR executed' }
            $Result = & {} | Remove-CloudAccessKey
            $Result | Should -Not -Be 'IAR executed'
        }
    }
}

