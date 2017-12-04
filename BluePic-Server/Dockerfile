##
# Copyright IBM Corporation 2016, 2017
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

# Builds a Docker image with all the dependencies for compiling and running the BluePic-iOS sample application.

FROM ibmcom/swift-ubuntu:4.0.2
MAINTAINER IBM Swift Engineering at IBM Cloud
LABEL Description="Docker image for building and running the BluePic sample application."

# Expose default port for Kitura
EXPOSE 8080

RUN mkdir /BluePic-Server

ADD /BluePic-Server/BluePic-Web /BluePic-Server/BluePic-Web
ADD /BluePic-Server/config /BluePic-Server/config
ADD /BluePic-Server/Sources /BluePic-Server/Sources
ADD /BluePic-Server/Tests /BluePic-Server/Tests
ADD /BluePic-Server/public /BluePic-Server/public
ADD /BluePic-Server/Package.swift /BluePic-Server
ADD /BluePic-Server/Package.resolved /BluePic-Server
ADD /BluePic-Server/.swift-version /BluePic-Server
RUN cd /BluePic-Server && swift build

CMD [ "sh", "-c", "cd /BluePic-Server && .build/x86_64-unknown-linux/debug/BluePicServer" ]
