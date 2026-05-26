function Set-NetstorageObjectMTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $mtime,

        [Parameter()]
        [Alias('AuthFile')]
        [string]
        $NSRCFile,

        [Parameter()]
        [string]
        $Section
    )

    process {
        $Action = "mtime"
        $Body = ''
        $AdditionalOptions = @{
            'mtime' = $mtime
        }
    
        $RequestParams = @{
            'Path'              = $Path
            'Action'            = $Action
            'AdditionalOptions' = $AdditionalOptions
            'Body'              = $Body
            'NSRCFile'          = $NSRCFile
            'Section'           = $Section
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
