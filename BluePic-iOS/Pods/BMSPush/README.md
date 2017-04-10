IBM Bluemix Mobile Services - Client SDK Swift Push
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-push.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-push)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/08bd0c46c0ae4485a3abc0fd8dffa4cf)](https://www.codacy.com/app/ibm-bluemix-mobile-services/bms-clientsdk-swift-push?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ibm-bluemix-mobile-services/bms-clientsdk-swift-push&amp;utm_campaign=Badge_Grade)
[![Coverage Status](https://coveralls.io/repos/github/ibm-bluemix-mobile-services/bms-clientsdk-swift-push/badge.svg?branch=development)](https://coveralls.io/github/ibm-bluemix-mobile-services/bms-clientsdk-swift-push?branch=development)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BMSPush.svg)](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-push.git)
[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)
[![CocoaPods](https://img.shields.io/cocoapods/dt/BMSPush.svg)](https://cocoapods.org/pods/BMSPush)


This is the Push component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/index.html).


## Contents

This package contains the Push components of the Swift SDK.
* Push Registration and Unregister
* Subscribing and Unsubscribing for Tags

## Requirements

* iOS 8.0+
* Xcode 7.3, 8.0
* Swift 2.3 - 3.0
* Cocoapods or Carthage

## Installation

The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).

### Cocoapods
To install BMSPush using Cocoapods, add it to your Podfile:

```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSCore', '~> 2.0'
    pod 'BMSPush', '~> 3.0'
end
```
From the Terminal, go to your project folder and install the dependencies with the following command:

```
pod install
```

#### Swift 2.3

Before running the `pod install` command, make sure to use Cocoapods version [1.1.0.beta.1](https://github.com/CocoaPods/CocoaPods/releases/tag/1.1.0.beta.1).

#### Swift 3.0

Before running the `pod install` command, make sure to use Cocoapods version [1.1.0.beta.1](https://github.com/CocoaPods/CocoaPods/releases/tag/1.1.0.beta.1).

For apps built with Swift 3.0, you may receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSCore) do not convert BMSPush, BMSCore or BMSAnalyticsAPI

This will installs your dependencies and creates a new Xcode workspace.
***Note:*** Ensure that you always open the new Xcode workspace, instead of the original Xcode project file:

```
MyApp.xcworkspace
```

### Carthage
To install BMSPush using Carthage, add it to your Cartfile:

```
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-push"
```

Then run the `carthage update` command. Once the build is finished, drag `BMSPush.framework`,`BMSCore.framework` and `BMSAnalyticsAPI.framework` into your Xcode project.

To complete the integration, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3.` Otherwise, use `carthage update`

## Enabling iOS applications to receive push notifications

### Reference the SDK in your code.

```
import BMSPush
import BMSCore
```
### Initializing the Core SDK

```
let myBMSClient = BMSClient.sharedInstance

//Swift3

myBMSClient.initialize(bluemixRegion: "Location where your app Hosted")

//Swift 2.3 or Older

myBMSClient.initialize(bluemixRegion: "Location where your app Hosted")

```

##### bluemixRegion

- Specifies the location where the app hosted. You can use one of three values - `BMSClient.Region.usSouth`, `BMSClient.Region.unitedKingdom` and `BMSClient.Region.sydney`.

### Initializing the Push SDK

 initialize the `BMSPushClient`  using the following code.
```
let push =  BMSPushClient.sharedInstance

//Swift 3

push.initializeWithAppGUID(appGUID: "your push appGUID", clientSecret:"your push client secret")

//Swift Older

push.initializeWithAppGUID(appGUID:"your push appGUID", clientSecret:"your push client secret")

```

##### appGUID

- The Push app GUID value.

##### clientSecret

- The Push client secret value.

>**Note**: If you are using Xcode8 beta, add `yourApp.entitlements`. To do this, go to Targets -> Capabilities and enable Push Notifications capability.

After the token is received from APNS, pass the token to Push Notifications as part of the `didRegisterForRemoteNotificationsWithDeviceToken` method.

```

//Swift3

 func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){

   let push =  BMSPushClient.sharedInstance
   push.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
    if error.isEmpty {
      print( "Response during device registration : \(response)")
      print( "status code during device registration : \(statusCode)")
    } else{
      print( "Error during device registration \(error) ")
      Print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
    }  
 }


 //Swift2.3 and Older

 func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){

   let push =  BMSPushClient.sharedInstance
   push.registerWithDeviceToken(deviceToken) { (response, statusCode, error) -> Void in
        if error.isEmpty {
            print( "Response during device registration : \(response)")
            print( "status code during device registration : \(statusCode)")
        }else{
            print( "Error during device registration \(error) ")
            Print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
        }
    }
}
```

### Registering iOS applications and devices with userId

For `userId` based notification, the register method will accept one more parameter - `userId`


```
//Swift3

func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){

   let push =  BMSPushClient.sharedInstance
   push.registerWithDeviceToken(deviceToken: deviceToken, WithUserId: "your userId") { (response, statusCode, error) -> Void in
    if error.isEmpty {
      print( "Response during device registration : \(response)")
      print( "status code during device registration : \(statusCode)")
    } else{
      print( "Error during device registration \(error) ")
      Print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
    }  
}

//Swift2.3 and Older

func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){

    let push =  BMSPushClient.sharedInstance
    push.registerWithDeviceToken(deviceToken, WithUserId: "your userId") { (response, statusCode, error) -> Void in
        if error.isEmpty {
            print( "Response during device registration : \(response)")
            print( "status code during device registration : \(statusCode)")
        }else{
            print( "Error during device registration \(error) ")
            Print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
        }
    }
}
```

##### WithUserId

- The User Id value you want to register in the push service

>**Note**: If userId is provided the client secret value must be provided.


### Retrieve Available Tags and subscribe for Tags based Notifications

##### Retrieve Available tags

The `retrieveAvailableTagsWithCompletionHandler` API returns the list of available tags to which the device
can subscribe. After the device is subscribed to a particular tag, the device can receive any push notifications
that are sent for that tag.Call the push service to get subscriptions for a tag.

Copy the following code snippets into your Swift mobile application to get a list of available tags to which the
device can subscribe.

```

//Swift3

push.retrieveAvailableTagsWithCompletionHandler(completionHandler: { (response, statusCode, error) -> Void in

  if error.isEmpty {
    print( "Response during retrieve tags : \(response)")
    print( "status code during retrieve tags : \(statusCode)")
  }else{
    print( "Error during retrieve tags \(error) ")
    Print( "Error during retrieve tags \n  - status code: \(statusCode) \n Error :\(error) \n")
  }
}

//Swift2.3 and Older

push.retrieveAvailableTagsWithCompletionHandler({ (response, statusCode, error) -> Void in

    if error.isEmpty {
        print( "Response during retrieve tags : \(response)")
        print( "status code during retrieve tags : \(statusCode)")
    }else{
        print( "Error during retrieve tags \(error) ")
        Print( "Error during retrieve tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
##### Subscribe to Available tags

```

//Swift3

 push.subscribeToTags(tagsArray: response!, completionHandler: { (response, statusCode, error) -> Void in

   if error.isEmpty {
       print( "Response during Subscribing to tags : \(response?.description)")     
       print( "status code during Subscribing tags : \(statusCode)")
     }else{
       print( "Error during subscribing tags \(error) ")
       Print( "Error during subscribing tags \n  - status code: \(statusCode) \n Error :\(error) \n")
     }
 }

//Swift2.3 and Older

push.subscribeToTags(response, completionHandler: { (response, statusCode, error) -> Void in

    if error.isEmpty {
        print( "Response during Subscribing to tags : \(response?.description)")
        print( "status code during Subscribing tags : \(statusCode)")
    }else {
        print( "Error during subscribing tags \(error) ")
        Print( "Error during subscribing tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```

##### Retrieve Subscribed tags

```

//Swift3
 push.retrieveSubscriptionsWithCompletionHandler(completionHandler: { (response, statusCode, error) -> Void in

   if error.isEmpty {                                     
     print( "Response during retrieving subscribed tags : \(response?.description)")
     print( "status code during retrieving subscribed tags : \(statusCode)")
   }else{
     print( "Error during retrieving subscribed tags \(error) ")
     Print( "Error during retrieving subscribed tags \n  - status code: \(statusCode) \n Error :\(error) \n")
   }
 }

//Swift2.3 and Older
push.retrieveSubscriptionsWithCompletionHandler { (response, statusCode, error) -> Void in

    if error.isEmpty {
        print( "Response during retrieving subscribed tags : \(response?.description)")
        print( "status code during retrieving subscribed tags : \(statusCode)")
    }else {
        print( "Error during retrieving subscribed tags \(error) ")
        Print( "Error during retrieving subscribed tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
### Unsubscribing from tags based notifications

Use the following code snippets to allow your devices to get unsubscribe
from a tag.

```

//Swift3
push.unsubscribeFromTags(tagsArray: response!, completionHandler: { (response, statusCode, error) -> Void in

  if error.isEmpty {
    print( "Response during unsubscribed tags : \(response?.description)")
    print( "status code during unsubscribed tags : \(statusCode)")
  }else{
    print( "Error during  unsubscribed tags \(error) ")
  }
}

//Swift2.3 and Older

push.unsubscribeFromTags(response, completionHandler: { (response, statusCode, error) -> Void in

    if error.isEmpty {

        print( "Response during unsubscribed tags : \(response?.description)")

        print( "status code during unsubscribed tags : \(statusCode)")
    }
    else {
        print( "Error during  unsubscribed tags \(error) ")

        print( "Error during unsubscribed tags \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```
### Unregistering the Device from Bluemix Push Notification

Use the following code snippets to Unregister the device from Bluemix Push Notification

```

//Swift3

push.unregisterDevice(completionHandler: { (response, statusCode, error) -> Void in

  if error.isEmpty {                 
     print( "Response during unregistering device : \(response)")
     print( "status code during unregistering device : \(statusCode)")
   }else{
     print( "Error during unregistering device \(error) ")
   }
}

//Swift2.3 and Older

push.unregisterDevice({ (response, statusCode, error) -> Void in

    if error.isEmpty {
        print( "Response during unregistering device : \(response)")
        print( "status code during unregistering device : \(statusCode)")
    }else{
        print( "Error during unregistering device \(error) ")
        print( "Error during unregistering device \n  - status code: \(statusCode) \n Error :\(error) \n")
    }
}
```

### Enabling interactive push notifications

To enable interactive push notifications, the notification action parameters must be passed in as part of the notification object.  The following is a sample code to enable interactive notifications.

```
let actionOne = BMSPushNotificationAction(identifierName: "FIRST", buttonTitle: "Accept", isAuthenticationRequired: false, defineActivationMode: UIUserNotificationActivationMode.background)

let actionTwo = BMSPushNotificationAction(identifierName: "SECOND", buttonTitle: "Reject", isAuthenticationRequired: false, defineActivationMode: UIUserNotificationActivationMode.background)

let category = BMSPushNotificationActionCategory(identifierName: "category", buttonActions: [actionOne, actionTwo])

let notificationOptions = BMSPushClientOptions()
notifOptions.setInteractiveNotificationCategories(categoryName: [category])

let push = BMSPushClient.sharedInstance.initializeWithAppGUID(appGUID: "APP-GUID-HERE", clientSecret:"CLIENT-SECRET-HERE", options: notificationOptions)

```

### Enabling Rich Push notification support in iOS 10 (Audio, Video, GIF and Images)

To receive rich push notifications with iOS10, implement ```UNNotificationServiceExtension```.  The extension will intercept the rich push notification and it needs to be handled here.  While sending the notification from the server, all the four fields, alert, title, subtitle, attachmentURL must be specified.

In the didReceive() method of your service extension, add the following code to retrieve the rich notification content.

```
override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
       self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        BMSPushRichPushNotificationOptions.didReceive(request, withContentHandler: contentHandler)
        }
```

## Enable Monitoring.
<p>To see the push notification monitoring status for iOS you have add the following code snippets. </p>

<strong>Swift 3</strong>
```
// Send notification status when app is opened by clicking the notifications
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {

     let push =  BMSPushClient.sharedInstance
     let respJson = (userInfo as NSDictionary).value(forKey: "payload") as! String
     let data = respJson.data(using: String.Encoding.utf8)

     let jsonResponse:NSDictionary = try! JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary

     let messageId:String = jsonResponse.value(forKey: "nid") as! String
     push.sendMessageDeliveryStatus(messageId: messageId) { (res, ss, ee) in
         print("Send message status to the Push server")
     }
}


// Send notification status when the app is in background mode.
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

   let payLoad = ((((userInfo as NSDictionary).value(forKey: "aps") as! NSDictionary).value(forKey: "alert") as! NSDictionary).value(forKey: "body") as! NSString)

   self.showAlert(title: "Recieved Push notifications", message: payLoad)

   let push =  BMSPushClient.sharedInstance

   let respJson = (userInfo as NSDictionary).value(forKey: "payload") as! String
   let data = respJson.data(using: String.Encoding.utf8)

   let jsonResponse:NSDictionary = try! JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary

   let messageId:String = jsonResponse.value(forKey: "nid") as! String
   push.sendMessageDeliveryStatus(messageId: messageId) { (res, ss, ee) in
       completionHandler(UIBackgroundFetchResult.newData)
   }
}
```
<strong>Swift 2.3</strong>

```
func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

  let respJson = (userInfo as NSDictionary).valueForKey("payload") as! String
  let data = respJson.dataUsingEncoding(NSUTF8StringEncoding)

  do {
      let responseObject:NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
      let nid = responseObject.valueForKey("nid") as! String
      print(nid)

      let push =  BMSPushClient.sharedInstance

      push.sendMessageDeliveryStatus(nid, completionHandler: { (response, statusCode, error) in

          print("Send message status to the Push server")
      })

  } catch let error as NSError {
      print("error: \(error.localizedDescription)")
  }
}

func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

  let payLoad = ((((userInfo as NSDictionary).valueForKey("aps") as! NSDictionary).valueForKey("alert") as! NSDictionary).valueForKey("body") as! NSString)

  self.showAlert("Recieved Push notifications", message: payLoad)


  let respJson = (userInfo as NSDictionary).valueForKey("payload") as! String
  let data = respJson.dataUsingEncoding(NSUTF8StringEncoding)

  do {
      let responseObject:NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
      let nid = responseObject.valueForKey("nid") as! String
      print(nid)

      let push =  BMSPushClient.sharedInstance

      push.sendMessageDeliveryStatus(nid, completionHandler: { (response, statusCode, error) in
          completionHandler(UIBackgroundFetchResult.NewData)
      })

  } catch let error as NSError {
      print("error: \(error.localizedDescription)")
  }
}
```
>**Note**: To get the message status when the app is in background you have to send either <strong>MIXED</strong> or <strong>SILENT</strong> push notifications. If the app is force quite you will not get any message delivery status.

### Open Url by clicking push notifications.

To open a url by clicking the push notification you can send a `url` firld inside the payload.
```
{
  "message": {
    "alert": "Notification alert message",
    "url":"https://console.ng.bliuemix.net"
  }
}
```

In your applications, go to `AppDelegate` file and inside `didFinishLaunchingWithOptions` check the value for `url`

```
let remoteNotif = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary

if remoteNotif != nil {
    let urlField = (remoteNotif?.value(forKey: "url") as! String)
    application.open(URL(string: urlField)!, options: [:], completionHandler: nil)
}
```

### Adding custom DeviceId for registration

To send `DeviceId` please use `BMSPushClientOptions` class method,

```
let notifOptions = BMSPushClientOptions()
notifOptions.setDeviceId(deviceId: "YOUR_DEVICE_ID")
```
>**Note**: Remember to keep custom DeviceId <strong>unique</strong> for each device.

### Samples & videos

* Please visit for samples - [Github Sample](https://github.com/ibm-bluemix-mobile-services/bms-samples-swift-hellopush)

* Video Tutorials Available here - [Bluemix Push Notifications](https://www.youtube.com/channel/UCRr2Wou-z91fD6QOYtZiHGA)

### Learning More

* Visit the **[Bluemix Developers Community](https://developer.ibm.com/bluemix/)**.

* [Getting started with IBM MobileFirst Platform for iOS](https://www.ng.bluemix.net/docs/mobile/index.html)

### Connect with Bluemix

[Twitter](https://twitter.com/ibmbluemix) |
[YouTube](https://www.youtube.com/playlist?list=PLzpeuWUENMK2d3L5qCITo2GQEt-7r0oqm) |
[Blog](https://developer.ibm.com/bluemix/blog/) |
[Facebook](https://www.facebook.com/ibmbluemix) |
[Meetup](http://www.meetup.com/bluemix/)


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
