function New-CloudletPolicy {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [int]
        $GroupID,

        [Parameter(Mandatory)]
        [ValidateSet('API Prioritization', 'Application Load Balancer', 'Audience Segmentation', 'Edge Redirector', 'Forward Rewrite', 'Phased Release', 'Request Control', 'Visitor Prioritization')]
        [string]
        $CloudletType,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [switch]
        $Legacy,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [int]
        $ClonePolicyID,

        [Parameter(ParameterSetName = 'Non-shared policy')]
        [int]
        $ClonePolicyVersion,

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
        $Body = @{
            'name'        = $Name
            'groupId'     = $GroupID
            'description' = $Description
        }

        if ($Legacy) {
            $Path = "/cloudlets/api/v2/policies"
            switch ($CloudletType) {
                'API Prioritization' { $CloudletID = 5 }
                'Application Load Balancer' { $CloudletID = 9 }
                'Audience Segmentation' { $CloudletID = 6 }
                'Edge Redirector' { $CloudletID = 0 }
                'Forward Rewrite' { $CloudletID = 3 }
                'Phased Release' { $CloudletID = 7 }
                'Request Control' { $CloudletID = 4 }
                'Visitor Prioritization' { $CloudletID = 1 }
            }
            $Body.cloudletId = $CloudletID
        }
        else {
            $Path = "/cloudlets/v3/policies"
            $Body.policyType = 'SHARED'
            switch ($CloudletType) {
                'API Prioritization' { $SharedType = 'AP' }
                'Application Load Balancer' { throw "'Application Load Balancer' policies must use the -Legacy switch." }
                'Audience Segmentation' { $SharedType = 'AS' }
                'Edge Redirector' { $SharedType = 'ER' }
                'Forward Rewrite' { $SharedType = 'FR' }
                'Phased Release' { $SharedType = 'CD' }
                'Request Control' { $SharedType = 'IG' }
                'Visitor Prioritization' { throw "'Visitor Prioritization' policies must use the -Legacy switch." }
            }
            $Body.cloudletType = $SharedType
        }

        $QueryParameters = @{
            'clonePolicyId' = $PSBoundParameters.ClonePolicyID
            'version'       = $PSBoundParameters.ClonePolicyVersion
        }
        $RequestParams = @{
            'Path'             = $Path
            'Method'           = 'POST'
            'QueryParameters'  = $QueryParameters
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

