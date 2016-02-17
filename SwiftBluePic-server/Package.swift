/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import PackageDescription

let package = Package(
    name: "SwiftBluePic-server",
          dependencies: [
               .Package(url: "git@github.com:IBM-Swift/Kitura-router.git", majorVersion: 0),
               .Package(url: "git@github.com:IBM-Swift/Kitura-CouchDB.git", majorVersion: 0),
               .Package(url: "git@github.com:IBM-Swift/Kitura-redis.git", majorVersion: 0),
          ]
)

