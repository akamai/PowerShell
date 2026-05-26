function Remove-NetstorageDirectory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $DirectoryIsEmpty,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        if ($DirectoryIsEmpty) {
            $Action = 'rmdir'
            $Body = ''
            $AdditionalOptions = @{}
        }
    
        else {
            if (!$Force) {
                $Sure = Read-Host "This operation will delete the directory $Path with no further confirmation. Are you really, really sure?[y/n]"
                if ($Sure.ToLower() -ne "y") {
                    Write-Host -ForegroundColor "Red" "Delete cancelled."
                    return
                }
            }
        
            $Action = 'quick-delete'
            $Body = ''
            $AdditionalOptions = @{
                'quick-delete' = 'imreallyreallysure'
            }
        }   
    
        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'Body'              = $Body
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}