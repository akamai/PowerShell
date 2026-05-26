function Get-NetstorageDirectory {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $Prefix,

        [Parameter(ParameterSetName = 'List')]
        [switch]
        $Recurse,

        [Parameter(ParameterSetName = 'Directory')]
        [string]
        $StartPath,

        [Parameter()]
        [string]
        $EndPath,

        [Parameter()]
        [int]
        $MaxEntries,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $SlashBoth,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = 'dir'
        if ($PSCmdlet.ParameterSetName -eq 'List') {
            $Action = 'list'
            # Add end param to list action if missing. Otherwise the API returns everything
            if ($Path -ne '/' -and -not $EndPath) {
                $EndPath = $Path
            }
        }

        $AdditionalOptions = @{
            'format' = 'sql'
        }

        if ($StartPath) {
            $AdditionalOptions['start'] = $StartPath
        }
        if ($EndPath) {
            $AdditionalOptions['end'] = $EndPath
        }
        if ($MaxEntries) {
            $AdditionalOptions['max_entries'] = $MaxEntries
        }
        if ($Encoding) {
            $AdditionalOptions['encoding'] = $Encoding
        }
        if ($Prefix -ne '') {
            $AdditionalOptions['prefix'] = $Prefix
        }

        if ($SlashBoth) {
            $AdditionalOptions['slash'] = 'both'
        }

        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            if ($PSCmdlet.ParameterSetName -eq 'Directory') {
                return $Response.stat.file
            }
            else {
                return $Response.list.file
            }
        }
        catch {
            throw $_
        }
    }
}
