function New-TestVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]
        $TestSuiteID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Single variable')]
        [Parameter(Mandatory, ParameterSetName = 'Attributes - Variable group')]
        [string]
        $VariableName,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Single variable')]
        [string]
        $VariableValue,

        [Parameter(Mandatory, ParameterSetName = 'Attributes - Variable group')]
        [hashtable[]]
        $VariableGroupValue,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'POST body')]
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
        $CollatedVariables = New-Object -TypeName System.Collections.Generic.List['object']
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'POST body' -and $Body -isnot 'String') {
            $CollatedVariables.Add($Body)
        }
    }

    end {
        $Path = "/test-management/v3/functional/test-suites/$TestSuiteID/variables"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes - Single variable') {
            $Body = @(
                @{
                    'variableName'  = $VariableName
                    'variableValue' = $VariableValue
                }
            )
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Attributes - Variable group') {
            $Body = @(
                @{
                    'variableName'       = $VariableName
                    'variableGroupValue' = $VariableGroupValue
                }
            )
        }
        elseif ($CollatedVariables.count -gt 0) {
            $Body = $CollatedVariables
        }
        
        # Add array wrapper if missing
        $Body = Get-BodyObject -Source $Body
        if ($Body -isnot 'Array') {
            $Body = @($Body)
        }

        # Remove date-based elements, which confuse the API due to a JSON conversion bug
        foreach ($Variable in $Body) {
            $Variable.PSObject.Members.Remove('createdDate')
            $Variable.PSObject.Members.Remove('modifiedDate')
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
        if ($IncludeStatus) {
            return $Response.Body
        }
        else {
            return $Response.Body.successes
        }
    }

}
