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

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/config.sh

echo ""
echo "${bold}Binding IBM Cloud Services to Cluster${normal}"

services=( "BluePic-Cloudant" "BluePic-Object-Storage" "BluePic-App-ID" "BluePic-IBM-Push" "BluePic-Weather-Company-Data" "BluePic-Visual-Recognition" )

for service in "${services[@]}"
do
  bx cs cluster-service-bind $KUBERNETES_CLUSTER_NAME default $service || { echo "Failed to bind service:" ${bold}$service${normal}; }
done
