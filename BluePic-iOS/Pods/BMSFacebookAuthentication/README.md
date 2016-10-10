IBM Bluemix Mobile Services - Client SDK Swift Security -Facebook
===================================================

This is the Facebook security component of the Swift SDK for [IBM Bluemix Mobile Services] (https://console.ng.bluemix.net/docs/mobile/index.html).

## Requirements
* iOS 8.0 or later
* Xcode 7


## Installation
The Bluemix Mobile Services Facebook authentication Swift SDK is available via [Cocoapods](http://cocoapods.org/).
To install, add the `BMSFacebookAuthentication` pod to your Podfile.

##### iOS
```ruby
use_frameworks!

target 'MyApp' do
    platform :ios, '8.0'
    pod 'BMSFacebookAuthentication'
end
```

After you update your Podfile, the pod's sources are added to your workspace. Copy the `FacebookAuthenticationManager.swift` file from the `BMSFacebookAuthentication` pod's source folder to your app folder. Then find the `info.plist` file (typically located under `Supporting files` folder of your project) and add the following data to the source code of `info.plist`. Replace `<YOUR_FACEBOOK_APP_ID>` and `<YOUR_FACEBOOK_APP_NAME>` with the values for your app's Facebook data:

```XML
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb<YOUR_FACEBOOK_APP_ID></string>
        </array>
    </dict>
</array>
<key>FacebookAppID</key>
<string><YOUR_FACEBOOK_APP_ID></string>
<key>FacebookDisplayName</key>
<string><YOUR_FACEBOOK_APP_NAME> </string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbauth</string>
    <string>fbauth2</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>facebook.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>                
            <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
        <key>fbcdn.net</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
        <key>akamaihd.net</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```
**Important:** Do not to override any existing properties in the `info.plist` file. If you have overlapping properties, merge your file manually with this segment.

## Getting started

To use the Bluemix Mobile Services Facebook authentication Swift SDK, add the following imports to the class which you want to use Facebook authentication it in:

```Swift
import BMSCore
import BMSSecurity
```
Connectivity and interaction between your mobile app and the Bluemix services depends on the application ID and application route that are associated with Bluemix application.

The BMSClient API is the entry point for interacting with the SDK. You must invoke the following method before any other API calls:

```
initializeWithBluemixAppRoute(bluemixAppRoute: String?, bluemixAppGUID: String?, bluemixRegion: String)
```

The BMSClient API provides information about the current SDK level and access to service SDKs. This method is usually in the application delegate of your mobile app.

An example of initializing the Bluemix Mobile Services Swift SDK follows:

Initialize SDK with IBM Bluemix application route, ID and the region where your Bluemix application is hosted.
```
BMSClient.sharedInstance.initializeWithBluemixAppRoute(<app route>, bluemixAppGUID: <app GUID>, bluemixRegion: BMSClient.<region>)
```

You also need to define MCAAuthorizationManager as your authorization manager:
```Swift
BMSClient.sharedInstance.authorizationManager = MCAAuthorizationManager.sharedInstance
```

Then register the delegate for Facebook's realm:

```Swift
FacebookAuthenticationManager.sharedInstance.register()
```

Then add the following code to your app delegate:

```Swift
  func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject) -> Bool {
        return FacebookAuthenticationManager.sharedInstance.onOpenURL(application, url: url, sourceApplication: sourceApplication, annotation: annotation)
    }

 ```

In order to logout the current logged in user, you can use the following code:
```Swift
FacebookAuthenticationManager.logout(<callBack>)

```
To switch users, you must call this code and the user must logout from Facebook in their browser.

## Sample app
You can use 'pod try BMSFacebookAuthentication' to get a sample application. A readme file with details on how to run the sample application is available in the app's folder.

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
