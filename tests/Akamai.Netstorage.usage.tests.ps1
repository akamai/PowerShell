BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.Netstorage Usage Tests' {
    BeforeAll { 
        Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
        Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
        # Setup shared variables
        $CommonParams = @{
            AuthFile = $env:PesterAuthFile
        }
        $TestDirectory = "ns-usage-temp"
        $TestNewDirName = "temp"
        $TestNewFileName = "temp.txt"
        $TestNewFileContent = "new"
        $TestSymlinkFileName = "symlink.txt"
        $TestRenamedFileName = "renamed.txt"
        $TestCPCodeID = $env:PesterNSCpCode
        $PD = @{}
    }

    AfterAll {
        if ((Test-Path $TestNewFileName)) {
            Remove-Item $TestNewFileName -Force
        }
        if ((Test-Path $TestDirectory)) {
            Remove-Item $TestDirectory -Recurse -Force
        }
    }

    Context 'New-NetstorageDirectory' {
        It 'creates successfully' {
            $PD.NewDir = New-NetstorageDirectory -Path "/$TestDirectory/$TestNewDirName" @CommonParams
            $PD.NewDir | Should -Match 'successful'
        }
    }

    Context 'Write-NetstorageObject' {
        It 'throws no errors' {
            $TestNewFileContent | Set-Content $TestNewFileName
            Write-NetstorageObject -LocalPath $TestNewFileName -RemotePath "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams 
            Write-NetstorageObject -LocalPath $TestNewFileName -RemotePath "/$TestDirectory/$TestNewFileName" @CommonParams 
        }
    }

    Context 'Get-NetstorageDirectory without recursion (dir)' {
        It 'lists content' {
            $PD.Dir = Get-NetstorageDirectory -Path $TestDirectory @CommonParams
            $PD.Dir[0].type | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-NetstorageDirectory with recursion (list)' {
        It 'lists content' {
            $PD.List = Get-NetstorageDirectory -Path $TestDirectory -Recurse @CommonParams
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
            $PD.Usage = Get-NetstorageDirectoryUsage -Path $TestDirectory @CommonParams
            $PD.Usage.files | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-NetstorageSymlink' {
        It 'creates a symlink' {
            $PD.Symlink = New-NetstorageSymlink -Path "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName" -Target "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams
            $PD.Symlink | Should -Match 'successful'
        }
    }

    Context 'Read-NetstorageObject' {
        It 'downloads successfully' {
            Read-NetstorageObject -RemotePath "/$TestDirectory/$TestNewDirName/$TestNewFileName" -LocalPath $TestNewFileName @CommonParams 
            $PD.DownloadedContent = Get-Content $TestNewFileName
            $PD.DownloadedContent | Should -Be $TestNewFileContent
        }
    }
    
    Context 'Read-NetstorageDirectory' {
        It 'downloads a whole directory successfully' {
            Read-NetstorageDirectory -Path $TestDirectory -OutputDirectory $TestDirectory -Recurse @CommonParams 
            $DownloadedFiles = Get-ChildItem $TestDirectory
            $DownloadedFiles.count | Should -BeGreaterThan 0
            $TestCPCodeID | Should -BeIn $DownloadedFiles.Name
        }
    }

    Context 'Set-NetstorageObjectMTime' {
        It 'sets mtime' {
            $PD.MTime = Set-NetstorageObjectMTime -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" -mtime 0 @CommonParams
            $PD.MTime | Should -Match 'successful'
        }
    }

    Context 'Measure-NetstorageObject' {
        It 'gets object stats' {
            $PD.Stat = Measure-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" @CommonParams
            $PD.Stat.name | Should -Be $TestNewFileName
        }
    }

    Context 'Rename-NetstorageObject' {
        It 'renames a file' {
            $PD.Rename = Rename-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestNewFileName" -NewFilename $TestRenamedFileName @CommonParams
            $PD.Rename | Should -Match 'renamed'
        }
    }

    Context 'Remove-NetstorageObject' {
        It 'removes a file' {
            $PD.RemoveFile = Remove-NetstorageObject -Path "/$TestDirectory/$TestNewDirName/$TestSymlinkFileName" @CommonParams
            $PD.RemoveFile | Should -Match 'deleted'
        }
    }

    Context 'Remove-NetstorageDirectory' {
        It 'removes a dir' {
            $PD.RemoveDir = Remove-NetstorageDirectory -Path "/$TestDirectory/$TestNewDirName" -Force @CommonParams
            $PD.RemoveDir | Should -Match "quick-delete scheduled"
        }
    }
}
