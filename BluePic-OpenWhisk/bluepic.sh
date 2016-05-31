#!/bin/bash
#
# Copyright 2016 IBM Corp. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#  https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
 
# Color vars to be used in shell script output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
 
# load configuration variables
source local.env

# capture the namespace where actions will be created
# as we need to pass it to our change listener
CURRENT_NAMESPACE=`wsk property get --namespace | awk '{print $3}'`
echo "Current namespace is $CURRENT_NAMESPACE."

function usage() {
  echo -e "${YELLOW}Usage: $0 [--install,--uninstall,--reinstall,--env]${NC}"
}

function install() {
  echo -e "${YELLOW}Installing OpenWhisk actions for BluePic..."
  
  echo "Creating package"
  wsk package create bluepic
  
  echo "Adding VCAP_SERVICES as parameter"
  wsk package update bluepic\
    -p alchemyKey $ALCHEMY_key\
    -p weatherUsername $WEATHER_username\
    -p weatherPassword $WEATHER_password\
    -p cloudantHost $CLOUDANT_host\
    -p cloudantUsername $CLOUDANT_username\
    -p cloudantPassword $CLOUDANT_password\
    -p cloudantDbName $CLOUDANT_db

  echo "Creating actions"
  #this is just a test action to make sure we can make HTTP requests leveraging kitura networking
  wsk action create --kind swift:3 bluepic/prepareReadImage actions/PrepareToReadImage.swift
  wsk action create --kind swift:3 bluepic/prepareWeatherRequest actions/PrepareWeatherRequest.swift
  wsk action create --kind swift:3 bluepic/prepareCloudantWrite actions/PrepareToWriteImage.swift
  wsk action create --kind swift:3 bluepic/httpGet actions/HttpGet.swift
  wsk action create --kind swift:3 bluepic/weather actions/Weather.swift
  wsk action create --kind swift:3 bluepic/alchemy actions/Alchemy.swift
  wsk action create --kind swift:3 bluepic/cloudantRead actions/CloudantRead.swift
  wsk action create --kind swift:3 bluepic/cloudantWrite actions/CloudantWrite.swift
  wsk action create --kind swift:3 bluepic/processImage actions/Stub.swift
  
  
  #create sequences to tie everything together - lots of these are for testing
  wsk action create bluepic/processRequest --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest,bluepic/weather,bluepic/alchemy,bluepic/prepareCloudantWrite,bluepic/cloudantWrite
  wsk action create bluepic/processRequestThroughCloudantWrite --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest,bluepic/weather,bluepic/alchemy,bluepic/prepareCloudantWrite,bluepic/cloudantWrite
  wsk action create bluepic/processRequestToCloudantWrite --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest,bluepic/weather,bluepic/alchemy,bluepic/prepareCloudantWrite
  wsk action create bluepic/processRequestThroughAlchemy --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest,bluepic/weather,bluepic/alchemy
  wsk action create bluepic/processRequestThroughWeather --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest,bluepic/weather
  wsk action create bluepic/processRequestToWeather --sequence bluepic/prepareReadImage,bluepic/cloudantRead,bluepic/prepareWeatherRequest
  wsk action create bluepic/processRequestThroughReadImage --sequence bluepic/prepareReadImage,bluepic/cloudantRead
  wsk action create bluepic/processRequestToReadImage --sequence bluepic/prepareReadImage
  wsk action create bluepic/processRequestThroughReadUser --sequence bluepic/prepareReadUser,bluepic/cloudantRead
  wsk action create bluepic/processFinalWrite --sequence bluepic/prepareCloudantWrite,bluepic/cloudantWrite
  
  echo -e "${GREEN}Install Complete${NC}"
  wsk list
}

function uninstall() {
  echo -e "${RED}Uninstalling..."
  
  echo "Removing actions..."
  wsk action delete bluepic/prepareReadImage
  wsk action delete bluepic/prepareWeatherRequest
  wsk action delete bluepic/prepareCloudantWrite
  wsk action delete bluepic/httpGet
  wsk action delete bluepic/weather
  wsk action delete bluepic/alchemy
  wsk action delete bluepic/cloudantRead
  wsk action delete bluepic/cloudantWrite
  wsk action delete bluepic/processImage
  
  wsk action delete bluepic/processRequest
  wsk action delete bluepic/processRequestThroughCloudantWrite
  wsk action delete bluepic/processRequestToCloudantWrite
  wsk action delete bluepic/processRequestThroughAlchemy
  wsk action delete bluepic/processRequestThroughWeather
  wsk action delete bluepic/processRequestToWeather
  wsk action delete bluepic/processRequestThroughReadImage
  wsk action delete bluepic/processRequestToReadImage
  wsk action delete bluepic/processRequestThroughReadUser
  wsk action delete bluepic/processFinalWrite
  
  wsk package delete bluepic
  
  echo -e "${GREEN}Uninstall Complete${NC}"
  wsk list
}

function showenv() {
  echo -e "${YELLOW}"
  echo CLOUDANT_username=$CLOUDANT_username
  echo CLOUDANT_password=$CLOUDANT_password
  echo CLOUDANT_host=$CLOUDANT_host
  echo CLOUDANT_db=$CLOUDANT_db
  echo ALCHEMY_key=$ALCHEMY_key
  echo WEATHER_username=$WEATHER_username
  echo WEATHER_password=$WEATHER_password
  echo -e "${NC}"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--update" )
update
;;
"--reinstall" )
uninstall
install
;;
"--env" )
showenv
;;
* )
usage
;;
esac