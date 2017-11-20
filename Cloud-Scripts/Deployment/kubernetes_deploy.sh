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
set -e

### Environment Variables

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/config.sh

### Deploy App

echo ""
echo "${bold}Deploying IBM Cloud Application${normal}"
bx dev deploy --target=container --deploy-image-target=registry.ng.bluemix.net/$CONTAINER_REGISTRY_NAMESPACE/bluepic --ibm-cluster=$KUBERNETES_CLUSTER_NAME

### Display Public IP and Kubernetes Information
ip_addr=$(bx cs workers $KUBERNETES_CLUSTER_NAME | grep normal | awk '{ print $2 }')
port=$(kubectl get services | grep ${CHART_NAME} | sed 's/.*:\([0-9]*\).*/\1/g')

echo ""
echo "${bold}DEPLOYED SERVICES${normal}"
kubectl describe services ${CHART_NAME}

echo ""
echo "To see further information on your deployed pods execute: "
echo "${bold}kubectl describe pods --selector app=${CHART_NAME}-selector${normal}"
echo ""
echo "You may also view the kubernetes interface by running '${bold}kubectl proxy${normal}' and visiting ${bold}http://localhost:8001/ui${normal}"
echo ""
echo "After populating your database, you may view the application at: ${bold}http://$ip_addr:$port${normal}"
