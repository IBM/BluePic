IBM Bluemix Mobile Services - Client SDK Swift Analytics
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics-api.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics-api)
[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics-api.svg?branch=development)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics-api)

This is the analytics and logger component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/services/mobile.html).


## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7


## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).

#### Cocoapods
To install BMSAnalytics using Cocoapods, add it to your Podfile:

```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSAnalytics'
end
```

Then run the `pod install` command.

#### Carthage
To install BMSAnalytics using Carthage, add it to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics"
```

Then run the `carthage update` command. Once the build is finished, drag the `BMSAnalytics.framework`, `BMSCore.framework`, and `BMSAnalyticsAPI.framework` files into your Xcode project. 

To complete the integration, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).


=======================
Copyright 2015 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
