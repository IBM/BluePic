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
revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2000 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/png" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/swift.png -X PUT "https://$username.cloudant.com/$database/2000/swift.png?rev=$revNumber" -u $username:$password

revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2001 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/jpg" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/genesis.jpg -X PUT "https://$username.cloudant.com/$database/2001/genesis.jpg?rev=$revNumber" -u $username:$password

revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2002 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/jpg" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/tombstone.jpg -X PUT "https://$username.cloudant.com/$database/2002/tombstone.jpg?rev=$revNumber" -u $username:$password

revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2003 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/jpg" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/rush-logo.jpg -X PUT "https://$username.cloudant.com/$database/2003/rush-logo.jpg?rev=$revNumber" -u $username:$password

revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2004 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/jpg" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/rush.jpg -X PUT "https://$username.cloudant.com/$database/2004/rush.jpg?rev=$revNumber" -u $username:$password

revNumber=`curl -H "Content-Type: application/json" --head https://$username.cloudant.com/$database/2005 -u $username:$password | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/jpg" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/within-temptation.jpg -X PUT "https://$username.cloudant.com/$database/2005/within-temptation.jpg?rev=$revNumber" -u $username:$password

echo
echo "Successfully finished populating cloudant database '$database'."
