function New-AkamaiDataCache {
    $Global:AkamaiDataCache = [ordered] @{
        'APIDefinitions' = @{
            'APIEndpoints' = @{}
        }
        'AppSec'         = @{
            'Configs' = @{}
        }
        'ClientLists'    = @{
            'Lists' = @{}
        }
        'EdgeWorkers' = @{
            'EdgeWorkers' = @{}
        }
        'METS'           = @{
            'CASets' = @{}
        }
        'MOKS'           = @{
            'ClientCerts' = @{}
        }
        'Property'       = [ordered] @{
            'Properties' = @{}
            'Includes'   = @{}
        }
    }
}
