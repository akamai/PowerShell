function Get-NetstorageDirectoryUsage {
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
        $Action = "du"
        $AdditionalOptions = @{
            'format' = 'sql'
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
            return $Response.du.'du-info'
        }
        catch {
            throw $_
        }
    }
}
