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

scriptsFolder=$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )

### Deploy Services
$scriptsFolder/Deployment/services.sh

### Deploy App
echo "Deploying App to Bluemix. This could take awhile.."
bx dev deploy

route=$(bx app show bluepic | grep routes | sed 's/routes:[ ]*//')
echo "After you populate your database, you may view the application at: http://$route/"
