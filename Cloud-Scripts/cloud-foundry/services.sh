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

# Delete services first
echo "Deleting services..."
cf delete-service -f "BluePic-Cloudant"
cf delete-service -f "BluePic-Object-Storage"
cf delete-service -f "BluePic-Mobile-Client-Access"
cf delete-service -f "BluePic-IBM-Push"
cf delete-service -f "BluePic-Insights-for-Weather"
cf delete-service -f "BluePic-Alchemy"
echo "Services deleted."

# Create services
echo "Creating services..."
cf create-service cloudantNoSQLDB Shared "BluePic-Cloudant"
cf create-service Object-Storage Free "BluePic-Object-Storage"
cf create-service AdvancedMobileAccess Gold "BluePic-Mobile-Client-Access"
cf create-service imfpush Basic "BluePic-IBM-Push"
cf create-service weatherinsights Free-v2 "BluePic-Insights-for-Weather"
cf create-service alchemy_api free "BluePic-Alchemy"
echo "Services created."
