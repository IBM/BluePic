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

imagesFolder=`dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`/images
authHeader="Bearer <valid auth token>"

# Upload images via Kitura-based server (localhost)
curl -v --data-binary @$imagesFolder/bridge.png -X POST http://localhost:8090/images/bridge.png/Bridge/100/100/34.2/80.5/Austin,%20Texas -H "Authorization: $authHeader"
curl -v --data-binary @$imagesFolder/city.png -X POST http://localhost:8090/images/city.png/Car/90/90/50.2/90.5/Tuscon,%20Arizona -H "Authorization: $authHeader"

# Upload images via Kitura-based server (running on Bluemix)
#curl -v --data-binary @$imagesFolder/bridge.png -X POST http://bluepic-superconductive-ebonite.mybluemix.net/users/1003/images/bridge.png/Bridge/100/100/34.2/80.5/Austin,%20Texas -H "Authorization: $authHeader"
#curl -v --data-binary @$imagesFolder/car.png -X POST http://bluepic-superconductive-ebonite.mybluemix.net/users/1003/images/car.png/Car/90/90/50.2/90.5/Tuscon,%20Arizona -H "Authorization: $authHeader"
