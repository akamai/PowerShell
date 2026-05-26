BeforeDiscovery {
    # Check environment variables have been imported
    if ($null -eq $env:PesterGroupID) {
        throw "Required environment variables are missing"
    }
}

Describe 'Safe Akamai.DOM Tests' {
    BeforeAll {
        # Disable module auto-loading
        $OldModuleAutoloadingPreference = $PSModuleAutoloadingPreference
        $PSModuleAutoloadingPreference = 'None'
        
        # Load modules
        $TestModules = 'Akamai.Common', 'Akamai.DOM'
        $LoadedModules = Get-Module
        foreach ($Module in $TestModules) {
            if ($LoadedModules.Name -contains $Module) {
                Remove-Module $Module -Force
            }
            Import-Module "$PSScriptRoot/../dist/$Module/$Module.psd1" -Force
        }
        
        # Set timestamp for unique asset creation
        $Timestamp = [math]::round((Get-Date).TimeOfDay.TotalMilliseconds)

        # Setup shared variables
        $CommonParams = @{
            EdgeRCFile = $env:PesterEdgeRCFile
            Section    = $env:PesterEdgeRCSection
        }
        $TestContract = $env:PesterContractID
        $TestGroupID = $env:PesterGroupID
        $TestDomainName = "validate-$Timestamp.$env:PesterTestZoneName"
        $TestHostname = "host.$TestDomainName"

        $TestNewHostBody = @{
            "domains" = @(
                @{
                    'validationScope' = 'HOST'
                    'domainName'      = $TestHostName
                }
            )
        }

        $ResponseLibrary = "$PSScriptRoot/ResponseLibrary/Akamai.DOM"
        # Persistent Data
        $PD = @{}
    }

    AfterAll {
        Get-DOMDomain @CommonParams | Where-Object domainName -in $TestDomainName, $TestHostname | Remove-DOMDomain @CommonParams
        $PSModuleAutoloadingPreference = $OldModuleAutoloadingPreference
    }

    Context 'New-DOMDomain' {
        It 'validates a domain by pipeline' {
            $PD.NewHost = $TestNewHostBody | New-DOMDomain @CommonParams
            $PD.NewHost.successes[0].domainName | Should -Be $TestHostname
        }
        It 'validates a domain by attributes' {
            $TestParams = @{
                DomainName      = $TestDomainName
                ValidationScope = 'DOMAIN'
            }
            $PD.NewDomain = New-DOMDomain @TestParams @CommonParams
            $PD.NewDomain.successes[0].domainName | Should -Be $TestDomainName
        }
    }

    Context 'Get-DOMDomain' {
        It 'lists domains to be validated' {
            $PD.Domains = Get-DOMDomain @CommonParams
            $PD.Domains.domainName | Should -Contain $TestDomainName
            $PD.Domains.domainName | Should -Contain $TestHostname
        }
        It 'gets a single domain by parameter' {
            $TestParams = @{
                DomainName      = $TestDomainName
                ValidationScope = 'DOMAIN'
            }
            $PD.Domain = Get-DOMDomain @TestParams @CommonParams
            $PD.Domain.domainName | Should -Be $TestDomainName
        }
    }

    Context 'Find-DOMDomain' {
        It 'finds multiple domains by parameter' {
            $TestParams = @{
                DomainName      = @($TestDomainName, $TestHostname)
                ValidationScope = @('DOMAIN', 'HOST')
            }
            $PD.FindDomainParameter = Find-DOMDomain @TestParams @CommonParams
            $PD.FindDomainParameter.domainName | Should -Contain $TestDomainName
            $PD.FindDomainParameter.domainName | Should -Contain $TestHostname
        }
    }

    Context 'Complete-DOMDomain' {
        It 'completes by parameter' {
            $TestParams = @{
                DomainName       = $TestHostname
                ValidationScope  = 'HOST'
                ValidationMethod = 'DNS_TXT'
            }
            $PD.CompleteParameter = Complete-DOMDomain @TestParams @CommonParams
            $PD.CompleteParameter.domainName | Should -Be $TestHostname
            $PD.CompleteParameter.domainStatus | Should -Be 'VALIDATION_IN_PROGRESS'
        }
        It 'completes by pipeline' {
            $TestParams = @{
                ValidationMethod = 'DNS_TXT'
            }
            $PD.CompletePipeline = $PD.Domain | Complete-DOMDomain @TestParams @CommonParams
            $PD.CompletePipeline.domainName | Should -Be $TestDomainName
            $PD.CompletePipeline.domainStatus | Should -Be 'VALIDATION_IN_PROGRESS'
        }
    }

    Context 'Disable-DOMDomain' {
        BeforeAll {
            Mock -CommandName Invoke-AkamaiRequest -ModuleName Akamai.DOM -MockWith {
                $Response = Get-Content -Raw "$ResponseLibrary/Disable-DOMDomain.json"
                return $Response | ConvertFrom-Json
            }
        }
        It 'disables by parameter' {
            $TestParams = @{
                DomainName      = $TestHostname
                ValidationScope = 'HOST'
            }
            $Disable = Disable-DOMDomain @TestParams
            $Disable[0].domainStatus | Should -Be "INVALIDATED"
        }
        It 'disables by pipeline' {
            $Disable = $PD.Domain | Disable-DOMDomain
            $Disable[0].domainStatus | Should -Be "INVALIDATED"
        }
    } 

    Context 'Remove-DOMDomain' {
        It 'deletes by parameter' {
            $TestParams = @{
                DomainName      = $TestHostname
                ValidationScope = 'HOST'
            }
            Remove-DOMDomain @TestParams @CommonParams
        }
        It 'deletes by pipeline' {
            $PD.Domain | Remove-DOMDomain @CommonParams
        }
    }

}
