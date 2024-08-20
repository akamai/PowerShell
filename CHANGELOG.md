# Release notes

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
    * Broadened `Get-PropertyHostname` to list all account hostnames if no property information provided.
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
  
### Removed

* Common
  * Scoping for 100-continue removal.

* AppSec
  * `Copy-AppSecPolicy`. Functionality moved into `New-AppSecPolicy`.

* Image & Video Manager
  * ImageCollection functions.

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
* Log Delivery Service
* Media Delivery Reports
* Media Services Live
* Service Level Agreement