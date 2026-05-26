function Block-IAMPropertyUsers {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Alias('PropertyID')]
        [int]
        $AssetID,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $UIIdentityID,

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
            $CollatedIDs = New-Object -TypeName System.Collections.ArrayList
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            $CollatedIDs.Add($UIIdentityID) | Out-Null
        }
    }

    end {
        $Body = New-Object -TypeName System.Collections.ArrayList
        if (!$PSCmdlet.MyInvocation.ExpectingInput) {
            $CollatedIDs = $UIIdentityID
        }
        $CollatedIDs | ForEach-Object {
            $Body.Add(@{ "uiIdentityId" = $_ }) | Out-Null
        }
        
        $Path = "/identity-management/v3/user-admin/properties/$AssetID/users/block"
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


