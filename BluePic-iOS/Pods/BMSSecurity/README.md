IBM Bluemix Mobile Services - Client SDK Swift Security
===================================================

This is the security component of the Swift SDK for [IBM Bluemix Mobile Services] (https://console.ng.bluemix.net/docs/mobile/index.html).


## Requirements
* iOS 8.0 or later
* Xcode 7


## Installation
The Bluemix Mobile Services Swift SDK is available via [Cocoapods](http://cocoapods.org/).
To install, add the `BMSSecurity` pod to your Podfile.

##### iOS
```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSSecurity'
end
```
## Getting started

To use the Bluemix Mobile Services Swift SDK, add the following imports in the class which you want to use it in:

```Swift
import BMSCore
import BMSSecurity
```

Connectivity and interaction between your mobile app and the Bluemix services depends on the application ID and application route that are associated with Bluemix application.

The BMSClient and MCAAuthorizationManager API are the entry points for interacting with the SDK. You must invoke the following API before any other API calls:

```Swift
MCAAuthorizationManager.sharedInstance.initialize(tenantId: tenantId, bluemixRegion: regionName)
```

 This method is usually called in the application delegate of your mobile app.

You also need to define MCAAuthorizationManager as your authorization manager:
```Swift
BMSClient.sharedInstance.authorizationManager = MCAAuthorizationManager.sharedInstance
```
Then you have to register an Authentication Delegate to the MCAAuthorizationManager as follows:

```Swift
let mcaAuthManager = MCAAuthorizationManager.sharedInstance
mcaAuthManager.registerAuthenticationDelegate(<delegate>, realm: <realm>)
```

In order to logout the current logged in user, you can use the following code:
```Swift
mcaAuthManager.logout(<callBack>)
```

## Sample app
You can use 'pod try BMSSecurity' to get a sample application. A readme file with details on how to run the sample application is available in the app's folder.

## Known limitation
Currently Swift SDK does not submit monitoring data. This is a work in progress and will be delivered in following months. If you’d like to continue receiving monitoring data in the service dashboard you can continue using Objective-C SDK.

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
