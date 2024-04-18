# Release notes

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

* Property

    Amalgamated rule management functions into `Get-PropertyRules` and `Set-PropertyRules` with equivalents for include that support PowerShell objects, JSON files, and snippets directories.

* Cloudlets

    United shared and non-shared endpoints into single functions with a default of shared and a `-Legacy` switch to create and manage non-shared policies.

* NetStorage

    Joined Config and Usage functions into a single submodule to simplify storage group and content management.

### Known issues

At the time of this release, there is no 1:1 support for these v1 services. To use Akamai PowerShell with these services, continue to use v1.

* API Key Manager
* China CDN
* Log Delivery Service
* Media Delivery Reports
* Media Services Live
* Service Level Agreement