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

cloudantFolder=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`/cloudantNoSQLDB
objectStorageFolder=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`/Object-Storage
$cloudantFolder/populator.sh --username="d4ae9f62-2765-4fe9-8053-659f0e81928f-bluemix" --password="4ba492fa3866992a0a093b919c74132e01fc99b3b7c6ea70bb83616defa3499b" --projectId="93682ef044ba4b54957ffc96c967b4c9"
$objectStorageFolder/populator.sh --userId="6a6fdf4bbaf84aec8544698d385e2969" --password="CJ5i6Ff)-Icp)xMi" --projectId="93682ef044ba4b54957ffc96c967b4c9" --region="dallas"
