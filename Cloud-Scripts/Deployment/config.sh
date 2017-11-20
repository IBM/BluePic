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

## Styles
bold=$(tput bold)
normal=$(tput sgr0)

## Variables
CHART_NAME="bluepic"
KUBERNETES_CLUSTER_NAME="BluePic-Cluster"
CONTAINER_REGISTRY_NAMESPACE="bluepic_container_registry"
DEPLOY_IMAGE_TARGET="registry.ng.bluemix.net/$CONTAINER_REGISTRY_NAMESPACE/bluepic"

## Folders
SCRIPTS_FOLDER=$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )
