function Get-CloudletSchema {
    [CmdletBinding(DefaultParameterSetName = 'Get all')]
    Param(
        [Parameter(ParameterSetName = 'Get one', Position = 0, Mandatory)]
        [string]
        $SchemaName,

        [Parameter(ParameterSetName = 'Get all', Mandatory)]
        [ValidateSet('API Prioritization', 'Application Load Balancer', 'Audience Segmentation', 'Edge Redirector', 'Forward Rewrite', 'Phased Release', 'Request Control', 'Visitor Prioritization')]
        [string]
        $CloudletType,

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

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Get one') {
            $Path = "/cloudlets/api/v2/schemas/$SchemaName"
        }
        else {
            $Path = "/cloudlets/api/v2/schemas"
            switch ($CloudletType) {
                'API Prioritization' { $CloudletTypeCode = 'AP' }
                'Application Load Balancer' { $CloudletTypeCode = 'ALB' }
                'Audience Segmentation' { $CloudletTypeCode = 'AS' }
                'Edge Redirector' { $CloudletTypeCode = 'ER' }
                'Forward Rewrite' { $CloudletTypeCode = 'FR' }
                'Phased Release' { $CloudletTypeCode = 'CD' }
                'Request Control' { $CloudletTypeCode = 'IG' }
                'Visitor Prioritization' { $CloudletTypeCode = 'VP' }
            }
            $QueryParameters = @{
                'cloudletType' = $CloudletTypeCode
            }
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'GET'
            'QueryParameters'  = $QueryParameters
            'EdgeRCFile'       = $EdgeRCFile
            'Section'          = $Section
            'AccountSwitchKey' = $AccountSwitchKey
            'Debug'            = ($PSBoundParameters.Debug -eq $true)
        }
        # Make Request
        $Response = Invoke-AkamaiRequest @RequestParams
        if ($SchemaName) {
            return $Response.Body
        }
        else {
            return $Response.Body.schemas
        }
    }
}

