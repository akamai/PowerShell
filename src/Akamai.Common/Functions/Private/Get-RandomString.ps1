function Get-RandomString {
    [CmdletBinding(DefaultParameterSetName = 'Alphabetical')]
    Param(
        [Parameter()]
        [int]
        $Length = 16,

        [Parameter(Mandatory, ParameterSetName = 'Alphabetical')]
        [switch]
        $Alphabetical,

        [Parameter(Mandatory, ParameterSetName = 'AlphaNumeric')]
        [switch]
        $AlphaNumeric,

        [Parameter(Mandatory, ParameterSetName = 'Numerical')]
        [switch]
        $Numerical,

        [Parameter(Mandatory, ParameterSetName = 'Hex')]
        [switch]
        $Hex
    )

    $Multiplier = 120
    $AlphabetRange = (97..122)
    $AtoFRange = (97..102)
    $NumberRange = (48..57)

    Switch ($PSCmdlet.ParameterSetName) {
        'Alphabetical' { $CharRange = $AlphabetRange }
        'AlphaNumeric' { $CharRange = $AlphabetRange + $NumberRange }
        'Numerical' { $CharRange = $NumberRange }
        'Hex' { $CharRange = $AtoFRange + $NumberRange }
    }

    $Response = -join ( $CharRange * $Multiplier | Get-Random -Count $Length | ForEach-Object { [char]$_ })
    return $Response
}
