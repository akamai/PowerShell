# Akamai Powershell Module

The Akamai PowerShell module provides a consistent interface with which to manage Akamai's product API. 

## What's new

We've completely refactored our PowerShell module to expand service availability and improve functionality.

* **Customizable installation.** Built using a submodule approach that groups commands by product or service, giving you the ability to install only what you need.

* **Updated function structure.** Use of PowerShell standard verbs to provide consistency and improve pipeline support.

* **Improved help.** Clear function and parameter descriptions.

## Install

> **Note:** Because v2 is a completely different module, there is no upgrade path. The two modules are incompatible and clash where command names are the same. To use v2, uninstall v1 and then install this module.

Install the full module or customize your install with specific submodules.

* Install the full module.

    ```powershell Full module
    Install-Module Akamai
    ```

* Install individual submodules.

    **Note:** Custom installs load only 

    ```powershell Submodule
    Install-Module Akamai.<submodule-name>
    ```

## Contribute

We're not currently accepting pull requests, but we appreciate and encourage community contribution and feedback through Issues. 

### Create a new issue

Before you create a new issue, search existing issues to see if something related already exists. 

If not, open a new issue, fill out the issue template, providing as much information as you can. 

### Solve an issue

Have a look through our [open issues](https://github.com/akamai/PowerShell/issues) to find one that interests you and pass on your solutions or suggestions. 

### License

Copyright © 2024 Akamai Technologies, Inc. All rights reserved

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.