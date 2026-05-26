function Set-AkamaiDataCache {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'API Definitions', Mandatory)]
        [string]
        $APIEndpointName,

        [Parameter(ParameterSetName = 'API Definitions', Mandatory)]
        [string]
        $APIEndpointID,

        [Parameter(ParameterSetName = 'AppSec config', Mandatory)]
        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecConfigName,

        [Parameter(ParameterSetName = 'AppSec config', Mandatory)]
        [string]
        $AppSecConfigID,

        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecPolicyName,

        [Parameter(ParameterSetName = 'AppSec policy', Mandatory)]
        [string]
        $AppSecPolicyID,

        [Parameter(ParameterSetName = 'Client Lists', Mandatory)]
        [string]
        $ClientListName,

        [Parameter(ParameterSetName = 'Client Lists', Mandatory)]
        [string]
        $ClientListID,

        [Parameter(ParameterSetName = 'EdgeWorkers', Mandatory)]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'EdgeWorkers', Mandatory)]
        [string]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'METS', Mandatory)]
        [string]
        $METSCaSetName,

        [Parameter(ParameterSetName = 'METS', Mandatory)]
        [string]
        $METSCaSetID,

        [Parameter(ParameterSetName = 'MOKS', Mandatory)]
        [string]
        $MOKSClientCertName,

        [Parameter(ParameterSetName = 'MOKS', Mandatory)]
        [string]
        $MOKSClientCertID,

        [Parameter(ParameterSetName = 'Property', Mandatory)]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Property', Mandatory)]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Include', Mandatory)]
        [string]
        $IncludeID
    )

    # ---- API Endpoints
    if ($PSCmdlet.ParameterSetName -eq 'API Definitions') {
        if ($AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName) {
            Write-Debug "Setting existing cache entry for API Endpoint '$APIEndpointName' to '$APIEndpointID'."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName.APIEndpointID = $APIEndpointID
        }
        else {
            Write-Debug "Setting new cache entry for API Endpoint '$APIEndpointName' to '$APIEndpointID'."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName = @{ 'APIEndpointID' = $APIEndpointID }
        }
    }

    # ---- AppSec
    if ($PSCmdlet.ParameterSetName.StartsWith('AppSec')) {
        # Config mode
        if (-not $AppSecPolicyName -and -not $AppSecPolicyID) {
            if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Setting existing cache entry for AppSec config '$AppSecConfigName' to '$AppSecConfigID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.ConfigID = $AppSecConfigID
            }
            else {
                Write-Debug "Setting new cache entry for AppSec config '$AppSecConfigName' to '$AppSecConfigID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName = @{
                    'ConfigID' = $AppSecConfigID
                    'Policies' = @{}
                }
            }
        }
        # Policy Mode
        else {
            if (($AppSecPolicyName -and -not $AppSecPolicyID) -or ($AppSecPolicyID -and -not $AppSecPolicyName)) {
                throw "To add a policy to the data cache you require -AppSecPolicyName AND -AppSecPolicyID"
            }
            if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Setting existing cache entry for AppSec config '$APIEndpointName ($APIEndpointID)'. Policy '$AppSecPolicyName' set to '$AppSecPolicyID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$AppSecPolicyName = @{ 'PolicyID' = $AppSecPolicyID }
            }
            else {
                Write-Debug "Setting new cache entry for AppSec config '$APIEndpointName ($APIEndpointID)'. Policy '$AppSecPolicyName' set to '$AppSecPolicyID'."
                $AkamaiDataCache.AppSec.Configs.$AppSecConfigName = @{
                    'ConfigID' = $AppSecConfigID
                    'Policies' = @{
                        $AppSecPolicyName = @{
                            'PolicyID' = $AppSecPolicyID
                        }
                    }
                }
            }
        }
    }

    # ---- Client Lists
    if ($PSCmdlet.ParameterSetName -eq 'Client Lists') {
        if ($AkamaiDataCache.ClientLists.Lists.$ClientListName) {
            Write-Debug "Setting existing cache entry for Client List '$ClientListName' to '$ClientListID'."
            $AkamaiDataCache.ClientLists.Lists.$ClientListName.ListID = $ClientListID
        }
        else {
            Write-Debug "Setting new cache entry for Client List '$ClientListName' to '$ClientListID'."
            $AkamaiDataCache.ClientLists.Lists.$ClientListName = @{ 'ListID' = $ClientListID }
        }
    }

    # ---- EdgeWorkers
    if ($PSCmdlet.ParameterSetName -eq 'EdgeWorkers') {
        if ($AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
            Write-Debug "Setting existing cache entry for EdgeWorker '$EdgeWorkerName' to '$EdgeWorkerID'."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName.EdgeWorkerID = $EdgeWorkerID
        }
        else {
            Write-Debug "Setting new cache entry for EdgeWorker '$EdgeWorkerName' to '$EdgeWorkerID'."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName = @{ 'EdgeWorkerID' = $EdgeWorkerID }
        }
    }

    # ---- METS
    if ($PSCmdlet.ParameterSetName -eq 'METS') {
        if ($AkamaiDataCache.METS.CASets.$METSCaSetName) {
            $AkamaiDataCache.METS.CASets.$METSCaSetName.CASetID = $METSCaSetID
        }
        else {
            Write-Debug "Setting new cache entry for METS CA Set '$METSCaSetName' to '$METSCaSetID'."
            $AkamaiDataCache.METS.CASets.$METSCaSetName = @{ 'CASetID' = $METSCaSetID }
        }
    }

    # ---- MOKS
    if ($PSCmdlet.ParameterSetName -eq 'MOKS') {
        if ($AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName) {
            Write-Debug "Setting existing cache entry for MOKS Client Cert '$MOKSClientCertName' to '$MOKSClientCertID'."
            $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName.CertificateID = $MOKSClientCertID
        }
        else {
            Write-Debug "Setting new cache entry for MOKS Client Cert '$MOKSClientCertName' to '$MOKSClientCertID'."
            $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName = @{ 'CertificateID' = $MOKSClientCertID }
        }
    }

    # ---- Property
    if ($PSCmdlet.ParameterSetName -eq 'Property') {
        if ($AkamaiDataCache.Property.Properties.$PropertyName) {
            Write-Debug "Setting existing cache entry for Property '$PropertyName' to '$PropertyID'."
            $AkamaiDataCache.Property.Properties.$PropertyName.PropertyID = $PropertyID
        }
        else {
            Write-Debug "Setting new cache entry for Property '$PropertyName' to '$PropertyID'."
            $AkamaiDataCache.Property.Properties.$PropertyName = @{ 'PropertyID' = $PropertyID }
        }
    }

    # ---- Include
    if ($PSCmdlet.ParameterSetName -eq 'Include') {
        if ($AkamaiDataCache.Property.Includes.$IncludeName) {
            Write-Debug "Setting existing cache entry for Include '$IncludeName' to '$IncludeID'."
            $AkamaiDataCache.Property.Includes.$IncludeName.IncludeID = $IncludeID
        }
        else {
            Write-Debug "Setting new cache entry for Include '$IncludeName' to '$IncludeID'."
            $AkamaiDataCache.Property.Includes.$IncludeName = @{ 'IncludeID' = $IncludeID }
        }
    }
}
