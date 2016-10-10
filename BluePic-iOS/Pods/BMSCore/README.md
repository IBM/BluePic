IBM Bluemix Mobile Services - Client SDK Swift Core
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core)
[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.svg?branch=development)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core)

This is the core component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/index.html).



## Contents
This package contains the core components of the Swift SDK.

* HTTP Infrastructure
* Security and Authentication interfaces
* Logger and Analytics interfaces



## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7.3, 8.0
* Swift 2.2 - 3.0



## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).


### Cocoapods
To install BMSCore using Cocoapods, add it to your Podfile:

```ruby
use_frameworks!

target 'MyApp' do
    pod 'BMSCore'
end
```

Then run the `pod install` command.

#### Xcode 8

Before running the `pod install` command, make sure to use the latest Cocoapods [pre-release version](https://github.com/CocoaPods/CocoaPods/releases).

If you receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSCore), **do not** convert BMSCore or BMSAnalyticsAPI.


### Carthage
To install BMSCore using Carthage, add it to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-core"
```

Then run the `carthage update` command. Once the build is finished, drag `BMSCore.framework` and `BMSAnalyticsAPI.framework` into your Xcode project. 

To complete the integration, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3`. Otherwise, use `carthage update`.



## Usage Examples


### Swift 2.2

```Swift
// Initialize BMSClient

let appRoute = "https://myapp.mybluemix.net"
let appGuid = "2fe35477-5410-4c87-1234-aca59511433b"
let bluemixRegion = BMSClient.Region.usSouth

BMSClient.sharedInstance.initialize(bluemixAppRoute: appRoute,
	                            bluemixAppGUID: appGuid,
	                            bluemixRegion: bluemixRegion)
	                               
let logger = Logger.logger(name: "My Logger")

// Make a network request

let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)

let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
request.allHTTPHeaderFields = ["foo":"bar"]

let dataTask = urlSession.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
    if let httpResponse = response as? NSHTTPURLResponse {
        logger.info(message: "Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
        logger.info(message: "Response data: \(responseString)")
    }
    if let error = error {
        logger.error(message: "Error: \(error)")
    }
}

dataTask.resume()
```


### Swift 3.0

```Swift
// Initialize BMSClient

let appRoute = "https://myapp.mybluemix.net"
let appGuid = "2fe35477-5410-4c87-1234-aca59511433b"
let bluemixRegion = BMSClient.Region.usSouth

BMSClient.sharedInstance.initialize(bluemixAppRoute: appRoute,
	                            bluemixAppGUID: appGuid,
	                            bluemixRegion: bluemixRegion)
	                            
let logger = Logger.logger(name: "My Logger")

// Make a network request

let urlSession = BMSURLSession(configuration: .default, delegate: nil, delegateQueue: nil)

var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
request.httpMethod = "GET"
request.allHTTPHeaderFields = ["foo":"bar"]

let dataTask = urlSession.dataTaskWithRequest(request) { (data: Data?, response: URLResponse?, error: Error?) in
    if let httpResponse = response as? HTTPURLResponse {
        logger.info(message: "Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = String(data: data!, encoding: .utf8) {
        logger.info(message: "Response data: \(responseString)")
    }
    if let error = error {
        logger.error(message: "Error: \(error)")
    }
}
```

> By default the Bluemix Mobile Service SDK internal debug logging will not be printed to Xcode console. If you want to enable SDK debug logging output set the `Logger.sdkDebugLoggingEnabled` property to `true`.


### Disabling Logging output for production applications

By default the Logger class will print its logs to Xcode console. If is advised to disable Logger output for applications built in release mode. In order to do so add a debug flag named `RELEASE_BUILD` to your release build configuration. One of the way of doing so is adding `-D RELEASE_BUILD` to `Other Swift Flags` section of the project build configuration.



=======================
Copyright 2016 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
