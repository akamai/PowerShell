function Get-PropertyCertificateChallenge {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string[]]
        $CnamesFrom,

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
        $CollatedCNAMEs = New-Object System.Collections.Generic.List[string]
    }

    process {
        $CnamesFrom | ForEach-Object {
            $CollatedCNAMEs.Add($_)
        }
    }

    end {
        $Path = "/papi/v1/hostnames/certificate-challenges"
        $Body = @{
            cnamesFrom = $CollatedCNAMEs
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
        return $Response.Body.hostnames.items
    }
}
