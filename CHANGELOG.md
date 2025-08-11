## 2.3.0 (Aug 11, 2025)

### New 

#### CPS

* `Get-CPSActiveCertificate`. Gets active certificates for a given account or contract.

#### Datastream

* `Get-DatastreamEDNSZones`. Returns Edge DNS zones on your contract.
* `Get-DatastreamGTMProperties`. Returns Global Traffic Management (GTM) domain properties on your contract.

#### EdgeWorkers

* `Get-EdgeWorkerLoggingOverride`. Get status information about a specific logging override. 
* `New-EdgeWorkerLoggingOverride`. Override the default JavaScript logging level for an EdgeWorker specified by its `EdgeWorkerName` or `EdgeWorkerID`.

#### Test Center

`Initialize-TestSuite`. Generates the request body for a new test suite. This addition clears up a confusing workflow when using `New-TestSuite -AutoGenerate`.

### Bug Fixes

This update fixes the following issues.

* `Akamai.Common` module. Options are no longer reset when module is imported.
* `Akamai.GTM` module. `MapName` is now mandatory on `Remove-GTMCIDRMap`.
* `Akamai.EdgeDNS` module. Unified casing of EdgeDNS.
* `Akamai.Reporting` module. `Limit` and `Filters` are now applied correctly.
* `New-EdgeKVNamespace`. The `GroupID` parameter is now mandatory.

### Updates

#### Common

* Added support for `$ENV:proxy_use_default_credentials` that was available in v1 but missed in the upgrade to v2.
* Improved handling of unexpected errors whose response body does not contain the HTTP status.

#### Datastream

* Migrated to v3 of the API. This adds stream support for CDN, EdgeWorkers, EdgeDNS and GTM. All functions now have a `LogType` parameter that defaults to `cdn` for backwards compatibility.

#### EdgeKV

* `New-EdgeKVNamespace`. Added `RestrictDataAccess` parameter so you can control namespace access in Standard TLS.

#### IAM

* Added `PropertyID` alias to any command using `AssetID` for backwards compatibility.

#### SIEM

* `Get-SIEMData`. The `To` parameter is no longer mandatory to match the API.

#### Test Center

* `New-TestSuite`. Added parameters option to better support creation of simple test suites.

## 2.2.1 (Apr 15, 2025)

### Bug Fixes

This update fixes the following issues.

* `Akamai.Common` module. When using `New-NetstorageSymlink` without having run `Invoke-AkamaiRestMethod` in the same session, it couldn't find the system HTTP utility. The `System.Web` assembly is now auto-loaded for PowerShell 5.1 clients. Resolves [Issue 10](https://github.com/akamai/powershell/issues/10).
* `Invoke-AkamaiRequest`. It didn't parse correctly when using PowerShell 5.1 on Windows Server without Internet Explorer installed. Added a `-UseBasicParsing` parameter. Resolves [Issue 14](https://github.com/akamai/powershell/issues/14).
* GTM `Body` parameter. A body is required in several functions but wasn't set to `Mandatory`. Corrected.
* GTM `DatacenterID` parameter. It was a string. Updated to `int`.
* GTM return object. It wasn't scoped properly in several `New` functions. Rescoped to `resource` property. 

### Updates

#### GTM

Added Pipeline support for multiple functions.

* `Remove-GTMASMap`
* `Remove-GTMCIDRMap`
* `Remove-GTMDatacenter`
* `Remove-GTMGeoMap`
* `Remove-GTMProperty`
* `Remove-GTMResource`

## 2.2.0 (Apr 8, 2025)

### New

#### Submodules

MTLS Origin Keystore (MOKS)

#### General

* `Invoke-AkamaiRequest`. Replaces `Invoke-AkamaiRestMethod` in all higher function. It's based on `Invoke-WebRequest` rather than `Invoke-RestMethod`, so all functions work the same for PowerShell v5.1 and ≥7.0.
* `Uninstall-Akamai`. Handles migration from Akamaipowershell v1.
* Added options architecture that manage server and rate limiting error impact, provides troubleshooting information, and stores Akamai asset IDs for reuse. 
  * Error retries
  * Rate Limit retries and warnings
  * Property API prefixes
  * Suggested actions
  * Data cache

#### EdgeKV

* `Get-EdgeKVNamespaceDelete`. Gets the namespace delete time.
* `Get-EdgeKVNamespaceGroup`. Lists groups within a namespace.
* `Remove-EdgeKVNamespace`. Deletes a namespace.
* `Restore-EdgeKVNamespace`. Cancels a scheduled namespace delete.
* `Update-EdgeKVAccessToken`. Refreshes an access token.

#### NetStorage

`Read-NetstorageDirectory`. Recursively downloads an entire directory from a storage group.
    
### Bug Fixes

This update fixes the following issues.

