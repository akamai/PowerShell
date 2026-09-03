function Get-EDNSChangeListRecordSetTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(Mandatory)]
        [string]
        $Name,

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
        $Method = 'GET'
        if ($Name -ne $Zone -and $Name -notmatch "\.$Zone\.?$") {
            $Name = "$Name.$Zone"
        }
        # Remove trailing slash if present
        if ($Name.EndsWith('.')) {
            $Name = $Name.TrimEnd('.')
        }
        $Path = "/config-dns/v2/changelists/$Zone/names/$Name/types"

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body.types
    }
}
