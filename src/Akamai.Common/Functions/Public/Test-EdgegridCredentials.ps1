function Test-EdgegridCredentials {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('host')]
        [string]
        $HostName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ClientToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $AccessToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ClientSecret

    )

    $EdgegridCredentialMatch = '^aka[ab]-[a-z0-9]{16}-[a-z0-9]{16}'
    $SecretMatch = '[a-zA-Z0-9\+\/=]{44}'
    $Status = New-Object -Typename System.Collections.Generic.List[string]

    if ($HostName -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'Host' attribute of your credentials appears to be invalid")
    }
    if ($ClientToken -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'ClientToken' attribute of your credentials appears to be invalid")
    }
    if ($AccessToken -notmatch $EdgegridCredentialMatch) {
        $Status.Add("The 'AccessToken' attribute of your credentials appears to be invalid")
    }
    if ($ClientSecret -notmatch $SecretMatch) {
        $Status.Add("The 'ClientSecret' attribute of your credentials appears to be invalid")
    }

    return $Status
}
