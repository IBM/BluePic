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

for i in "$@"
do
case $i in
    --userid=*)
    userid="${i#*=}"
    shift # past argument=value
    ;;
    --password=*)
    password="${i#*=}"
    shift # past argument=value
    ;;
    --projectid=*)
    projectid="${i#*=}"
    shift # past argument=value
    ;;
    *)
        # unknown option
    ;;
esac
done

# Variables (tmp)
#userid=69435710c71c4ed2b78856520f9cae25
#password=F*nt4gmY-Oss4{v.
#projectid=742fffae2c24438b83a2c43491119a82

echo "Variables:"
echo -e "  userid: $userid"
echo -e "  projectid: $projectid"
