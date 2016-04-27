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

# Parse input parameters
source ./parse_inputs.sh

# Delete bluepic_db just in case it already exists (we need a clean slate)
curl -X DELETE https://$username.cloudant.com/$database -u $username:$password

# Create bluepic_db
curl -X PUT https://$username.cloudant.com/$database -u $username:$password

# Upload design document
curl -X PUT "https://$username.cloudant.com/bluepic_db/_design/main_design" -u $username:$password -d @main_design.json

# Create user documents
curl -H "Content-Type: application/json" -d @users.json -X POST https://$username.cloudant.com/$database/_bulk_docs -u $username:$password

# Create image documents
curl -H "Content-Type: application/json" -d @images.json -X POST https://$username.cloudant.com/$database/_bulk_docs -u $username:$password

# Upload attachments (images)
declare -a attachments=('image/png' '2000' 'swift.png' 'image/jpg' '2001' 'genesis.jpg' 'image/jpg' '2002' 'tombstone.jpg' 'image/jpg' '2003' 'rush-logo.jpg' 'image/jpg' '2004' 'rush.jpg' 'image/jpg' '2005' 'within-temptation.jpg');
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
  curl -v -H "Content-Type: $contentType" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/images/$fileName -X PUT "https://$username.cloudant.com/$database/$imageId/$fileName?rev=$revNumber" -u $username:$password
  let index+=1
done

echo
echo "Successfully finished populating cloudant database '$database'."