* `New-Property`. Always placed a cloned property in the existing property's group. Resolves [Issue 11](https://github.com/akamai/powershell/issues/11).
* `Get-PropertyIncludeRulesDigest`. Didn't require the`-IncludeVersion` parameter, missing mandatory annotation on the parameter.
* `Get-PropertyHostname`. Didn't pass the `-Network` parameter to recursive calls.
* `AllowCancelPendingChanges`. A typo prevented its use.
* `Get-IAMGroup`. Unexpected behavior when using the `-Flatten` option in PowerShell 5.1. Resolves [Akamaipowershell issue 54](https://github.com/akamai/akamaipowershell/issues/54).
* `*-EdgeKVItem`. Overloaded use of the word _group_ in functions that fused item and access control groups. Access control groups now use a string.
* `New-AppSecActivation`. Body data not sent if not a string.
    
### Updates

#### General
  
* Overhauled error handling, making displayed errors much more useful.
* Added the module version to`RequiredModules` in all submodules.
* Added splatting to all functions using `Invoke-AkamaiRequest`.
* Expanded debugging so parameters are passed down to `Invoke-AkamaiRequest`.

#### AppSec
  
* Added error handling to `Expand-AppSecConfigDetails` if the given `ConfigName` is not found. Previously it just warned the user.
* `Get-AppSecMatchTarget`: changed `IncludeChildObjectName` switch parameter to `OmitChildObjectName`. Inclusion of child objects is the default API behavior, so you could only previously remove them by the use of `-IncludeChildObjectName:$false`, which is confusing.
* Improved pipeline handling, particularly with `Remove-*` functions.
    
#### CPS

Added the `ContractID` parameter to `Get-CPSEnrollment` to allow for both get one and get all functionality.

#### Datastream

Added `-Activate` switch to `New-DataStream` that combines creation and activation of the datastream.

#### Edge DNS

Included support for updating multiple records and to auto-increment zone SOA record if required to `Set-EdnsRecordSet`.
  
#### Edge Diagnostics

Forced inclusion of `useStaging` in request body to mitigate an API issue.

#### Identity & Access Management

* Added an option that disables the implicit inclusion of account switch keys in `Get-AccountSwitchKey`.
* Changed the `PropertyID` parameter to `AssetID` so that it's inline with API documentation and matches the Property API format.
    
#### Netstorage

* Improved `Get-NetstorageDirectory` to properly handle `StartPath` and `EndPath` parameters.
* Added error handling in `New-NetstorageAuth` when the provided `UploadAccountID` does not have HTTP API access enabled.
* Added functionality to `Read-NetstorageObject` to create necessary folders in the local path.

#### Property

* Added pipeline support for `Get-Property` to retrieve groups and list their properties.
* Clarified function response in `Get-PropertyIncludeRules`.

#### SLA

Improved pipeline support.

### End-of-Life

The Media Delivery Reports service hit end end-of-life. This service's functions were available in v1 but had yet to be added to v2. Because of its lifecycle state, they will not be added to v2.

### Removed

Redundant `Set-APIEndpointVersionPIIParameters` function from API Definitions submodule.

## 2.1.0 (Aug 16, 2024)

### New

#### Submodules

* API Key Manager
* ChinaCDN
* Client Lists
* Cloud Wrapper
* Media Services Live
* mTLS Edge Trust Store (METS)
* SLA

#### General

Added Docker support for both both AMD64 and ARM64.

#### Property

* Expanded Property submodule to include cmdlets for add, remove, test, and update property rules.
* Added `OriginalInput` and `UpgradeRules` switches to support Flex PAPI features.
* Added functions to get rule digest (Powershell 6+).

### Updates

#### AppSec

* Moved `Copy-AppSecPolicy` functionality into `New-AppSecPolicy` with `-CreateFromPolicyName` and `-CreateFromPolicyID` options.
* Added `-Override` option to `Set-AppSecPolicyRequestSizeLimit` to allow for enforcement of customized limits.

#### CPS

Bumped deployment content-type to v8.

#### Property

* Added additional response body object members in cmdlets that only returned a link, removing the need to parse IDs for use downstream. For example, `New-Property` now returns both a `PropertyLink`, `/papi/v1/properties/prp_97654?contractId=ctr_C-0N7RAC7&groupId=grp_12345`, and an isolated `PropertyID`, `97654` or `prp_97654` depending on your client settings.
* Simplified `Get-PropertyRules` and `Get-PropertyIncludeRules` to support multiple output types.
* Broadened `Get-PropertyHostname` to list all account hostnames if no property information provided.
  
### Removed

#### Common

Scoping for 100-continue removal.

#### AppSec
`Copy-AppSecPolicy`. Functionality moved into `New-AppSecPolicy`.

#### Image & Video Manager
ImageCollection functions.

### Known issues

All other previous known issues are resolved with this release's new submodules.

## 2.0.0 (Apr 17, 2024)

### New

Refactored entire module. 

* Split module into parent and child architecture to improve import speed and flexibility.
* Created parent manifest module that allows an install or import of all child modules in a single command.
* Constructed `Expand-` functions to make lookups more efficient when asset names or versions of `latest` are used

### Updates

#### All submodules

* Added clear function and parameter descriptions in help documentation.
* Revised existing functions to use the most recent API versions.
* Removed all unapproved verbs.
* Combined singular and plural functions into one, removing `List-` functions.
* Merged object and string request body parameters into `-Body` that accepts any datatype that converts to JSON.
* Extended support for pipelining.

#### Cloudlets

United shared and non-shared endpoints into single functions with a default of shared and a `-Legacy` switch to create and manage non-shared policies.

#### NetStorage

Joined Config and Usage functions into a single submodule to simplify storage group and content management.

#### Property

Amalgamated rule management functions into `Get-PropertyRules` and `Set-PropertyRules` with equivalents for include that support PowerShell objects, JSON files, and snippets directories.

### Known issues

At the time of this release, there is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1.

* API Key Manager
* China CDN
* Media Services Live
* Service Level Agreement
