# Bluemix AppID
Swift SDK for the Bluemix AppID service

[![Bluemix powered][img-bluemix-powered]][url-bluemix]
[![Travis][img-travis-master]][url-travis-master]
[![Coveralls][img-coveralls-master]][url-coveralls-master]
[![Codacy][img-codacy]][url-codacy]
[![License][img-license]][url-bintray]

[![GithubWatch][img-github-watchers]][url-github-watchers]
[![GithubStars][img-github-stars]][url-github-stars]
[![GithubForks][img-github-forks]][url-github-forks]

## Requirements
Xcode 8.1 or above, CocoaPods 1.1.0 or higher, MacOS 10.11.5 or higher, iOS 9 or higher.

## Installing the SDK:

1. Add the 'BluemixAppID' dependency to your Podfile, for example:

    ```swift
    target <yourTarget> do
       use_frameworks!
	     pod 'BluemixAppID'
    end
    ```  
2. From the terminal, run:  
    ```swift
    pod install --repo-update
    ```

## Using the SDK:

### Initializing the AppId client SDK
1. Open your Xcode project and enable Keychain Sharing (Under project settings --> Capabilities --> Keychain sharing)
2. Under project setting --> info --> Url Types, Add $(PRODUCT_BUNDLE_IDENTIFIER) as a URL Scheme
3. Add the following import to your AppDelegate.swift file:
```swift
import BluemixAppID
```
4. Initialize the client SDK by passing the tenantId and region parameters to the initialize method. A common, though not mandatory, place to put the initialization code is in the application:didFinishLaunchingWithOptions: method of the AppDelegate in your Swift application.
    ```swift
    AppID.sharedInstance.initialize(tenantId: <tenantId>, bluemixRegion: AppID.<region>)
    ```
5. Add the following code to you AppDelegate file
    ```swift
    func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return AppID.sharedInstance.application(application, open: url, options: options)
    }
    ```


* Replace ״tenantId״ with the App ID service tenantId. <br />
* Replace ״region״ with the App ID region.

For more information on obtaining these values see Before you begin.

### Using Login Widget
After the App ID client SDK is initialized, you can start authenticate users by launching the Login Widget.
Add the following import to the file in which you want to use the using the login Widget:
```swift
import BluemixAppID
```
Then add the following code:
```swift
class delegate : AuthorizationDelegate {
    public func onAuthorizationSuccess(accessToken: AccessToken, identityToken: IdentityToken, response:Response?) {
        //User authenticated
    }

    public func onAuthorizationCanceled() {
        //Authentication canceled by the user
    }

    public func onAuthorizationFailure(error: AuthorizationError) {
        //Exception occurred
    }
}

AppID.sharedInstance.loginWidget?.launch(delegate: delegate())
```
**Note**: The Login widget default configuration use Facebook and Google as authentication options.
    If you configure only one of them the login widget will NOT launch and the user will be redirect to the configured idp authentication screen.

### Invoking protected resources
Add the following imports to the file in which you want to invoke a protected resource request:
```swift
import BMSCore
import BluemixAppID
```
Then add the following code:
```swift
BMSClient.sharedInstance.initialize(bluemixRegion: AppID.<region>)
BMSClient.sharedInstance.authorizationManager = AppIDAuthorizationManager(appid:AppID.sharedInstance)
var request:Request =  Request(url: "<your protected resource url>")
request.send(completionHandler: {(response:Response?, error:Error?) in
    //code handling the response here
})
```

### License
This package contains code licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and may also view the License in the LICENSE file within this package.

[img-bluemix-powered]: https://img.shields.io/badge/bluemix-powered-blue.svg
[url-bluemix]: http://bluemix.net
[url-bintray]: https://bintray.com/ibmcloudsecurity/appid-clientsdk-swift
[img-license]: https://img.shields.io/github/license/ibm-cloud-security/appid-clientsdk-swift.svg
[img-version]: https://img.shields.io/bintray/v/ibmcloudsecurity/maven/appid-clientsdk-swift.svg

[img-github-watchers]: https://img.shields.io/github/watchers/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Watch
[url-github-watchers]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/watchers
[img-github-stars]: https://img.shields.io/github/stars/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Star
[url-github-stars]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/stargazers
[img-github-forks]: https://img.shields.io/github/forks/ibm-cloud-security/appid-clientsdk-swift.svg?style=social&label=Fork
[url-github-forks]: https://github.com/ibm-cloud-security/appid-clientsdk-swift/network

[img-travis-master]: https://travis-ci.org/ibm-cloud-security/appid-clientsdk-swift.svg
[url-travis-master]: https://travis-ci.org/ibm-cloud-security/appid-clientsdk-swift

[img-coveralls-master]: https://coveralls.io/repos/github/ibm-cloud-security/appid-clientsdk-swift/badge.svg
[url-coveralls-master]: https://coveralls.io/github/ibm-cloud-security/appid-clientsdk-swift

[img-codacy]: https://api.codacy.com/project/badge/Grade/d41f8f069dd343769fcbdb55089561fc?branch=master
[url-codacy]: https://www.codacy.com/app/ibm-cloud-security/appid-clientsdk-swift
