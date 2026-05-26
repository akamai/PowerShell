function Remove-NetstorageObject {
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
        $Action = "delete"
        $Body = ''
    
        $RequestParams = @{
            'Path'     = $Path
            'Action'   = $Action
            'Body'     = $Body
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
