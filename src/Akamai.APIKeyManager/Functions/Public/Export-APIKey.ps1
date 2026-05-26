function Export-APIKey {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int64]
        $CollectionID,

        [Parameter()]
        [string]
        $OutputFileName,

        [Parameter()]
        [switch]
        $PassThru,

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

    process {
        if ($OutputFileName) {
            if (-not $OutputFileName.EndsWith('.json') -and -not $OutputFileName.EndsWith('.xml') -and -not $OutputFileName.EndsWith('.csv')) {
                throw "OutputFileName must use either a json, xml or csv file extension"
            }
            if ($OutputFileName.EndsWith('.csv')) {
                $AdditionalHeaders = @{
                    'Accept' = 'text/csv'
                }
            }
            elseif ($OutputFileName.EndsWith('.xml')) {
                $AdditionalHeaders = @{
                    'Accept' = 'application/xml'
                }
            }
        }
    
        if ($CollectionID) {
            $Path = "/apikey-manager-api/v2/collections/$CollectionID/keys/export"
        }
        else {
            $Path = "/apikey-manager-api/v2/keys/export"
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'GET'
            'AdditionalHeaders' = $AdditionalHeaders
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($OutputFileName) {
            Write-Host 'Writing keys to: ' -NoNewline
            Write-Host $OutputFileName -ForegroundColor Green -NoNewline
            Write-Host '.'
            # JSON
            if ($OutputFileName.EndsWith('.json')) {
                ConvertTo-Json -InputObject @($Response.Body) -Depth 100 | Out-File -FilePath $OutputFileName -Encoding utf8
            }
            # XML
            elseif ($OutputFileName.EndsWith('.xml')) {
                $StringWriter = New-Object System.Io.Stringwriter
                $XMLWriter = New-Object System.Xml.XmlTextWriter($StringWriter)
                $XMLWriter.Formatting = "indented"
                $XMLWriter.IndentChar = " "
                $XMLWriter.Indentation = 4
                $Response.Body.WriteContentTo($XMLWriter)
                $StringWriter.ToString() | Out-File $OutputFileName -Encoding utf8 -NoNewline
            }
            # CSV
            else {
                $ExportParams = @{
                    Path              = $OutputFileName
                    NoTypeInformation = $true
                }
                if ($PSVersionTable.PSVersion -ge '7.0.0') {
                    $ExportParams.UseQuotes = 'AsNeeded'
                }
                $Response.Body | Export-CSV @ExportParams
            }
        }
        if (-not $OutputFileName -or $PassThru) {
            return $Response.Body
        }
    }
}

