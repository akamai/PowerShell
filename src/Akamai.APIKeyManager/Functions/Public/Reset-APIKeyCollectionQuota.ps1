function Reset-APIKeyCollectionQuota {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int64]
        $CollectionID,
        
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
        $CollatedKeys = New-Object -TypeName System.Collections.Generic.List['int64']
    }

    process {
        foreach ($KeyID in $KeyIDs) {
            $CollatedKeys.Add($KeyID)
        }
    }
    
    end {
        $Path = "/apikey-manager-api/v2/collections/$CollectionID/quota-reset"
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

