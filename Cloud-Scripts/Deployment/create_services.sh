#!/bin/bash

##
# Copyright IBM Corporation 2017
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
bx service delete -f "BluePic-Cloudant"
bx service delete -f "BluePic-Object-Storage"
bx service delete -f "BluePic-App-ID"
bx service delete -f "BluePic-IBM-Push"
bx service delete -f "BluePic-Weather-Company-Data"
bx service delete -f "BluePic-Visual-Recognition"
echo "Services deleted."

# Create services
echo "Creating services..."
bx service create cloudantNoSQLDB Lite "BluePic-Cloudant"
bx service create Object-Storage Free "BluePic-Object-Storage"
bx service create AppID "Graduated tier" "BluePic-App-ID"
bx service create imfpush Basic "BluePic-IBM-Push"
bx service create weatherinsights Free-v2 "BluePic-Weather-Company-Data"
bx service create watson_vision_combined free "BluePic-Visual-Recognition"
echo "Services created."
