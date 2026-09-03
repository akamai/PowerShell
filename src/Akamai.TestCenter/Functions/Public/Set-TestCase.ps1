function Set-TestCase {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ValueFromPipeline)]
        $Body,
        
        [Parameter()]
        [switch]
        $IncludeStatus,

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
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases = New-Object -TypeName System.Collections.Generic.List['object']
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedCases.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/test-cases"
        if ($CollatedCases.count -gt 0) {
            $Body = $CollatedCases
        }
        # Add array wrapper if missing
        else {
            $Body = Get-BodyObject -Source $Body
            if ($Body -isnot 'Array') {
                $Body = @($Body)
            }
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($TestCase in $Body) {
            $TestCase.PSObject.Members.Remove('createdDate')
            $TestCase.PSObject.Members.Remove('modifiedDate')
        }
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}
