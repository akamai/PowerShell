function Get-PropertyDebugKey {
    [OutputType([String])]
    [CmdletBinding(DefaultParameterSetName = 'Property Name')]
    param(
        [Parameter(ParameterSetName = 'Property Name', Position = 0, Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Property ID', Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Hostname', Mandatory)]
        [string]
        $Hostname,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(latest|production|staging|[0-9]+)$')]
        [string]
        $PropertyVersion,

        [Parameter(Position = 1)]
        [ValidateSet('cache', 'vars', 'tls', 'client', 'brotli', 'feo', 'tags', 'a2', 'ro', 'im', 'all', 'tap', 'purge')]
        [string]
        $Option = 'all',

        [Parameter()]
        [int]
        $DurationInHours = 24,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $GroupID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ContractId,

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
        $AuthParams = @{
            EdgeRCFile       = $EdgeRCFile
            Section          = $Section
            AccountSwitchKey = $AccountSwitchKey
        }

        # If using property name or hostname, search for the property
        if ($Hostname) {
            $Local:FoundProperty = Find-Property -PropertyHostname $Hostname @AuthParams
            if (-not $FoundProperty) {
                throw "No property found for hostname $Hostname"
            }
            $Local:FirstFoundProperty = $FoundProperty | Select-Object -First 1
            $PSBoundParameters['PropertyName'] = $Local:FirstFoundProperty.propertyName
        }

        # Expand details as usual
        $PropertyID, $PropertyVersion, $GroupID, $ContractID = Expand-PropertyDetails @PSBoundParameters
        $RulesParams = @{
            PropertyId      = $PropertyID
            PropertyVersion = $PropertyVersion
            GroupId         = $GroupID
            ContractId      = $ContractID
        }
        $Rules = Get-PropertyRules @RulesParams @AuthParams
        $DebugBehavior = Find-Behavior -BehaviorName 'enhancedDebug' -Rule $Rules.rules
        if ($DebugBehavior.Count -eq 0) {
            throw "No debug behavior found in property $PropertyName"
        }

        $Key = $DebugBehavior[0].options.debugKey
        if (-not $Key) {
            throw "No debug key set in enhancedDebug behavior for property $PropertyName"
        }

        $TokenParams = @{
            Secret          = $Key
            DurationInHours = $DurationInHours
            ACL             = '/*'
        }
        $Token = New-EdgeAuthToken @TokenParams
        return "$Token $Option"
    }

}