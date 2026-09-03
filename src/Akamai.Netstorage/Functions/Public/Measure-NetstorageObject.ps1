function Measure-NetstorageObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [switch]
        $Implicit,

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
        $Action = 'stat'
    
        $AdditionalOptions = @{
            'format'   = 'sql'
            'encoding' = $Encoding
        }
    
        if ($Implicit) {
            $AdditionalOptions['implicit'] = 'yes'
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
            return $Response.stat.file
        }
        catch {
            throw $_
        }
    }
}