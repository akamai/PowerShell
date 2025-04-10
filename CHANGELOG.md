# Release notes

## 2.2.0 (Apr 8 2025)

### New

* Submodules
  * MTLS Origin Keystore (MOKS)

* Functionality
  * General
   * Improved API handling and migration help.
      * `Invoke-AkamaiRequest`. Replaces `Invoke-AkamaiRestMethod` in all higher functions. It's based on `Invoke-WebRequest` rather than `Invoke-RestMethod`, so all functions work the same for PowerShell v5.1 and ≥7.0.
      * `Uninstall-Akamai`. Handles migration from Akamaipowershell v1.
   
  * Added options architecture that manage server and rate limiting error impact, provides troubleshooting information, and stores Akamai asset IDs for reuse. 
      * Error Retries
      * Rate Limit Retries
      * Rate Limit Warnings
      * Property API Prefixes
      * Suggested Actions
      * Data Cache

  * EdgeKV
      * `Get-EdgeKVNamespaceDelete`. Gets the namespace delete time.
      * `Get-EdgeKVNamespaceGroup`. Lists groups within a namespace.
      * `Remove-EdgeKVNamespace`. Deletes a namespace.
      * `Restore-EdgeKVNamespace`. Cancels a scheduled namespace delete.
      * `Update-EdgeKVAccessToken`. Refreshes an access token.
 
  * NetStorage<br />
  `Read-NetstorageDirectory`. Recursively downloads an entire directory from a storage group.

### Bug Fixes

This update fixes the following issues.

* `AllowCancelPendingChanges`. A typo prevented its use.
* `*-EdgeKVItem`. Overloaded use of the word _group_ in functions that fused item and access control groups. Access control groups now use a string.
* `Get-PropertyIncludeRulesDigest`. Didn't require the`-IncludeVersion` parameter, missing mandatory annotation on the parameter.
* `Get-PropertyHostname`. Didn't pass the `-Network` parameter to recursive calls.
* `Get-IAMGroup`. Unexpected behavior when using the `-Flatten` option in PowerShell 5.1. Resolves [Akamaipowershell issue 54](https://github.com/akamai/akamaipowershell/issues/54).
* `New-AppSecActivation`. Body data not sent if not a string.
* `New-Property`. Always placed a cloned property in the existing property's group. Resolves [Issue 11](https://github.com/akamai/powershell/issues/11).
    
### Updates

* General
  * Overhauled error handling, making displayed errors much more useful.
  * Added the module version to`RequiredModules` in all submodules.
  * Added splatting to all functions using `Invoke-AkamaiRequest`.
  * Expanded debugging so parameters are passed down to `Invoke-AkamaiRequest`.
    
* Property
  * Added pipeline support for `Get-Property` to retrieve groups and list their properties.
  * Clarified function response in `Get-PropertyIncludeRules`.

* AppSec
  * Added error handling to `Expand-AppSecConfigDetails` if the given `ConfigName` is not found. Previously it just warned the user.
  * `Get-AppSecMatchTarget`: changed `IncludeChildObjectName` switch parameter to `OmitChildObjectName`. Inclusion of child objects is the default API behavior, so you could only previously remove them by the use of `-IncludeChildObjectName:$false`, which is confusing.
  * Improved pipeline handling, particularly with `Remove-*` functions.
    
* Edge DNS
  * Included support for updating multiple records and to auto-increment zone SOA record if required to `Set-EdnsRecordSet`.
  
* Identity & Access Management
  * Added an option that disables the implicit inclusion of account switch keys in `Get-AccountSwitchKey`.
  * Changed the `PropertyID` parameter to `AssetID` so that it's inline with API documentation and matches the Property API format.
    
* CPS
  * Added the `ContractID` parameter to `Get-CPSEnrollment` to allow for both get one and get all functionality.

* SLA
  * Improved pipeline support.
    
* Edge Diagnostics
  * Forced inclusion of `useStaging` in request body to mitigate an API issue.

* Datastream
   * Added `-Activate` switch to `New-DataStream` that combines creation and activation of the datastream.

* Netstorage
  * Improved `Get-NetstorageDirectory` to properly handle `StartPath` and `EndPath` parameters.
  * Added error handling in `New-NetstorageAuth` when the provided `UploadAccountID` does not have HTTP API access enabled.
  * Added functionality to `Read-NetstorageObject` to create necessary folders in the local path.

### Deprecated

All Media Delivery Reports functions.

### Removed

Removed redundant `Set-APIEndpointVersionPIIParameters` function from API Definitions submodule.

### Known issues

There is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1. 

## 2.1.0 (Aug 16 2024)

### New

* Submodules
  * API Key Manager
  * ChinaCDN
  * Client Lists
  * Cloud Wrapper
  * Media Services Live
  * mTLS Edge Trust Store (METS)
  * SLA

* Functionality
  * General
    * Added Docker support for both both AMD64 and ARM64.

  * Property
    * Expanded Property submodule to include cmdlets for add, remove, test, and update property rules.
    * Added `OriginalInput` and `UpgradeRules` switches to support Flex PAPI features.
    * Added functions to get rule digest (Powershell 6+).

### Updates

* AppSec
  * Moved `Copy-AppSecPolicy` functionality into `New-AppSecPolicy` with `-CreateFromPolicyName` and `-CreateFromPolicyID` options.
  * Added `-Override` option to `Set-AppSecPolicyRequestSizeLimit` to allow for enforcement of customized limits.

* CPS
  * Bumped deployment content-type to v8.

* Property
  * Added additional response body object members in cmdlets that only returned a link, removing the need to parse IDs for use downstream.
  
    For example, `New-Property` now returns both a `PropertyLink`, `/papi/v1/properties/prp_97654?contractId=ctr_C-0N7RAC7&groupId=grp_12345`, and an isolated `PropertyID`, `97654` or `prp_97654` depending on your client settings.

  * Simplified `Get-PropertyRules` and `Get-PropertyIncludeRules` to support multiple output types.
  * Broadened `Get-PropertyHostname` to list all account hostnames if no property information provided.
  
### Removed

* Common
  * Scoping for 100-continue removal.

* AppSec
  * `Copy-AppSecPolicy`. Functionality moved into `New-AppSecPolicy`.

* Image & Video Manager
  * ImageCollection functions.

### Known issues

There is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1.

All other previous known issues are resolved with this release's new submodules.

## 2.0.0 (Apr 17, 2024)

### New

* All submodules

  * Split module into parent and child architecture to improve import speed and flexibility.
  * Created parent manifest module that allows an install or import of all child modules in a single command.
  * Constructed `Expand-` functions to make lookups more efficient when asset names or versions of `latest` are used

### Updates

* All submodules

  * Added clear function and parameter descriptions in help documentation.
  * Revised existing functions to use the most recent API versions.
  * Removed all unapproved verbs.
  * Combined singular and plural functions into one, removing `List-` functions.
  * Merged object and string request body parameters into `-Body` that accepts any datatype that converts to JSON.
  * Extended support for pipelining.

* Cloudlets

  United shared and non-shared endpoints into single functions with a default of shared and a `-Legacy` switch to create and manage non-shared policies.

* NetStorage

  Joined Config and Usage functions into a single submodule to simplify storage group and content management.

* Property

  Amalgamated rule management functions into `Get-PropertyRules` and `Set-PropertyRules` with equivalents for include that support PowerShell objects, JSON files, and snippets directories.

### Known issues

At the time of this release, there is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1.

* API Key Manager
* China CDN
* Media Delivery Reports
* Media Services Live
* Service Level Agreement
