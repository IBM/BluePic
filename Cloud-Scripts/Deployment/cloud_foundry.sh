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

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/config.sh

echo "${bold}Deploying BluePic as a Cloud Foundry Cluster application${normal}"
echo ""
echo "${bold}Deploying IBM Cloud Services${normal}"

### Deploy Services

$SCRIPTS_FOLDER/Deployment/create_services.sh

### Deploy App

echo ""
echo "${bold}Deploying App to Bluemix.${normal} This could take awhile.."
bx dev deploy

route=$(bx app show bluepic | grep routes | sed 's/routes:[ ]*//')
echo "After you populate your database, you may view the application at: ${bold}http://$route/${normal}"
