IBM Bluemix Mobile Services - AnalyticsApi Swift SDK
===================================================

## Contents
This package contains the AnalyticsAPI component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/services/mobile.html)

The package includes

* Logger and Analytics interfaces
* Client side Logger implementation
* Empty stubs for server side related Logger and Analytics functionality. In order to leverage server side functionality you'll need to provision a Mobile Analytics service instance and import [BMSAnalytics SDK](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics)

## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7+

## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/). 

While it is possible to install the `BMSAnalyticsAPI` pod as a stand-alone component the recommended way is to install the `BMSCore` pod, which will include `BMSAnalyticsAPI` as a dependency. Once one of the the above pods is installed you can start using BMSAnalyticsAPI.

Update your Podfile with the pod you want to use and run `pod install`.

##### iOS
```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSCore'
end
```

##### watchOS
```ruby
use_frameworks!

target 'MyApp WatchKit Extension' do
    platform :watchos, '2.0'
    pod 'BMSCore'
end
```

## Usage Examples

```Swift
let logger1 = Logger.loggerForName("FirstLogger")
let logger2 = Logger.loggerForName("SecondLogger")

logger1.debug("This is a debug message")
logger2.error("This is an error message")
logger1.info("This is an info message")
logger2.warn("This is a warning message")
logger1.fatal("This is a fatal message. It is used internally to report application crashes")
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
