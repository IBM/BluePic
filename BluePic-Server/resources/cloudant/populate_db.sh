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

# Delete bluepic_db just in case it already exists (we need a clean slate)
curl -X DELETE https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3

# Create bluepic_db
curl -X PUT https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3

# Upload design document
./upload_design_doc.sh

# Create user documents
curl -H "Content-Type: application/json" -d @users.json -X POST https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db/_bulk_docs -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3

# Create image documents
curl -H "Content-Type: application/json" -d @images.json -X POST https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db/_bulk_docs -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3

# Upload attachments (images)
revNumber=`curl -H "Content-Type: application/json" --head https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db/2000 -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3 | grep Etag | awk '{print $2}' | tr -cd '[[:alnum:]]._-'`
curl -v -H "Content-Type: image/png" --data-binary @/Users/olivieri/git/BluePic-IBM-Swift/BluePic-Server/resources/imgs/swift.png -X PUT "https://d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com/bluepic_db/2000/swift.png?rev=$revNumber" -u d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix:f2c7c6a70784057bf8ab86a3ae5c9ac7129fedf67619f243eb030058764792e3
