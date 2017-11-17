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

#!/bin/bash
#set -x

KUBERNETES_CLUSTER_NAME="BluePic-Cluster"
CLUSTER_NAMESPACE="bluepic"
CHART_NAME="bluepic"
DEPLOY_IMAGE_TARGET="registry.ng.bluemix.net/$CLUSTER_NAMESPACE/bluepic"
SCRIPTS_FOLDER=$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )

echo "Check cluster availability"
ip_addr=$(bx cs workers $KUBERNETES_CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $ip_addr ]; then
    echo "$KUBERNETES_CLUSTER_NAME not created or workers not ready"
    exit 1
fi

echo "Check cluster target namespace"
if ! kubectl get namespace $CLUSTER_NAMESPACE ; then
    echo "$CLUSTER_NAMESPACE cluster namespace does not exist, creating it"
    kubectl create namespace $CLUSTER_NAMESPACE
fi

# Check Helm/Tiller
echo "CHECKING TILLER (Helm's server component)"
helm init --upgrade
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
$SCRIPTS_FOLDER/Deployment/services.sh

### Deploy App
echo $DEPLOY_IMAGE_TARGET
bx dev deploy --target="container" --deploy-image-target=$DEPLOY_IMAGE_TARGET --ibm-cluster=$KUBERNETES_CLUSTER_NAME

bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-Cloudant"
bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-Object-Storage"
bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-App-ID"
bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-IBM-Push"
bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-Weather-Company-Data"
bx cs cluster-service-bind BluePic-Cluster "bluepic" "BluePic-Visual-Recognition"

## Display Public IP
echo ""
echo "DEPLOYED SERVICE:"
kubectl describe services ${CHART_NAME}
kubectl describe services "bluepic" --namespace "bluepic"

echo ""
echo "DEPLOYED PODS:"
kubectl describe pods --selector app=${CHART_NAME}-selector

port=$(kubectl get services | grep ${CHART_NAME} | sed 's/.*:\([0-9]*\).*/\1/g')
echo $port
echo ""
echo "After you populate your database, you may view the application at: http://$ip_addr:$port"
