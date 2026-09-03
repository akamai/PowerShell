function Clear-AkamaiCache {
    [CmdletBinding(DefaultParameterSetName = 'URL')]
    Param(
        [Parameter(ParameterSetName = 'URL', Mandatory)]
        [string[]]
        $URLs,

        [Parameter(ParameterSetName = 'CP code', Mandatory)]
        [int[]]
        $CPCodes,

        [Parameter(ParameterSetName = 'Tag', Mandatory)]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateSet('invalidate', 'delete')]
        [string]
        $Method = 'invalidate',

        [Parameter()]
        [ValidateSet('staging', 'production')]
        [string]
        $Network = 'production',

        [Parameter()]
        [string]
        $EdgeRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'URL') {
            $Objects = $URLs
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CP code') {
            $Objects = $CPCodes
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Tag') {
            $Objects = $Tags
        }
        $Body = @{ 'objects' = $Objects }

        # Construct request path
        $Method = $Method.ToLower()
        $Network = $Network.ToLower()
        switch ($PSCmdlet.ParameterSetName) {
            'URL' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/url/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/url/$Network"
                    }
                }
            }
            'CP code' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/cpcode/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/cpcode/$Network"
                    }
                }
            }
            'Tag' {
                switch ($Method) {
                    'invalidate' {
                        $Path = "/ccu/v3/invalidate/tag/$Network"
                    }
                    'delete' {
                        $Path = "/ccu/v3/delete/tag/$Network"
                    }
                }
            }
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