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
bx cr namespace-add $CONTAINER_REGISTRY_NAMESPACE

### Check Helm/Tiller

echo "Checking Tiller (Helm's server component)"
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

echo ""
echo "${bold}Deploying IBM Cloud Services${normal}"
$SCRIPTS_FOLDER/Deployment/create_services.sh
