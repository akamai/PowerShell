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

FROM --platform=linux/amd64 mcr.microsoft.com/powershell:7.5-alpine-3.20 AS build-amd64
FROM --platform=linux/arm64 mcr.microsoft.com/powershell:7.5-mariner-2.0-arm64 AS build-arm64

FROM build-$TARGETARCH

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ] ; then \
    tdnf install tar -y; \
    fi

# Install Akamai module
RUN ["pwsh", "-command", "Install-Module -Scope AllUsers Akamai -Force"] 