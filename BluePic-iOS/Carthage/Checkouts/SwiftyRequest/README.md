# SwiftyRequest

[![Build Status - Master](https://travis-ci.org/IBM-Swift/SwiftyRequest.svg?branch=master)](https://travis-ci.org/IBM-Swift/SwiftyRequest)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)

SwiftyRequest is an HTTP networking library built for Swift.

## Contents
* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [CircuitBreaker Integration](#circuitbreaker-integration)
* [Response Methods](#response-methods)

## Features
- Several response methods (e.g. Data, Object, Array, String, etc.) to eliminate boilerplate code in your application.
- JSON encoding and decoding.
- Integration with [CircuitBreaker](https://github.com/IBM-Swift/CircuitBreaker) library.
- Authentication token.
- Multipart form data.

## Swift version
The latest version of SwiftyRequest works with the `3.1.1` and newer versions of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/#releases).

## Installation
To leverage the SwiftyRequest package in your Swift application, you should specify a dependency for it in your `Package.swift` file:

```swift
 import PackageDescription

 let package = Package(
     name: "MySwiftProject",

     ...

     dependencies: [
        // Swift 3.1.1
        .Package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", majorVersion: 0),

        // Swift 4.0
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMajor(from: "0.0.0"),
         ...

     ])
```

## Usage

### Make Requests
To make outbound HTTP calls using SwiftyRequest, You create a `RestRequest` instance. The `method` parameter is optional (defaulting to `.get`) and `url` is required

#### Below is the list of customizeable fields
- `headerParameters`
- `acceptType`
- `messageBody`
- `productInfo`
- `circuitParameters`
- `contentType` : Defaults to `application/json`
- `method` : Defaults to `application/json`

Example usage of `RestRequest`:

```swift
import SwiftyRequest

let request = RestRequest(method: .get, url: "http://myApiCall/hello")
request.credentials = .apiKey
```

### Invoke Response
In this example, `responseToError` is simply an error handling function.
The `response` object we get back is of type `RestResponse<String>` so we can perform a switch on the `response.result` to determine if the network call was successful.

```swift
request.responseString(responseToError: responseToError) { response in
    switch response.result {
    case .success(let result):
        print("Success")
    case .failure(let error):
        print("Failure")
    }
}
```

### Invoke Response with Template Parameters

In this example, we invoke a response method with some template parameters to be used in replacing the `{state}` and `{city}` values in the `url`. This allows us to create multiple response invocations with the same `RestRequest` object, but possibly using different url values. Additionally, the `RequestParameters` is a helper object to bundle up values used to create a `RestRequest` object.

```swift
let request = RestRequest(url: "http://api.weather.com/api/123456/conditions/q/{state}/{city}.json")
request.credentials = .apiKey

request.responseData(templateParams: ["state": "TX", "city": "Austin"]) { response in
	// Handle response
}
```

### Invoke Response with Query Parameters

In this example, we invoke a response method with a query parameter to be appeneded onto the `url` behind the scenes so that the `RestRequest` gets executed with the following url: `http://api.weather.com/api/123456/conditions/q/CA/San_Francisco.json?hour=9`. If no `queryItems` parameter is set, then all query parameters will be removed from the url if any exsisted.

```swift
let request = RestRequest(url: "http://api.weather.com/api/123456/conditions/q/CA/San_Francisco.json")
request.credentials = .apiKey

request.responseData(queryItems: [URLQueryItem(name: "hour", value: "9")]) { response in
	// Handle response	
}
```

## CircuitBreaker Integration

SwiftyRequest now has additional built-in functionality for leveraging the [CircuitBreaker](https://github.com/IBM-Swift/CircuitBreaker) library to increase your application's stability. To make use of this functionality, you just need to provide a `CircuitParameters` object to the `RestRequest` initializer. A `CircuitParameters` object will include a reference to a fallback function that will be invoked when the circuit is failing fast.

### Fallback
Here is an example of a fallback closure:

```swift
let fallback = { (error: BreakerError, msg: String) in
    print("Fallback closure invoked... circuit must be open.")
}
```

### CircuitParameters
We just initialize the `CircuitParameters` object and create a `RestRequest` instance. The only required value you need to set for `CircuitParameters` is the `fallback` (everything else has default values).

```swift
let circuitParameters = CircuitParameters(timeout: 2000,
                                          maxFailures: 2,
                                          fallback: breakFallback)

let request = RestRequest(method: .get, url: "http://myApiCall/hello")
request.credentials = .apiKey,
request.circuitParameters = circuitParameters
```

At this point, you can use any of the response methods mentioned in the section below.

## Response Methods
There are various response methods you can use based on what result type you want, here they are:

- `responseData` returns a `Data` object.
- `responseObject<T: JSONDecodable>` returns an object of type `T`.
- `responseArray<T: JSONDecodable>` returns an array of type `T`.
- `responseString` returns a `String`.
- `responseVoid` returns `Void`.

## License
This Swift package is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
