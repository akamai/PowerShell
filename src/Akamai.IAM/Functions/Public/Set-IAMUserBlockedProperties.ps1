function Set-IAMUserBlockedProperties {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $UIIdentityID,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

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
            $CombinedProperties = New-Object -TypeName System.Collections.ArrayList
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $CombinedProperties.Add($Body) | Out-Null
        }
    }

    end {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $Body = $CombinedProperties
        }

        $Path = "/identity-management/v3/user-admin/ui-identities/$UIIdentityID/groups/$GroupID/blocked-properties"
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
