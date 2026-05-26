function New-IAMAPICredential {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $ClientID = 'self',

        [Parameter()]
        [switch]
        $APIResponseOnly,

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

    process {
        if ($ClientID -eq 'self') {
            $Path = "/identity-management/v3/api-clients/self/credentials"
        }
        else {
            $Path = "/identity-management/v3/api-clients/$ClientID/credentials"
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        try {
            $Response = Invoke-AkamaiRequest @RequestParams
            # Unless user specifies, we should hydrate the response to include all creds for easier storage
            if (-not $APIResponseOnly) {
                if ($ClientID -eq 'self') {
                    try {
                        $EdgeGridCredentials = Get-EdgegridCredentials -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
                        $Response.body | Add-Member -MemberType NoteProperty -Name 'accessToken' -Value $EdgeGridCredentials.AccessToken
                        $Response.body | Add-Member -MemberType NoteProperty -Name 'host' -Value $EdgeGridCredentials.Host
                    }
                    catch {
                        Write-Warning "Failed to retrieve EdgeGrid credentials. Output will not include accessToken and host: $_"
                    }
                }
                else {
                    try {
                        $Client = Get-IAMAPIClient -ClientID $ClientID -EdgeRCFile $EdgeRCFile -Section $Section -AccountSwitchKey $AccountSwitchKey
                        Write-Debug ($Client | ConvertTo-Json -Depth 5)
                        $Response.body | Add-Member -MemberType NoteProperty -Name 'accessToken' -Value $Client.accessToken
                        $Response.body | Add-Member -MemberType NoteProperty -Name 'Host' -Value $Client.baseURL.Replace("https://", "")
                    }
                    catch {
                        Write-Warning "Failed to retrieve API Client details. Output will not include accessToken and host: $_"
                    }
                }
            }
            return $Response.Body
        }
        catch {
            throw $_
        }
    }
}
