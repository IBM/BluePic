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

cf create-service cloudantNoSQLDB Shared "Cloudant NoSQL DB-fz"
cf create-service Object-Storage standard "Object Storage-bv"
cf create-service AdvancedMobileAccess Gold "Mobile Client Access-ag"
cf create-service imfpush Basic "IBM Push Notifications-12"