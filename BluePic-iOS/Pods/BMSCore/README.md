BMSCore
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-core)
[![Platform](https://img.shields.io/cocoapods/p/BMSCore.svg?style=flat)](http://cocoadocs.org/docsets/BMSCore)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BMSCore.svg)](https://img.shields.io/cocoapods/v/BMSCore.svg)
[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)

BMSCore is the core component of the Swift SDKs for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/services.html).



## Table of Contents
* [Summary](#summary)
* [Requirements](#requirements)
* [Installation](#installation)
* [Example Usage](#example-usage)
* [Release Notes](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core/releases)
* [License](#license)



## Summary

BMSCore provides the HTTP infrastructure that the other Bluemix Mobile Services (BMS) client SDKs use to communicate with their corresponding Bluemix services. These other SDKs include [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics), [BMSPush](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-push), [BMSSecurity](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-security), and [BluemixObjectStorage](https://github.com/ibm-bluemix-mobile-services/bluemix-objectstorage-clientsdk-swift). 

You can also use this SDK to make network requests to any resource using `BMSURLSession`. This API is a wrapper around the native Swift [URLSession](https://developer.apple.com/reference/foundation/urlsession) that currently supports data tasks and upload tasks. `BMSURLSession` becomes more powerful if you have other BMS SDKs installed in your app. With [BMSSecurity](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-security), you can make network requests to backends protected by [Mobile Client Access](https://console.ng.bluemix.net/docs/services/mobileaccess/index.html). With [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics), analytics data will automatically be gathered (if you opt in) for all requests made with `BMSURLSession`, which can then be sent to a [Mobile Analytics](https://console.ng.bluemix.net/docs/services/mobileanalytics/index.html) service.

BMSCore is also available for [Android](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-android-core) and [Cordova](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-cordova-plugin-core). 



## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7.3, 8.0
* Swift 2.2 - 3.0
* Cocoapods or Carthage



## Installation
The Bluemix Mobile Services Swift SDKs can be installed with either [Cocoapods](http://cocoapods.org/) or [Carthage](https://github.com/Carthage/Carthage).


### Cocoapods

To install BMSCore using Cocoapods, add it to your Podfile. If your project does not have a Podfile yet, use the `pod init` command.

```ruby
use_frameworks!

target 'MyApp' do
    pod 'BMSCore'
end
```

Then run the `pod install` command, and open the generated `.xcworkspace` file. To update to a newer release of BMSCore, use `pod update BMSCore`.

For more information on using Cocoapods, refer to the [Cocoapods Guides](https://guides.cocoapods.org/using/index.html).

#### Xcode 8

When installing with Cocoapods in Xcode 8, make sure you have installed Cocoapods [1.1.0](https://github.com/CocoaPods/CocoaPods/releases) or later. You can get the latest version of Cocoapods using the command `sudo gem install cocoapods`.

If you receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSCore), **do not** convert BMSCore or BMSAnalyticsAPI.


### Carthage

To install BMSCore with Carthage, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

Add this line to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-core"
```

Then run the `carthage update` command. Once the build is finished, add `BMSCore.framework` and `BMSAnalyticsAPI.framework` to your project (step 3 in the link above). 

#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3`. Otherwise, use `carthage update`.



## Example Usage

* [Import the module](#import-the-module)
* [Initialize the client](#initialize-the-client)
* [Monitor the network connection](#monitor-the-network-connection)
* [Make a network request](#make-a-network-request)
	* [Data task](#data-task)
	* [Upload task](#upload-task)
	* [Automatically resend requests](#automatically-resend-requests)

> View the complete API reference [here](https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSCore/Swift/index.html).

--


### Import the module

```Swift
import BMSCore
```

--

### Initialize the client

Initializing `BMSClient` is only required when using `BMSCore` with other BMS SDKs.

```Swift
BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)
```

--

### Monitor the network connection

With the `NetworkMonitor` API, you can monitor the status of the iOS device's connection to the internet. You can use this information to decide when to send network requests and to handle offline or slow network conditions.

First, create a new instance of the `NetworkMonitor`. Only one instance is needed per app. **Note**: The initializer is failable, so you will need to unwrap the result later.

```Swift
let networkMonitor = NetworkMonitor()
```

To get the current type of network connection (WiFi, WWAN, or no connection), use `networkMonitor.currentNetworkConnection`. If the device has a data plan enabled, you can see whether they have access to 4G, 3G, or 2G with `networkMonitor.cellularNetworkType`.

You can also create an observer to detect changes in the network connection.

##### Swift 3

```Swift
networkMonitor.startMonitoringNetworkChanges()
NotificationCenter.default.addObserver(self, selector: #selector(networkConnectionChanged), name: NetworkMonitor.networkChangedNotificationName, object: nil)

func networkConnectionChanged() {    
    print("Changed network connection to: \(networkMonitor.currentNetworkConnection)")
}
```

##### Swift 2

```Swift
networkMonitor.startMonitoringNetworkChanges()
NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(networkConnectionChanged), name: NetworkMonitor.networkChangedNotificationName, object: nil)

func networkConnectionChanged() {    
    print("Changed network connection to: \(networkMonitor.currentNetworkConnection)")
}
```

--

### Make a network request

#### Data task

With `BMSURLSession`, you can create data tasks to send and receive data.

The example belows show how to create and send a data task, using a completion handler to parse the response. 

**Note**: If you are also using the [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics) framework to gather data on these network requests, be sure to call `.resume()` immediately after creating the data task as shown in the examples below.

##### Swift 3

```Swift
var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
request.httpMethod = "GET"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .default, delegate: nil, delegateQueue: nil, autoRetries: 2)
urlSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in

    if let httpResponse = response as? HTTPURLResponse {
        print("Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = String(data: data!, encoding: .utf8) {
        print("Response data: \(responseString)")
    }
    if let error = error {
        print("Error: \(error)")
    }
}.resume()
```


##### Swift 2

```Swift
let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
request.HTTPMethod = "GET"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: nil, delegateQueue: nil, autoRetries: 2)
urlSession.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in

    if let httpResponse = response as? NSHTTPURLResponse {
        print("Status code: \(httpResponse.statusCode)")
    }
    if data != nil, let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
        print("Response data: \(responseString)")
    }
    if let error = error {
        print("Error: \(error)")
    }
}.resume()
```

--

As an alternative to using completion handlers, you can create your own [URLSessionDelegate](https://developer.apple.com/reference/foundation/urlsessiondelegate) for more control over handling the response. 

##### Swift 3

```Swift
var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
request.httpMethod = "GET"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .default, delegate: URLSessionDelegateExample(), delegateQueue: nil, autoRetries: 2)
urlSession.dataTask(with: request).resume()
```

```Swift
class URLSessionDelegateExample: NSObject, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    
        if let error = error {
            print("Error: \(error)\n")
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        // Required when connecting with an MCA-protected backend
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
    }
}
```


##### Swift 2

```Swift
let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
request.HTTPMethod = "GET"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: NSURLSessionDelegateExample(), delegateQueue: nil, autoRetries: 2)
urlSession.dataTaskWithRequest(request).resume()
```

```Swift
class NSURLSessionDelegateExample: NSObject, NSURLSessionDataDelegate {
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    
        if let error = error {
            print("Error: \(error)\n")
        }
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
    
        if let httpResponse = response as? NSHTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        // Required when connecting with an MCA-protected backend
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
    
        if let responseString = String(data: data, encoding: NSUTF8StringEncoding) {
            print("Response data: \(responseString)")
        }
    }
}
```

--

#### Upload task

Upload tasks are data tasks that make it easier to upload data or files. With upload tasks, you can monitor the progress of each upload, and continue the upload in the background when the app is not running.

The examples below show how to upload a file, using a completion handler to parse the response.

**Note**: If you are also using the [BMSAnalytics](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics) framework to gather data on these network requests, be sure to call `.resume()` immediately after creating the data task as shown in the examples below.

##### Swift 3

```Swift
let file = Bundle.main.url(forResource: "MyPicture", withExtension: "jpg")!

var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
request.httpMethod = "POST"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .default, delegate: nil, delegateQueue: nil, autoRetries: 2)
urlSession.uploadTask(with: request, fromFile: file, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in

    if let httpResponse = response as? HTTPURLResponse {
        print("Status code: \(httpResponse.statusCode)")
    }
    if let error = error {
        print("Error: \(error)")
    }
}).resume()
```

##### Swift 2

```Swift
let file = NSBundle.mainBundle().URLForResource("MyPicture", withExtension: "jpg")!

let request = NSMutableURLRequest(URL: NSURL(string: "https://httpbin.org/post")!)
request.HTTPMethod = "POST"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: nil, delegateQueue: nil, autoRetries: 2)
urlSession.uploadTaskWithRequest(request, fromFile: file, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in

    if let httpResponse = response as? NSHTTPURLResponse {
        print("Status code: \(httpResponse.statusCode)")
    }
    if let error = error {
        print("Error: \(error)")
    }
}).resume()
```

--

As an alternative to using completion handlers, you can create your own [URLSessionDelegate](https://developer.apple.com/reference/foundation/urlsessiondelegate) for more control over handling the response. 

##### Swift 3

```Swift
let file = Bundle.main.url(forResource: "MyPicture", withExtension: "jpg")!

var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
request.httpMethod = "POST"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .default, delegate: URLSessionDelegateExample(), delegateQueue: nil, autoRetries: 2)
urlSession.uploadTask(with: request, fromFile: file).resume()
```

```Swift
class URLSessionDelegateExample: NSObject, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let error = error {
            print("Error: \(error)\n")
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        // Required when connecting with an MCA-protected backend
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    
        DispatchQueue.main.async {
            let currentProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend) * 100
            print("Upload progress = \(currentProgress)%")
        }
    }
}
```


##### Swift 2

```Swift
let file = NSBundle.mainBundle().URLForResource("MyPicture", withExtension: "jpg")!

let request = NSMutableURLRequest(URL: NSURL(string: "https://httpbin.org/post")!)
request.HTTPMethod = "POST"
request.setValue("value", forHTTPHeaderField: "key")

let urlSession = BMSURLSession(configuration: .defaultSessionConfiguration(), delegate: NSURLSessionDelegateExample(), delegateQueue: nil, autoRetries: 2)
urlSession.uploadTaskWithRequest(request, fromFile: file).resume()
```

```Swift
class NSURLSessionDelegateExample: NSObject, NSURLSessionDataDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let error = error {
            print("Error: \(error)\n")
        }
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if let httpResponse = response as? NSHTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        
        // Required when connecting with an MCA-protected backend
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    internal func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        if let responseString = String(data: data, encoding: NSUTF8StringEncoding) {
            print("Response data: \(responseString)")
        }
    }
    
    internal func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        dispatch_async(dispatch_get_main_queue()) {
            let currentProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend) * 100
            print("Upload progress = \(currentProgress)%")
        }
    }
}
```

--

#### Automatically resend requests

In the data task and upload task examples above, there is an optional parameter `autoRetries` in the `BMSURLSession` initializers. This is the number of times that `BMSURLSession` will automatically resend the task if it fails due to network issues. These automatic retries occur under the following conditions:

1. Request timeout
2. Loss of network connection (such as WiFi disconnect or lost cellular service)
3. Failure to connect to the host
4. 504 response

If this parameter is excluded from the initializer, no automatic retries will occur.

--------



## License
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
