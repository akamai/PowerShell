function Clear-AkamaiDataCache {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param(
        [Parameter(ParameterSetName = 'API endpoint name')]
        [string]
        $APIEndpointName,

        [Parameter(ParameterSetName = 'API endpoint ID')]
        [string]
        $APIEndpointID,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [string]
        $AppSecConfigName,

        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecConfigID,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecPolicyName,

        [Parameter(ParameterSetName = 'AppSec config name')]
        [Parameter(ParameterSetName = 'AppSec config ID')]
        [string]
        $AppSecPolicyID,

        [Parameter(ParameterSetName = 'Client List name')]
        [string]
        $ClientListName,

        [Parameter(ParameterSetName = 'Client List ID')]
        [string]
        $ClientListID,

        [Parameter(ParameterSetName = 'EdgeWorker name')]
        [string]
        $EdgeWorkerName,

        [Parameter(ParameterSetName = 'EdgeWorker ID')]
        [string]
        $EdgeWorkerID,

        [Parameter(ParameterSetName = 'METS CaSet name')]
        [string]
        $METSCaSetName,

        [Parameter(ParameterSetName = 'METS CaSet ID')]
        [string]
        $METSCaSetID,

        [Parameter(ParameterSetName = 'MOKS client cert name')]
        [string]
        $MOKSClientCertName,

        [Parameter(ParameterSetName = 'MOKS client cert ID')]
        [string]
        $MOKSClientCertID,

        [Parameter(ParameterSetName = 'Property name')]
        [string]
        $PropertyName,

        [Parameter(ParameterSetName = 'Property ID')]
        [string]
        $PropertyID,

        [Parameter(ParameterSetName = 'Include name')]
        [string]
        $IncludeName,

        [Parameter(ParameterSetName = 'Include ID')]
        [string]
        $IncludeID
    )

    if (-not $AkamaiOptions.EnableDataCache) {
        Write-Debug "Data cache not enabled. No cache to clear."
        return
    }

    # Handle input combo
    if (($AppSecPolicyName -or $AppSecPolicyID) -and -not $AppSecConfigName -and -not $AppSecConfigID) {
        throw "To remove an AppSec policy by name or ID you must also provide -AppSecConfigName or -AppSecConfigID."
    }

    # Remove entire cache with no other prompts
    if ($PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
        Write-Debug "Clearing Akamai Data Cache."
        $Global:AkamaiDataCache = $null
        New-AkamaiDataCache
    }

    # Otherwise, remove individual elements
    # ---- API Endpoints
    if ($APIEndpointID) {
        foreach ($Key in $AkamaiDataCache.APIDefinitions.APIEndpoints.Keys) {
            if ($AkamaiDataCache.APIDefinitions.APIEndpoints.$Key.APIEndpointID -eq $APIEndpointID) {
                $APIEndpointName = $Key
                break
            }
        }
    }
    if ($APIEndpointName) {
        if ($null -ne $AkamaiDataCache.APIDefinitions.APIEndpoints.$APIEndpointName) {
            Write-Debug "Removing APIEndpoint '$APIEndpointName' from data cache."
            $AkamaiDataCache.APIDefinitions.APIEndpoints.Remove($APIEndpointName)
        }
    }

    # ---- AppSec
    if ($AppSecConfigID) {
        foreach ($Key in $AkamaiDataCache.AppSec.Configs.Keys) {
            if ($AkamaiDataCache.AppSec.Configs.$Key.ConfigId -eq $AppSecConfigID) {
                $AppSecConfigName = $Key
                break
            }
        }
    }
    if ($AppSecConfigName) {
        # Check for policy info, as if present we only delete that, not the whole config key
        if ($AppSecPolicyID -or $AppSecPolicyName) {
            if ($AppSecPolicyID) {
                foreach ($Key in $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.Keys) {
                    if ($AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$Key.PolicyID -eq $AppSecPolicyID) {
                        $AppSecPolicyName = $Key
                        break
                    }
                }
            }
            if ($AppSecPolicyName) {
                if ($null -ne $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.$AppSecPolicyName) {
                    Write-Debug "Removing AppSec policy '$AppSecPolicyName' from data cache."
                    $AkamaiDataCache.AppSec.Configs.$AppSecConfigName.Policies.Remove($AppSecPolicyName)
                }
            }
        }
        else {
            if ($null -ne $AkamaiDataCache.AppSec.Configs.$AppSecConfigName) {
                Write-Debug "Removing AppSec config '$AppSecConfigName' from data cache."
                $AkamaiDataCache.AppSec.Configs.Remove($AppSecConfigName)
            }
        }
    }

    # ---- Client Lists
    if ($ClientListID) {
        foreach ($Key in $AkamaiDataCache.ClientLists.Lists.Keys) {
            if ($AkamaiDataCache.ClientLists.Lists.$Key.ListID -eq $ClientListID) {
                $ClientListName = $Key
                break
            }
        }
    }
    if ($ClientListName) {
        if ($null -ne $AkamaiDataCache.ClientLists.Lists.$ClientListName) {
            Write-Debug "Removing client list '$ClientListName' from data cache."
            $AkamaiDataCache.ClientLists.Lists.Remove($ClientListName)
        }
    }

    # ---- EdgeWorkers
    if ($EdgeWorkerID) {
        foreach ($Key in $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Keys) {
            if ($AkamaiDataCache.EdgeWorkers.EdgeWorkers.$Key.EdgeWorkerID -eq $EdgeWorkerID) {
                $EdgeWorkerName = $Key
                break
            }
        }
    }
    if ($EdgeWorkerName) {
        if ($null -ne $AkamaiDataCache.EdgeWorkers.EdgeWorkers.$EdgeWorkerName) {
            Write-Debug "Removing EdgeWorker '$EdgeWorkerName' from data cache."
            $AkamaiDataCache.EdgeWorkers.EdgeWorkers.Remove($EdgeWorkerName)
        }
    }

    # ---- METS
    if ($METSCaSetID) {
        foreach ($Key in $AkamaiDataCache.METS.CASets.Keys) {
            if ($AkamaiDataCache.METS.CASets.$Key.CASetID -eq $METSCaSetID) {
                $METSCaSetName = $Key
                break
            }
        }
    }
    if ($METSCaSetName) {
        if ($null -ne $AkamaiDataCache.METS.CASets.$METSCaSetName) {
            Write-Debug "Removing METS CA Set '$METSCaSetName' from data cache."
            $AkamaiDataCache.METS.CASets.Remove($METSCaSetName)
        }
    }

    # ---- MOKS
    if ($MOKSClientCertID) {
        foreach ($Key in $AkamaiDataCache.MOKS.ClientCerts.Keys) {
            if ($AkamaiDataCache.MOKS.ClientCerts.$Key.CertificateID -eq $MOKSClientCertID) {
                $MOKSClientCertName = $Key
                break
            }
        }
    }
    if ($MOKSClientCertName) {
        if ($null -ne $AkamaiDataCache.MOKS.ClientCerts.$MOKSClientCertName) {
            Write-Debug "Removing MOKS Client Certificate '$MOKSClientCertName' from data cache."
            $AkamaiDataCache.MOKS.ClientCerts.Remove($MOKSClientCertName)
        }
    }

    # ---- Property
    if ($PropertyID) {
        foreach ($Key in $AkamaiDataCache.Property.Properties.Keys) {
            if ($AkamaiDataCache.Property.Properties.$Key.PropertyID -eq $PropertyID) {
                $PropertyName = $Key
                break
            }
        }
    }
    if ($PropertyName) {
        if ($null -ne $AkamaiDataCache.Property.Properties.$PropertyName) {
            Write-Debug "Removing property '$PropertyName' from data cache."
            $AkamaiDataCache.Property.Properties.Remove($PropertyName)
        }
    }

    if ($IncludeID) {
        foreach ($Key in $AkamaiDataCache.Property.Includes.Keys) {
            if ($AkamaiDataCache.Property.Includes.$Key.IncludeID -eq $IncludeID) {
                $IncludeName = $Key
                break
            }
        }
    }
    if ($IncludeName) {
        if ($null -ne $AkamaiDataCache.Property.Includes.$IncludeName) {
            Write-Debug "Removing include '$IncludeName' from data cache."
            $AkamaiDataCache.Property.Includes.Remove($IncludeName)
        }
    }
}
