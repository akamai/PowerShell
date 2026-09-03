function New-ChinaCDNPropertyHostname {
    [CmdletBinding(DefaultParameterSetName = 'Attributes')]
    [Alias('Set-ChinaCDNPropertyHostname')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Hostname,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(ParameterSetName = 'Attributes')]
        [string]
        $Comments,

        [Parameter(, ParameterSetName = 'Attributes')]
        [int]
        $ICPNumberID,

        [Parameter(, ParameterSetName = 'Attributes')]
        [int]
        $ServiceCategory,

        [Parameter(Mandatory, ParameterSetName = 'Body', ValueFromPipeline)]
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

    begin {}

    process {
        $Path = "/chinacdn/v1/property-hostnames/$Hostname"
        $QueryParameters = @{
            'groupId' = $GroupID
        }
        $AdditionalHeaders = @{
            'Accept'       = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
            'Content-Type' = 'application/vnd.akamai.chinacdn.property-hostname.v1+json'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                hostname = $Hostname
            }
            if ($ICPNumberID) {
                $Body['icpNumberId'] = $ICPNumberID
            }
            if ($ServiceCategory) {
                $Body['serviceCategory'] = $ServiceCategory
            }
            if ($Comments) {
                $Body['comments'] = $Comments
            }
        }
        $RequestParams = @{
            'Path'              = $Path
            'Method'            = 'PUT'
            'AdditionalHeaders' = $AdditionalHeaders
            'QueryParameters'   = $QueryParameters
            'Body'              = $Body
            'EdgeRCFile'        = $EdgeRCFile
            'Section'           = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        return $Response.Body
    }

    end {}
}

