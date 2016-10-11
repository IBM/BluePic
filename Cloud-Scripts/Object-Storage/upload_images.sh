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

# This script is kept as a reference on how to use curl for submitting a multipart request.

# If any commands fail, we want the shell script to exit immediately.
set -e

imagesFolder=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`/images
authHeader="Bearer <valid auth token>"

# Upload images via Kitura-based server (localhost)
curl -v -F "imageJson=@$imagesFolder/bridge.json;type=application/json" -F "imageBinary=@$imagesFolder/bridge.png;type=image/png" -X POST http://localhost:8090/images -H "Content-Type:multipart/form-data" -H "Authorization: $authHeader"
