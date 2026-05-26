function New-NetstorageDirectory {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "mkdir"
        $RequestParams = @{
            'Path'     = $Path
            'Action'   = $Action
            'NSRCFile' = $NSRCFile
            'Section'  = $Section
        }
        try {
            $Response = Invoke-NetstorageRequest @RequestParams
            return $Response
        }
        catch {
            throw $_
        }
    }
}
