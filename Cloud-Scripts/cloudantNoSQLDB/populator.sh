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

# Set scripts folder variable
scriptsFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "scriptsFolder: $scriptsFolder"

# Parse input parameters
source $scriptsFolder/parse_inputs.sh

# Variables (object storage - these are needed for storing URL in Cloudant database)
accessPoint=dal.objectstorage.open.softlayer.com
publicUrl=https://$accessPoint/v1/AUTH_$projectid

# Load images JSON file and expand variables in the JSON document
# As a reference, see http://stackoverflow.com/questions/10683349/forcing-bash-to-expand-variables-in-a-string-loaded-from-a-file
imagesJSON=$(<$scriptsFolder/images.json)
delimiter="__apply_shell_expansion_delimiter__"
imagesJSON=`eval "cat <<$delimiter"$'\n'"$imagesJSON"$'\n'"$delimiter"`

# Delete bluepic_db just in case it already exists (we need a clean slate)
curl -X DELETE https://$username.cloudant.com/$database -u $username:$password

# Create bluepic_db
curl -X PUT https://$username.cloudant.com/$database -u $username:$password

# Upload design document
curl -X PUT "https://$username.cloudant.com/bluepic_db/_design/main_design" -u $username:$password -d @$scriptsFolder/main_design.json

# Create user documents
curl -H "Content-Type: application/json" -d @$scriptsFolder/users.json -X POST https://$username.cloudant.com/$database/_bulk_docs -u $username:$password

# Create image documents
curl -H "Content-Type: application/json" --data "$imagesJSON" -X POST https://$username.cloudant.com/$database/_bulk_docs -u $username:$password

# Images are now stored in Object Storage; keeping the code below as reference
# Upload attachments (images)
<<COMMENT1
imagesFolder=`dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`/images
declare -a attachments=('image/png' '2000' 'rush.png' 'image/png' '2001' 'bridge.png' 'image/png' '2002' 'car.png' 'image/png' '2003' 'church.png' \
  'image/png' '2004' 'city.png' 'image/png' '2005' 'concert.png' 'image/png' '2006' 'flower_1.png' 'image/png' '2007' 'flower_2.png' \
  'image/png' '2008' 'nature.png' 'image/png' '2009' 'person.png' 'image/png' '2010' 'road.png');

index=0
while [ $index -lt ${#attachments[@]} ]; do
  contentType=${attachments[$index]}
  let index+=1
  imageId=${attachments[$index]}
  let index+=1
  fileName=${attachments[$index]}
  # Get revision number from image document
  revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/$imageId -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
  # Upload image file to image document as an attachment
  curl -v -H "Content-Type: $contentType" --data-binary @$imagesFolder/$fileName -X PUT "https://$username.cloudant.com/$database/$imageId/$fileName?rev=$revNumber" -u $username:$password
  let index+=1
done
COMMENT1

echo
echo "Finished populating cloudant database '$database'."
