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

# References:
# https://console.ng.bluemix.net/docs/services/ObjectStorage/objectstorge_usingobjectstorage.html
# https://console.ng.bluemix.net/docs/services/ObjectStorage/objectstorge_usingobjectstorage.html#using-swift-restapi
# https://dal.objectstorage.open.softlayer.com/v1/AUTH_742fffae2c24438b83a2c43491119a82

# Example URL for accessing an object/image
# https://<access point>/<API version>/AUTH_<project ID>/<container namespace>/<object namespace>

# If any commands fail, we want the shell script to exit immediately.
set -e

# Set scripts folder variable
scriptsFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "scriptsFolder: $scriptsFolder"

# Parse input parameters
source "$scriptsFolder/parse_inputs.sh"

# Variables
authUrl=https://identity.open.softlayer.com/v3/auth/tokens
accessPoint=dal.objectstorage.open.softlayer.com
publicUrl=https://$accessPoint/v1/AUTH_$projectid

# Containers (these should match the user ids)
container1=1000
container2=1001
container3=1002
container4=1003
container5=anonymous

# Echo publicUrl
echo "publicUrl: $publicUrl"

# Get access token
authToken=`curl -i -H "Content-Type: application/json" -d "{ \"auth\": { \"identity\": { \"methods\": [ \"password\" ], \"password\": { \"user\": { \"id\": \"$userid\", \"password\": \"$password\" } } }, \"scope\": { \"project\": { \"id\": \"$projectid\" } } } }" $authUrl | grep X-Subject-Token | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`

# Get all containers in this account and delete their contents (and delete them as well)
containers=$(curl $publicUrl -X GET -H "Content-Length: 0" -H "X-Auth-Token: $authToken")
for container in $containers
do
  objects=$(curl $publicUrl/$container -X GET -H "Content-Length: 0" -H "X-Auth-Token: $authToken")
  # Delete all objects in the container
  for object in $objects
  do
    echo "Deleting $object..."
    curl -i $publicUrl/$container/$object -X DELETE -H "Content-Length: 0" -H "X-Auth-Token: $authToken"
  done
  # Now delete the container (note this operation fails unless the container is empty)
  echo "Deleting $container..."
  curl -i $publicUrl/$container -X DELETE -H "Content-Length: 0" -H "X-Auth-Token: $authToken"
done

# Create and configure containers
declare -a containers=($container1 $container2 $container3 $container4 $container5)

for container in "${containers[@]}"; do
  # Create container
  curl -i $publicUrl/$container -X PUT -H "Content-Length: 0" -H "X-Auth-Token: $authToken"
  # Configure container for web hosting
  curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Meta-Web-Listings: true"
  # Configure container for public access
  curl -i $publicUrl/$container -X POST -H "Content-Length: 0" -H "X-Auth-Token: $authToken" -H  "X-Container-Read: .r:*,.rlistings"
done

# Upload images to containers
# Note that container4 does not have any images
imagesFolder=$scriptsFolder/images
echo "imagesFolder: $imagesFolder"
declare -a images=("$container1:person.png:image/png" "$container1:flower_1.png:image/png" "$container1:church.png:image/png" \
  "$container2:road.png:image/png" "$container2:flower_2.png:image/png" "$container2:city.png:image/png" "$container2:bridge.png:image/png" \
  "$container3:nature.png:image/png" "$container3:concert.png:image/png")

for record in "${images[@]}"; do
  IFS=':' read -ra image <<< "$record"
  container=${image[0]}
  fileName=${image[1]}
  contentType=${image[2]}
  echo "Uploading $fileName to $container..."
  echo "curl -i $publicUrl/$container/$fileName --data-binary @$imagesFolder/$fileName -X -PUT -H Content-Type: $contentType -H X-Auth-Token: $authToken"
  curl -i $publicUrl/$container/$fileName --data-binary @$imagesFolder/$fileName -X PUT -H "Content-Type: $contentType" -H "X-Auth-Token: $authToken"
done

echo
echo "Finished populating object storage."
