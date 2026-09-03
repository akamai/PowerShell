function New-EdgeKVNamespace {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        [ValidateSet('STAGING', 'PRODUCTION')]
        $Network,

        [Parameter(Mandatory)]
        [string]
        $GroupID,

        [Parameter(Mandatory)]
        [bool]
        $RestrictDataAccess,

        [Parameter()]
        [string]
        $RetentionInSeconds = 0,

        [Parameter()]
        [ValidateSet('US', 'EU', 'JP', 'GLOBAL')]
        [string]
        $GeoLocation = 'US',

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

    if ($Network -eq 'STAGING' -and $GeoLocation -ne 'US') {
        throw 'Only valid GeoLocation for STAGING network is US currently'
    }

    $Path = "/edgekv/v1/networks/$Network/namespaces"

    $Body = @{
        'name'               = $Name
        'geoLocation'        = $GeoLocation
        'retentionInSeconds' = $RetentionInSeconds
        'groupId'            = $GroupID
        'dataAccessPolicy'   = @{
            'restrictDataAccess' = $RestrictDataAccess
        }
    }
    $RequestParams = @{
        'Path'             = $Path
        'Method'           = 'POST'
        'Body'             = $Body
        'EdgeRCFile'       = $EdgeRCFile
        'Section'          = $Section
        'AccountSwitchKey' = $AccountSwitchKey
        'Debug'            = ($PSBoundParameters.Debug -eq $true)
    }
    # Make Request
    $Response = Invoke-AkamaiRequest @RequestParams
    return $Response.Body
}

