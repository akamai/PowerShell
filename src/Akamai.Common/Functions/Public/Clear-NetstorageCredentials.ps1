function Clear-NetstorageCredentials {
    [CmdletBinding()]
    Param()

    process {
        $Keys = 'CPCODE', 'GROUP', 'HOST', 'ID', 'KEY'
        foreach ($Key in $Keys) {
            Get-ChildItem -Path "Env:\NETSTORAGE_*$Key" | ForEach-Object {
                Write-Debug "Removing environment variable: $($_.Name)"
                $_ | Remove-Item
            }
        }
    }
}