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
$cloudantFolder/populator.sh --username="ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix" --password="390dcb82f98254d397deb397d29d202040d3e9249c3ff17aca6b2d469ae80ed7" --projectId="bf24aff817b2420c863b1abe3c877694"
$objectStorageFolder/populator.sh --userId="2151033288c1404fa53dc6060b65d28a" --password="azTr/{.9pC07IYR~" --projectId="bf24aff817b2420c863b1abe3c877694" --region="dallas"
