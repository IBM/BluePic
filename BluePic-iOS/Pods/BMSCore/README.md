IBM Bluemix Mobile Services - Client SDK Swift Core
===================================================

This is the core component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/services/mobile.html).

## Contents
This package contains the core components of the Swift SDK.

* HTTP Infrastructure
* Security and Authentication interfaces
* Logger and Analytics interfaces

## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7

## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).

#### Cocoapods
To install BMSCore using Cocoapods, add it to your Podfile:

```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSCore'
end
```

Then run the `pod install` command.

#### Carthage
To install BMSCore using Carthage, add it to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-core"
```

Then run the `carthage update` command. Once the build is finished, drag `BMSCore.framework` and `BMSAnalyticsAPI.framework` into your Xcode project. 

To complete the integration, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

## Usage Examples

```Swift
let appRoute = "https://greatapp.mybluemix.net"
let appGuid = "2fe35477-5410-4c87-1234-aca59511433b"
let bluemixRegion = BMSClient.REGION_US_SOUTH

BMSClient.sharedInstance
	.initializeWithBluemixAppRoute(appRoute,
	                               bluemixAppGUID: appGuid,
	                               bluemixRegion: bluemixRegion)

let request = Request(url: "/", method: HttpMethod.GET)
request.headers = ["foo":"bar"]
request.queryParameters = ["foo":"bar"]

request.sendWithCompletionHandler { (response, error) -> Void in
	if let error = error {
		print ("Error :: \(error)")
	} else {
		print ("Success :: \(response?.responseText)")
	}
}

let logger = Logger.loggerForName("FirstLogger")

logger.debug("This is a debug message")
logger.error("This is an error message")
logger.info("This is an info message")
logger.warn("This is a warning message")

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
