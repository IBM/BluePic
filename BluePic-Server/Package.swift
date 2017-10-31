// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
 * Copyright IBM Corporation 2017
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
 */

import PackageDescription

let package = Package(
    name: "BluePic-Server",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BluePic-Server",
            targets: ["BluePicApp", "BluePicServer"]
        )
    ],
    dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.0.0")),
      .package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", .upToNextMinor(from: "1.7.0")),
      .package(url: "https://github.com/IBM-Swift/CloudEnvironment.git", .upToNextMajor(from: "4.0.0")),
      .package(url: "https://github.com/IBM-Bluemix/cf-deployment-tracker-client-swift.git", .upToNextMajor(from: "4.0.0")),
      .package(url: "https://github.com/ibm-bluemix-mobile-services/bluemix-simple-http-client-swift.git", .upToNextMinor(from: "0.7.0")),
      .package(url: "https://github.com/ibm-bluemix-mobile-services/bluemix-objectstorage-serversdk-swift.git", .upToNextMinor(from: "0.8.0")),
      .package(url: "https://github.com/ibm-bluemix-mobile-services/bms-pushnotifications-serversdk-swift.git", .upToNextMinor(from: "0.6.0")),
      .package(url: "https://github.com/ibm-cloud-security/appid-serversdk-swift.git", .upToNextMinor(from: "2.0.0")),
      .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", .upToNextMinor(from: "2.0.0")),
      .package(url: "https://github.com/IBM-Swift/SwiftyRequest", .upToNextMajor(from: "0.0.0"))
    ],
    targets: [
        .target(
            name: "BluePicApp",
            dependencies: [ "Kitura",
                            "CouchDB",
                            "CloudEnvironment",
                            "BluemixObjectStorage",
                            "BluemixAppID",
                            "CloudFoundryDeploymentTracker",
                            "CredentialsFacebook",
                            "BluemixPushNotifications",
                            "SwiftyRequest"
                          ]
        ),
        .target(
            name: "BluePicServer",
            dependencies: ["BluePicApp"]
        ),
        .testTarget(
            name: "BluePicAppTests",
            dependencies: ["BluePicServer", "SwiftyRequest"]
        )
    ]
)
