function Set-TestVariable {
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
            $CollatedVariables = New-Object -TypeName System.Collections.Generic.List['object']
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -and $Body -isnot 'String') {
            $CollatedVariables.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables"
        if ($CollatedVariables.count -gt 0) {
            $Body = $CollatedVariables
        }
        # Add array wrapper if missing
        else {
            $Body = Get-BodyObject -Source $Body
            if ($Body -isnot 'Array') {
                $Body = @($Body)
            }
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($Variable in $Body) {
            $Variable.PSObject.Members.Remove('createdDate')
            $Variable.PSObject.Members.Remove('modifiedDate')
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
