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

imagesFolder=`dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`
echo "imagesFolder: $imagesFolder"

# Upload images via Kitura-based server
curl -v --data-binary @$imagesFolder/images/tombstone.jpg -X POST http://localhost:8090/users/1000/images/tombstone.jpg/Tombstone
curl -v --data-binary @$imagesFolder/images/swift.png -X POST http://localhost:8090/users/1000/images/swift.png/SwiftRocks
