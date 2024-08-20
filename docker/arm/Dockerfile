# Copyright 2024 Akamai Technologies
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM mcr.microsoft.com/powershell:7.4-mariner-2.0-arm64

# Install tar functionality
RUN tdnf install tar -y

# Install Akamai module
RUN ["pwsh", "-command", "Install-Module -Scope AllUsers Akamai -Force"]