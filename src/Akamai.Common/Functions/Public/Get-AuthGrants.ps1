function Get-AuthGrants {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [switch]
        $ReturnObject,

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section,

        [Parameter()]
        [string]
        $AccountSwitchKey
    )

    $Path = "/-/client-api/active-grants/implicit"

    try {
        $Response = Invoke-AkamaiRequest -Method GET -Path $Path -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
        if ($ReturnObject) {
            return $Response.Body
        }
        Write-Host "Credential Name: '$($Response.Body.name)'."
        Write-Host "---------------------------------"
        Write-Host "Created $($Response.Body.Created) by '$($Response.Body.CreatedBy)'."
        Write-Host "Updated $($Response.Body.Updated) by '$($Response.Body.UpdatedBy)'."
        Write-Host "Activated $($Response.Body.Activated) by '$($Response.Body.ActivatedBy)'."
        Write-Host "Grants:"
        
        $Scope = $Response.Body.Scope.Split(" ")
        $Grants = New-Object System.Collections.ArrayList
        foreach ($Grant in $Scope) {
            $Grant = $Grant.Replace("https://luna.akamaiapis.net/-/scope/", "")
            $Grant = $Grant.Replace("/-/", ": ")
            $Grants.Add("    $Grant") | Out-Null
        }
        $Grants
    }
    catch {
        throw $_
    }
}
