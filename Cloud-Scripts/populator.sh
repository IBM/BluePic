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

CLOUDANT_FOLDER=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`/cloudantNoSQLDB
OBJECT_STORAGE_FOLDER=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`/Object-Storage
$CLOUDANT_FOLDER/populator.sh --username="17a087a4-2b69-49ed-bc13-de56b30a0fe1-bluemix" --password="ee8143dd2314aeebdcec7d4a712665753b0fe10ec3d70fc2a722a8431c77ec3e" --projectId="ed9137272c0443ccbb17f4c8944e352f"
$OBJECT_STORAGE_FOLDER/populator.sh --userId="cc5f98d4a5594c78b23f9e7b2afe3525" --password="wBI.G#!YSM{4-i9w" --projectId="ed9137272c0443ccbb17f4c8944e352f" --region="dallas"
