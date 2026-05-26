function Set-IAMUserGroupAndRole {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UiIdentityID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,

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

    begin {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $CombinedAuthGrantsArray = New-Object -TypeName System.Collections.ArrayList
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $CombinedAuthGrantsArray.Add($Body) | Out-Null
        }
    }

    end {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $Body = $CombinedAuthGrantsArray
        }

        $Path = "/identity-management/v3/user-admin/ui-identities/$UiIdentityID/auth-grants"
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}


