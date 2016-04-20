IBM Bluemix Mobile Services - Client SDK Swift Push
===================================================

This is the Push component of the Swift SDK for IBM Bluemix Mobile Services. 

https://console.ng.bluemix.net/solutions/mobilefirst


## Contents

This package contains the Push components of the Swift SDK.
* Push Registration
* Subscribing and Unsubcribing for Tags


## Requirements

* iOS 8.0+ 
* Xcode 7


## Installation

The Bluemix Mobile Services Swift SDK is available via [Cocoapods](http://cocoapods.org/). 
To install, add the `BMSPush` pod to your `Podfile`. You have to add `BMSCore` also in your `Podfile`.

##### iOS

```Swift
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSCore'
    pod 'BMSPush'
end
```
From the Terminal, go to your project folder and install the dependencies with the following command:

```
pod update
```

That command installs your dependencies and creates a new Xcode workspace.
***Note:*** Ensure that you always open the new Xcode workspace, instead of the original Xcode project file:

```
open App.xcworkspace
```

## Enabling iOS applications to receive push notifications

##### Reference the SDK in your code.

```
import BMSPush
import BMSCore
```
#### Initializing the Core SDK

```
let myBMSClient = BMSClient.sharedInstance

myBMSClient.initializeWithBluemixAppRoute("BluemixAppRoute", bluemixAppGUID: "APPGUID", bluemixRegion:"Location where your app Hosted")
myBMSClient.defaultRequestTimeout = 10.0 // Timput in seconds

```
***AppRoute***

Specifies the route that is assigned to the server application that you created on Bluemix.

***AppGUID***

Specifies the unique key that is assigned to the application that you created on Bluemix. This value is 
case-sensitive.

***bluemixRegionSuffix***

Specifies the location where the app hosted. You can use one of three values - `BMSClient.REGION_US_SOUTH`, `BMSClient.REGION_UK` and `BMSClient.REGION_SYDNEY`.

#### Initializing the Push SDK

```
let push =  BMSPushClient.sharedInstance
```

#### Registering iOS applications and devices

Add this code to registering the app for push notification in APNS,

```
let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
UIApplication.sharedApplication().registerUserNotificationSettings(settings)
UIApplication.sharedApplication().registerForRemoteNotifications()
```    
After the token is received from APNS, pass the token to Push Notifications as part of the
 ***didRegisterForRemoteNotificationsWithDeviceToken*** method.

```
 func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){

    let push =  BMSPushClient.sharedInstance
   push.registerDeviceToken(deviceToken) { (response, statusCode, error) -> Void in
            
        if error.isEmpty {

            print( "Response during device registration : \(response)")
                
            print( "status code during device registration : \(statusCode)")
        }
        else{
            print( "Error during device registration \(error) ")
                
            Print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
        }
    }

}
```
#### Retrieve Available Tags and register for Tags

##### Retrieve Available tags

The ***retrieveAvailableTagsWithCompletionHandler*** API returns the list of available tags to which the device
can subscribe. After the device is subscribed to a particular tag, the device can receive any push notifications
that are sent for that tag.

Call the push service to get subscriptions for a tag.

Copy the following code snippets into your Swift mobile application to get a list of available tags to which the
device can subscribe.

```
push.retrieveAvailableTagsWithCompletionHandler({ (response, statusCode, error) -> Void in
                    
    if error.isEmpty {
        
        print( "Response during retrieve tags : \(response)")
        
        print( "status code during retrieve tags : \(statusCode)")
    }
    else{
        print( "Error during retrieve tags \(error) ")
        
        Print( "Error during retrieve tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
##### Subscribe to Available tags

```
push.subscribeToTags(response, completionHandler: { (response, statusCode, error) -> Void in
                            
    if error.isEmpty {
        
        print( "Response during Subscribing to tags : \(response.description)")
        
        print( "status code during Subscribing tags : \(statusCode)")
    }
    else {
                                
        print( "Error during subscribing tags \(error) ")
        
        Print( "Error during subscribing tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```

##### Retrieve Subscribed tags

```
push.retrieveSubscriptionsWithCompletionHandler { (response, statusCode, error) -> Void in
            
    if error.isEmpty {
        
        print( "Response during retrieving subscribed tags : \(response.description)")
        
        print( "status code during retrieving subscribed tags : \(statusCode)")
    }
    else {
        
        print( "Error during retrieving subscribed tags \(error) ")
        
        Print( "Error during retrieving subscribed tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
#### unsubscribing tags

Use the following code snippets to allow your devices to get unsubscribe
from a tag.

```
push.unsubscribeFromTags(response, completionHandler: { (response, statusCode, error) -> Void in
                    
    if error.isEmpty {
        
        print( "Response during unsubscribed tags : \(response.description)")
        
        print( "status code during unsubscribed tags : \(statusCode)")
    }
    else {
        print( "Error during  unsubscribed tags \(error) ")
        
        print( "Error during unsubscribed tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
#### Unregistering the Device from Bluemix Push Notification

Use the following code snippets to Unregister the device from Bluemix Push Notification

```
push.unregisterDevice({ (response, statusCode, error) -> Void in
                            
    if error.isEmpty {
        
        print( "Response during unregistering device : \(response)")
        
        print( "status code during unregistering device : \(statusCode)")
    }
    else{
        print( "Error during unregistering device \(error) ")
        
        print( "Error during unregistering device \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```

###Learning More
* Visit the **[Bluemix Developers Community](https://developer.ibm.com/bluemix/)**.

* [Getting started with IBM MobileFirst Platfrom for iOS](https://www.ng.bluemix.net/docs/mobile/index.html)

###Connect with Bluemix

[Twitter](https://twitter.com/ibmbluemix) |
[YouTube](https://www.youtube.com/playlist?list=PLzpeuWUENMK2d3L5qCITo2GQEt-7r0oqm) |
[Blog](https://developer.ibm.com/bluemix/blog/) |
[Facebook](https://www.facebook.com/ibmbluemix) |
[Meetup](http://www.meetup.com/bluemix/)


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
