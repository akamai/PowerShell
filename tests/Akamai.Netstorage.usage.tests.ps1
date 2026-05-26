BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Netstorage Usage Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.Netstorage'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Create custom NSRC for the tests
        $CredentialsParams = @{
            UploadAccountID = 'pester'
            EdgeRCFile      = $env:PesterEdgeRCFile
            Section         = $env:PesterEdgeRCSection
        }
        New-NetstorageCredentials @CredentialsParams | Export-NetstorageCredentials -NSRCFile 'TestDrive:/.nsrc'

        # Setup shared variables
        $CommonParams = @{
            'NSRCFile' = 'TestDrive:/.nsrc'
        }
        $TestDirectory = "ns-usage-temp-$Timestamp"
        $TestNewDirName = "temp"
        $TestNewFileName = "temp.txt"
        $TestNewFileContent = "new"
        $TestSymlinkFileName = "symlink.txt"
        $TestRenamedFileName = "renamed.txt"
        $TestCPCodeID = $env:PesterNSCpCode
        $PD = @{}
    }

    AfterAll {
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-NetstorageDirectory' {
        It 'creates successfully' {
            $TestParams = @{
                'Path' = "/$TestDirectory/$TestNewDirName"
            }
            $PD.NewDir = New-NetstorageDirectory @TestParams @CommonParams
            $PD.NewDir | Should -Match 'successful'
        }
    }

    Context 'Write-NetstorageObject' {
        BeforeAll {
            $TestNewFileContent | Set-Content "TestDrive:/$TestNewFileName"
            Compress-Archive -Path "TestDrive:/$TestNewFileName" -DestinationPath "TestDrive:/$TestNewFileName.zip"
        }
        It 'uploads a file successfully' {
            $TestParams = @{
                'LocalPath'  = "TestDrive:/$TestNewFileName"
                'RemotePath' = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
            }
            Write-NetstorageObject @TestParams @CommonParams
        }
        It 'uploads an object with index-zip' {
            $TestParams = @{
                'LocalPath'  = "TestDrive:/$TestNewFileName.zip"
                'RemotePath' = "/$TestDirectory/$TestNewDirName/$TestNewFileName.zip"
                'IndexZip'   = $true
            }
            Write-NetstorageObject @TestParams @CommonParams
        }
    }

    Context 'Get-NetstorageDirectory' {
        It 'lists content without recursion (dir)' {
            $TestParams = @{
                'Path' = "$TestDirectory/$TestNewDirName"
            }
            $PD.Dir = Get-NetstorageDirectory @TestParams @CommonParams
            $PD.Dir[0].type | Should -Not -BeNullOrEmpty
        }
        It 'lists content with recursion (list)' {
            $TestParams = @{
                'Path'    = "$TestDirectory/$TestNewDirName"
                'Recurse' = $true
            }
            $PD.List = Get-NetstorageDirectory @TestParams @CommonParams
            ($PD.List | Where-Object type -eq file | Select-Object -First 1).size | Should -Not -BeNullOrEmpty
            $MatchingPrefix = $true
            $PD.List.Name | ForEach-Object {
                if (-not $_.StartsWith("$TestCPCodeID/$TestDirectory")) {
                    Write-Host "File = $_"
                    $MatchingPrefix = $false
                }
            }
            $MatchingPrefix | Should -Be $true
        }
    }

    Context 'Get-NetstorageDirectoryUsage' {
        It 'returns stats' {
            $TestParams = @{
                'Path' = $TestDirectory
            }
            $PD.Usage = Get-NetstorageDirectoryUsage @TestParams @CommonParams
            $PD.Usage.files | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageSymlink' {
        It 'creates a symlink' {
            $TestParams = @{
                'Path'   = "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName"
                'Target' = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
            }
            $PD.Symlink = New-NetstorageSymlink @TestParams @CommonParams
            $PD.Symlink | Should -Match 'successful'
        }
    }

    Context 'Read-NetstorageObject' {
        It 'downloads successfully' {
            $TestParams = @{
                'RemotePath' = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
                'LocalPath'  = "TestDrive:/$TestNewFileName"
            }
            Read-NetstorageObject @TestParams @CommonParams
            "TestDrive:/$TestNewFileName" | Should -FileContentMatch $TestNewFileContent
        }
    }
    
    Context 'Read-NetstorageDirectory' {
        It 'downloads a whole directory successfully' {
            $TestParams = @{
                'Path'            = "$TestDirectory/$TestNewDirName"
                'OutputDirectory' = "TestDrive:/$TestDirectory/$TestNewDirName"
                'Recurse'         = $true
            }
            Read-NetstorageDirectory @TestParams @CommonParams
            $DownloadedFiles = Get-ChildItem "TestDrive:/$TestDirectory/$TestNewDirName"
            $DownloadedFiles.count | Should -BeGreaterThan 0
            $TestCPCodeID | Should -BeIn $DownloadedFiles.Name
        }
    }

    Context 'Set-NetstorageObjectMTime' {
        It 'sets mtime' {
            $TestParams = @{
                'Path'  = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
                'mtime' = 0
            }
            $PD.MTime = Set-NetstorageObjectMTime @TestParams @CommonParams
            $PD.MTime | Should -Match 'successful'
        }
    }

    Context 'Measure-NetstorageObject' {
        It 'gets object stats' {
            $TestParams = @{
                'Path' = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
            }
            $PD.Stat = Measure-NetstorageObject @TestParams @CommonParams
            $PD.Stat.name | Should -Be $TestNewFileName
        }
    }

    Context 'Rename-NetstorageObject' {
        It 'renames a file' {
            $TestParams = @{
                'Path'        = "/$TestDirectory/$TestNewDirName/$TestNewFileName"
                'NewFilename' = $TestRenamedFileName
            }
            $PD.Rename = Rename-NetstorageObject @TestParams @CommonParams
            $PD.Rename | Should -Match 'renamed'
        }
    }

    Context 'Remove-NetstorageObject' {
        It 'removes a file' {
            $TestParams = @{
                'Path' = "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName"
            }
            $PD.RemoveFile = Remove-NetstorageObject @TestParams @CommonParams
            $PD.RemoveFile | Should -Match 'deleted'
        }
    }

    Context 'Remove-NetstorageDirectory' {
        It 'removes a dir' {
            $TestParams = @{
                'Path'  = "/$TestDirectory/$TestNewDirName"
                'Force' = $true
            }
            $PD.RemoveDir = Remove-NetstorageDirectory @TestParams @CommonParams
            $PD.RemoveDir | Should -Match "quick-delete scheduled"
        }
    }
}
