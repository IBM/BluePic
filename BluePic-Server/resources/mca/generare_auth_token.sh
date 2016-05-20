#!/bin/bash

##
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

# If any commands fail, we want the shell script to exit immediately.
set -e

authHeader="NzVlZWY1MmMtMmVkMS00NTE4LTk1ODctY2U1NWNjNjY0NzlkOmtCTFRXWTF2Uk8yZzVnRmRSYnBWOFE="
appGuid="75eef52c-2ed1-4518-9587-ce55cc66479d"

curl -v -d "grant_type=client_credentials" -X POST "http://imf-authserver.ng.bluemix.net/imf-authserver/authorization/v1/apps/$appGuid/token" -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" -H "Authorization: Basic $authHeader"
