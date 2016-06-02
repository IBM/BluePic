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

# Get all images
echo "Querying images view..."
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/images?include_docs=true&descending=true" -u $username:$password
echo
echo

# Get all users
echo "Querying users view..."
curl -X GET https://$username.cloudant.com/$database/_design/main_design/_view/users?include_docs=false -u $username:$password
echo
echo

# Get images per users
echo "Querying images_per_user view..."
curl -X GET https://$username.cloudant.com/$database/_design/main_design/_view/images_per_user -u $username:$password
echo
echo

echo "Querying images_per_user view for user 1000..."
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/images_per_user?include_docs=false&descending=true&endkey=[\"1000\"]&startkey=[\"1000\",{}]" -u $username:$password
echo
echo

echo "Querying images_by_id view for image 2000..."
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/images_by_id?include_docs=true&descending=false&startkey=[\"2000\",0]&endkey=[\"2000\",{}]" -u $username:$password
echo
echo

echo "Querying tags view"
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/tags?group=true&group_level=1" -u $username:$password
echo
echo

echo "Querying images_by_tags view (mountain)"
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/images_by_tags?include_docs=true&descending=true&reduce=false&endkey=[\"mountain\",\"0\",\"0\",0]&startkey=[\"mountain\",{}]" -u $username:$password
echo
echo

echo "Querying images_by_tags view (progressive rock)"
curl -g -X GET "https://$username.cloudant.com/$database/_design/main_design/_view/images_by_tags?include_docs=true&descending=true&reduce=false&endkey=[\"progressive%20rock\",\"0\",\"0\",0]&startkey=[\"progressive%20rock\",{}]" -u $username:$password
echo
echo

echo "Successfully finished querying views on cloudant database '$database'."
