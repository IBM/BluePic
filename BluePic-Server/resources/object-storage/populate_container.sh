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

#https://<access point>/<API version>/AUTH_<project ID>/<container namespace>/<object namespace>
#https://dal.objectstorage.open.softlayer.com/v1/AUTH_742fffae2c24438b83a2c43491119a82

# Parse input parameters
source ./parse_inputs.sh

# Variables
authUrl=https://identity.open.softlayer.com/v3/auth/tokens
accessPoint=dal.objectstorage.open.softlayer.com
publicUrl=https://$accessPoint/v1/AUTH_$projectid
container=9012390

# Echo publicUrl
echo "publicUrl: $publicUrl" 

# Get access token
authToken=`curl -i -H "Content-Type: application/json" -d "{ \"auth\": { \"identity\": { \"methods\": [ \"password\" ], \"password\": { \"user\": { \"id\": \"$userid\", \"password\": \"$password\" } } }, \"scope\": { \"project\": { \"id\": \"$projectid\" } } } }" $authUrl | grep X-Subject-Token | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`

# Create container
curl -i $publicUrl/$container -X PUT -H "Content-Length: 0" -H "X-Auth-Token: $authToken"

# Configure container for web hosting
curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Meta-Web-Listings: true"

# Configure container for public access
curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Read: .r:*,.rlistings"

# Upload image to container
imagesFolder=`dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`/images
curl -i $publicUrl/$container/rush.jpg --data-binary @$imagesFolder/rush.jpg -X PUT -H "Content-Type: image/jpeg" -H "X-Auth-Token: $authToken"

echo
echo "Successfully finished populating object storage."
