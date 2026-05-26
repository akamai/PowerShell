function Set-EdgeKVNamespace {
    [CmdletBinding(DefaultParameterSetName = 'Body')]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('STAGING', 'PRODUCTION')]
        [string]
        $Network,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('namespace')]
        [string]
        $NamespaceID,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [int]
        $RetentionInSeconds,

        [Parameter(Mandatory, ParameterSetName = 'Attributes')]
        [string]
        $GroupID,

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

    process {
        $Path = "/edgekv/v1/networks/$Network/namespaces/$NamespaceID"
        if ($PSCmdlet.ParameterSetName -eq 'Attributes') {
            $Body = @{
                name               = $Name
                retentionInSeconds = $RetentionInSeconds
                groupId            = $GroupID
            }
        }

        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'PUT'
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
}