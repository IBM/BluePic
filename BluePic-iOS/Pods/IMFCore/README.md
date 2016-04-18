MobileFirst Platform for iOS SDK for IBM Bluemix
===

This package contains the required native components to interact with the IBM
MobileFirst Platform for iOS.  The SDK manages all the communication and security integration between
the iOS mobile app and with the MobileFirst Platform for iOS in Bluemix.

When you use Bluemix to create an application,
multiple services are provisioned under a single application context. Your mobile application is given
access to the following mobile services: Mobile Client Access (which includes security, analytics, and logging), Push for iOS8, and Cloudant NoSQL DB.

Version: 1.0.0

###Installing the SDK
Install the SDK with [CocoaPods](http://cocoapods.org/). Using CocoaPods
can significantly shorten the startup time for new projects and lessen the burden of managing
library version requirements and dependencies.

To install CocoaPods, see [CocoaPods Getting Started](http://guides.cocoapods.org/using/getting-started.html#getting-started).  If you
are using a [sample](https://hub.jazz.net/user/mobilecloud),
a [pod](http://guides.cocoapods.org/using/the-podfile.html)
file is included for you.

###SDK contents
The complete SDK consists of a core, plus a collection of pods that correspond to functions that are exposed
by the MobileFirst Platform for iOS.  Each piece of the iOS SDK is available as a separate pod
through CocoaPods,
that you can add to your project individually. The MobileFirst Platform for iOS SDK contains the following
pods, any of which you can add to your project:

- IMFCore: Implements core services such as networking, logging and analytics and security and authorization.
- IMFData: Implements security integration between IMFCore and CloudantToolkit.
- CloudantToolkit: Enables interaction with both local and remote Cloudant datastores.
- IMFPush: Enables push notification support.
- IMFFacebookAuthentication: Enables Facebook as an identity provider with the Mobile Client Access service.
- IMFGoogleAuthentication: Enables Google as an identity provider with the Mobile Client Access service.
- IMFURLProtocol: Enables use of IMFURLProtocol (NSURLRequest).

###Supported iOS levels
- iOS 7
- iOS 8

###Getting started
Connectivity and interaction between your mobile app and
the Bluemix services depends on the application ID and application route that are associated
with Bluemix application.

The IMFClient API is the entry point for interacting with the SDK.  You must invoke the `initializeWithBackendRoute: backendGUID:` method  before any other API calls.  IMFClient provides information about the current SDK level and access to service SDKs.  This method is usually in the application delegate of your mobile app.

An example of initializing the MobileFirst Platform for iOS SDK follows:
```Objective-c
// Initialize SDK with IBM Bluemix application ID and route
IMFClient *imfClient = [IMFClient sharedInstance];
[imfClient initializeWithBackendRoute:<app route> backendGUID:appId];
```

```Swift
// Initialize SDK with IBM Bluemix application ID and route
IMFClient.sharedInstance().initializeWithBackendRoute(applicationRoute, backendGUID: applicationId);
```

###Learning More
   * Visit the **[Bluemix Developers Community](https://developer.ibm.com/bluemix/)**.

   * [Getting started with IBM MobileFirst Platfrom for iOS](https://www.ng.bluemix.net/docs/#starters/mobilefirst/gettingstarted/index.html#gettingstarted)

###Connect with Bluemix

[Twitter](https://twitter.com/ibmbluemix) |
[YouTube](https://www.youtube.com/playlist?list=PLzpeuWUENMK2d3L5qCITo2GQEt-7r0oqm) |
[Blog](https://developer.ibm.com/bluemix/blog/) |
[Facebook](https://www.facebook.com/ibmbluemix) |
[Meetup](http://www.meetup.com/bluemix/)

*Licensed Materials - Property of IBM
(C) Copyright IBM Corp. 2013, 2014. All Rights Reserved.
US Government Users Restricted Rights - Use, duplication or
disclosure restricted by GSA ADP Schedule Contract with IBM Corp.*

[Terms of Use](https://hub.jazz.net/gerrit/plugins/gerritfs/contents/bluemixmobilesdk%2Fimf-ios-sdk/refs%2Fheads%2Fmaster/License.txt)
