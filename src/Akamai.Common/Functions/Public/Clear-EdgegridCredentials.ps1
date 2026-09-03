function Clear-EdgegridCredentials {
    [CmdletBinding()]
    Param()

    process {
        $Keys = 'ACCESS_TOKEN', 'CLIENT_TOKEN', 'CLIENT_SECRET', 'HOST', 'ACCOUNT_KEY'
        foreach ($Key in $Keys) {
            Get-ChildItem -Path "Env:\AKAMAI_*$Key" | ForEach-Object {
                Write-Debug "Removing environment variable: $($_.Name)"
                $_ | Remove-Item
            }
        }
    }
}