function Restore-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int64[]]
        $KeyIDs,

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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }

    end {
        $Path = "/apikey-manager-api/v2/keys/restore"
        $Body = @{
            'keyIds' = $CollatedKeys
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
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}

