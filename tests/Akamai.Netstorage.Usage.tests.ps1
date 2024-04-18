Import-Module $PSScriptRoot/../src/Akamai.Common/Akamai.Common.psd1 -Force
Import-Module $PSScriptRoot/../src/Akamai.Netstorage/Akamai.Netstorage.psd1 -Force
# Setup shared variables
$Script:TestDirectory = "akamaipowershell"
$Script:AuthFile = $env:PesterAuthFile
$Script:NewDirName = "temp"
$Script:NewFileName = "temp.txt"
$Script:NewFileContent = "new"
$Script:SymlinkFileName = "symlink.txt"
$Script:RenamedFileName = "renamed.txt"

Describe 'Safe NSAPI Tests' {
    BeforeDiscovery {
        
    }

    ### New-NetstorageDirectory
    $Script:NewDir = New-NetstorageDirectory -Path "/$TestDirectory/$NewDirName" -AuthFile $AuthFile
    it 'New-NetstorageDirectory creates successfully' {
        $NewDir | Should -Match 'successful'
    }

    ### Write-NetstorageObject
    $NewFileContent | Set-Content $NewFileName
    it 'Write-NetstorageObject lists content' {
        { Write-NetstorageObject -LocalPath $NewFileName -RemotePath "/$TestDirectory/$NewDirName/$NewFileName" -AuthFile $AuthFile } | Should -Not -Throw
    }

    ### Get-NetstorageDirectory
    $Script:Dir = Get-NetstorageDirectory -Path $TestDirectory -AuthFile $AuthFile
    it 'Get-NetstorageDirectory lists content' {
        $Dir[0].type | Should -Not -BeNullOrEmpty
    }

    ### Get-NetstorageDirectory with recursion (ls)
    $Script:Dir = Get-NetstorageDirectory -Path $TestDirectory -Recurse -AuthFile $AuthFile
    it 'Get-NetstorageDirectory lists content' {
        ($Dir | Where-Object type -eq file | Select-Object -First 1).size | Should -Not -BeNullOrEmpty
    }

    ### Get-NetstorageDirectoryUsage
    $Script:Usage = Get-NetstorageDirectoryUsage -Path $TestDirectory -AuthFile $AuthFile
    it 'Get-NetstorageDirectoryUsage returns stats' {
        $Usage.files | Should -Not -BeNullOrEmpty
    }

    ### Symlink-NetstorageObject
    $Script:Symlink = New-NetstorageSymlink -Path "/$TestDirectory/$NewDirName/$SymlinkFileName" -Target "/$TestDirectory/$NewDirName/$NewFileName" -AuthFile $AuthFile
    it 'New-NetstorageSymlink creates a symlink' {
        $Symlink | Should -Match 'successful'
    }

    ### Read-NetstorageObject
    it 'Read-NetstorageObject downloads successfully' {
        { Read-NetstorageObject -RemotePath "/$TestDirectory/$NewDirName/$NewFileName" -LocalPath $NewFileName -AuthFile $AuthFile } | Should -Not -Throw
        $DownloadedContent = Get-Content $NewFileName
        $DownloadedContent | Should -Be $NewFileContent
    }

    ### Set-NetstorageObjectMTime
    $Script:MTime = Set-NetstorageObjectMTime -Path "/$TestDirectory/$NewDirName/$NewFileName" -mtime 0 -AuthFile $AuthFile
    it 'Set-NetstorageObjectMTime sets mtime' {
        $MTime | Should -Match 'successful'
    }

    ### Measure-NetstorageObject
    $Script:Stat = Measure-NetstorageObject -Path "/$TestDirectory/$NewDirName/$NewFileName" -AuthFile $AuthFile
    it 'Measure-NetstorageObject gets object stats' {
        $Stat.name | Should -Be $NewFileName
    }

    ### Rename-NetstorageObject
    $Script:Rename = Rename-NetstorageObject -Path "/$TestDirectory/$NewDirName/$NewFileName" -NewFilename $RenamedFileName -AuthFile $AuthFile
    it 'Rename-NetstorageObject renames a file' {
        $Rename | Should -Match 'renamed'
    }

    ### Remove-NetstorageObject
    $Script:RemoveFile = Remove-NetstorageObject -Path "/$TestDirectory/$NewDirName/$SymlinkFileName" -AuthFile $AuthFile
    it 'Remove-NetstorageObject removes a file' {
        $RemoveFile | Should -Match 'deleted'
    }

    ### Remove-NetstorageDirectory
    $Script:RemoveDir = Remove-NetstorageDirectory -Path "/$TestDirectory/$NewDirName" -Force -AuthFile $AuthFile
    it 'Remove-NetstorageDirectory removes a dir' {
        $RemoveDir | Should -Match "quick-delete scheduled"
    }

    AfterAll {
        Remove-Item $NewFileName -Force
    }
}