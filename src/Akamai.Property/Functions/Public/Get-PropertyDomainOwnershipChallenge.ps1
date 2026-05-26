function Get-PropertyDomainOwnershipChallenge {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Hostname,

        [Parameter()]
        [switch]
        $RefreshToken,

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
        $CollatedHostnames = New-Object System.Collections.Generic.List[string]
    }

    process {
        $Hostname | ForEach-Object {
            $CollatedHostnames.Add($_)
        }
    }

    end {
        $Path = "/papi/v1/domain-challenges"
        $QueryParameters = @{
            'refreshToken' = $RefreshToken.IsPresent
        }
        $Body = @{
            'hostnames' = $CollatedHostnames
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
            'Body'             = $Body
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.hostnames
    }
}