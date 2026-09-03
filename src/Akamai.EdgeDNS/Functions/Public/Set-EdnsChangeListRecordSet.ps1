function Set-EDNSChangeListRecordSet {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Zone,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'Attributes', Mandatory)]
        [ValidateSet("ADD", "EDIT", "DELETE")]
        [string]
        $Op,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $TTL,

        [Parameter(ParameterSetName = 'Attributes')]
        [string[]]
        $RData,

        [Parameter(ParameterSetName = 'Body', Mandatory, ValueFromPipeline)]
        $Body,

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
        $Method = 'POST'
        $Path = "/config-dns/v2/changelists/$Zone/recordsets/add-change"

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                'name'  = $Name
                'type'  = $Type
                'ttl'   = $TTL
                'rdata' = $RData
                'op'    = $Op
            }
        }

        $RequestParams = @{
            'Method'           = $Method
            'Path'             = $Path
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Body'             = $Body
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }
}
