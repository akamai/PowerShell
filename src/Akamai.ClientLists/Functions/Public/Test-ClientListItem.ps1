function Test-ClientListItem {
    [CmdletBinding(DefaultParameterSetName = 'Items')]
    Param(
        [Parameter(ParameterSetName = 'Items', Mandatory)]
        [string[]]
        $Items,

        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]
        $File,

        [Parameter(Mandatory)]
        [ValidateSet('IP', 'GEO', 'ASN', 'TLS_FINGERPRINT', 'FILE_HASH')]
        [string]
        $ListType,

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
        if ($PSCmdlet.ParameterSetName -eq 'Items') {
            $Path = "/client-list/v1/lists/items/import/validation"
            $Body = @{
                'items'    = $Items
                'listType' = $ListType
            }
        }
        else {
            $Path = "/client-list/v1/lists/items/import-file/validation"
            $FileContent = Get-Content -Raw $File
            $FileName = (Get-Item $File).Name
            $Boundary = "AKAMAIPOWERSHELL"
            $Body = @"
--$Boundary
Content-Disposition: form-data; name="file"; filename="$FileName"

$FileContent
--$Boundary
Content-Disposition: form-data; name="action"

$Action
--$Boundary
Content-Disposition: form-data; name="listType"

$listType
--$Boundary--
"@
            $AdditionalHeaders = @{ 'Content-Type' = "multipart/form-data; boundary=$Boundary" }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'POST'
            'AdditionalHeaders' = $AdditionalHeaders
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey'  = $AccountSwitchKey
            'Debug'             = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
