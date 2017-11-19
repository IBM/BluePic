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
set -e

### Environment Variables
bold=$(tput bold)
normal=$(tput sgr0)
CHART_NAME="bluepic"
KUBERNETES_CLUSTER_NAME="BluePic-Cluster"
CONTAINER_REGISTRY_NAMESPACE="bluepic_container_registry"
DEPLOY_IMAGE_TARGET="registry.ng.bluemix.net/$CONTAINER_REGISTRY_NAMESPACE/bluepic"
SCRIPTS_FOLDER=$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )

### Setup

echo "${bold}Deploying BluePic as a Kubernetes Cluster application${normal}"
echo ""
echo "${bold}Setting up IBM Cloud Kubernetes Cluster Environment${normal}"

echo "Checking cluster availability"
ip_addr=$(bx cs workers $KUBERNETES_CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $ip_addr ]; then
    echo "$KUBERNETES_CLUSTER_NAME not created or workers not ready"
    exit 1
fi

echo "Checking Container Registry Namespace"
bx cr namespace-add $CONTAINER_REGISTRY_NAMESPACE || { echo 'Failed to create container registry namespace' ; exit 1; }

### Check Helm/Tiller

echo "Checking Tiller (Helm's server component)"
helm init --upgrade || { echo 'Helm init failed' ; exit 1; }
while true; do
    tiller_deployed=$(kubectl --namespace=kube-system get pods | grep tiller | grep Running | grep 1/1 )
    if [[ "${tiller_deployed}" != "" ]]; then
        echo "Tiller ready."
        break;
    fi
    echo "Waiting for Tiller to be ready."
    sleep 1
done
helm version

### Deploy Services

echo ""
echo "${bold}Deploying IBM Cloud Services${normal}"
$SCRIPTS_FOLDER/Deployment/create_services.sh

sleep 30 ### Allow services time to instantiate

### Bind Services

echo ""
echo "${bold}Binding IBM Cloud Services to Cluster${normal}"
services=( "BluePic-Cloudant" "BluePic-Object-Storage" "BluePic-App-ID" "BluePic-IBM-Push" ) # "BluePic-Weather-Company-Data" "BluePic-Visual-Recognition" )
for service in "${services[@]}"
do
  bx cs cluster-service-bind $KUBERNETES_CLUSTER_NAME default $service || { echo 'Failed to bind service:' $service ; exit 1; }
done


### Deploy App

echo ""
echo "${bold}Deploying IBM Cloud Services${normal}"
bx dev deploy --target=container --deploy-image-target=registry.ng.bluemix.net/$CONTAINER_REGISTRY_NAMESPACE/bluepic --ibm-cluster=$KUBERNETES_CLUSTER_NAME || { echo 'Failed to deploy application' ; exit 1; }

### Display Public IP and Kubernetes Information

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
