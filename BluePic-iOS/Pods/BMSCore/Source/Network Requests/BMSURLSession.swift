/*
*     Copyright 2017 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/


import BMSAnalyticsAPI

// MARK: - Swift 3

#if swift(>=3.0)


    
/// Callback for data tasks created with `BMSURLSession`.
public typealias BMSDataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void


    
/**
    Sends HTTP network requests.

    `BMSURLSession` is an alternative to `BaseRequest` that provides more flexibility and control over requests and their responses.
     
    It is built as a wrapper around Swift's [URLSession](https://developer.apple.com/reference/foundation/urlsession) API that incorporates Bluemix Mobile Services. 
    It automatically gathers [Mobile Analytics](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html) data on each network request, and can be used to access backends that are protected by [Mobile Client Access](https://console.ng.bluemix.net/docs/services/mobileaccess/overview.html).

    Currently, `BMSURLSession` only supports [URLSessionDataTask](https://developer.apple.com/reference/foundation/urlsessiondatatask) and [URLSessionUploadTask](https://developer.apple.com/reference/foundation/urlsessionuploadtask).
*/
public struct BMSURLSession: NetworkSession {

    
    // MARK: - Properties (internal)
    
    // Determines whether metadata gets recorded for all BMSURLSession network requests
    // Should only be set to true by passing DeviceEvent.network in the Analytics.initialize() method in the BMSAnalytics framework
    public static var shouldRecordNetworkMetadata: Bool = false
    
    // Should only be set to true by the BMSSecurity framework when creating a BMSURLSession request for authenticating with the MCA authorization server
    public var isBMSAuthorizationRequest: Bool = false
    
    
    // User-specified URLSession configuration
    internal let configuration: URLSessionConfiguration
    
    // User-specified URLSession delegate
    internal let delegate: URLSessionDelegate?
    
    // User-specified URLSession delegate queue
    internal let delegateQueue: OperationQueue?
    
    
    // The number of times a failed request should be retried, specified by the user
    internal let numberOfRetries: Int
    
    // Internal logger for BMSURLSession activity
    internal static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    // MARK: - Initializer
    
    /**
        Creates a network session similar to `URLSession`.

        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
        - parameter autoRetries:    The number of times to retry each request if it fails to send. The conditions for retries are: timeout, loss of network connectivity, failure to connect to the host, and 504 responses.
    */
    public init(configuration: URLSessionConfiguration = .default,
                delegate: URLSessionDelegate? = nil,
                delegateQueue: OperationQueue? = nil,
                autoRetries: Int = 0) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        self.numberOfRetries = autoRetries
    }
    
    
    
    // MARK: - Methods
    
    /**
        Creates a task that retrieves the contents of the specified URL.
     
        To start the task, you must call its `resume()` method.

        - parameter url:  The URL to retrieve data from.
     
        - returns: A data task.
    */
    public func dataTask(with url: URL) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTask(with url: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
     
        - returns: A data task.
    */
    public func dataTask(with request: URLRequest) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTask(with: bmsRequest)
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object,
        and passes the response to the completion handler.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTask(with request: URLRequest, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: nil, numberOfRetries: numberOfRetries)
        
        let dataTask = urlSession.dataTask(with: bmsRequest, completionHandler: bmsCompletionHandler)
        return dataTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: bodyData, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        var fileContents: Data? = nil
        do {
            fileContents = try Data(contentsOf: fileURL)
        }
        catch(let error) {
            BMSURLSession.logger.warn(message: "Cannot retrieve the contents of the file \(fileURL.absoluteString). Error: \(error)")
        }
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: fileContents, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
}

    

// Needed to use BMSURLSession and URLSession interchangeably
internal protocol NetworkSession {
    
    func dataTask(with url: URL) -> URLSessionDataTask
    func dataTask(with url: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask
    func dataTask(with request: URLRequest) -> URLSessionDataTask
    func dataTask(with request: URLRequest, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask
    
    func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask
}

extension URLSession: NetworkSession { }
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    
// MARK: BMSURLSession (Swift 2)
    
/// Callback for data tasks created with `BMSURLSession`.
public typealias BMSDataTaskCompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void


/**
    Sends HTTP network requests.

    `BMSURLSession` is an alternative to `BaseRequest` that provides more flexibility and control over requests and their responses.

    It is built as a wrapper around Swift's [NSURLSession](https://developer.apple.com/reference/foundation/urlsession) API that incorporates Bluemix Mobile Services.
    It automatically gathers [Mobile Analytics](https://console.ng.bluemix.net/docs/services/mobileanalytics/mobileanalytics_overview.html) data on each network request, and can be used to access backends that are protected by [Mobile Client Access](https://console.ng.bluemix.net/docs/services/mobileaccess/overview.html).

    Currently, `BMSURLSession` only supports [NSURLSessionDataTask](https://developer.apple.com/reference/foundation/urlsessiondatatask) and [NSURLSessionUploadTask](https://developer.apple.com/reference/foundation/urlsessionuploadtask).
*/
public struct BMSURLSession: NetworkSession {
    
    
    // MARK: - Properties (internal)
    
    // Determines whether metadata gets recorded for all BMSURLSession network requests
    // Should only be set to true by passing DeviceEvent.network in the Analytics.initialize() method in the BMSAnalytics framework
    public static var shouldRecordNetworkMetadata: Bool = false
    
    // Should only be set to true by the BMSSecurity framework when creating a BMSURLSession request for authenticating with the MCA authorization server
    public var isBMSAuthorizationRequest: Bool = false
    
    
    // User-specified URLSession configuration
    internal let configuration: NSURLSessionConfiguration
    
    // User-specified URLSession delegate
    internal let delegate: NSURLSessionDelegate?
    
    // User-specified URLSession delegate queue
    internal let delegateQueue: NSOperationQueue?
    
    
    // The number of times a failed request should be retried, specified by the user
    internal let numberOfRetries: Int
    
    // Internal logger for BMSURLSession activity
    internal static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    // MARK: - Initializer
    
    /**
        Creates a network session similar to `NSURLSession`.
     
        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
        - parameter autoRetries:    The number of times to retry each request if it fails to send. The conditions for retries are: timeout, loss of network connectivity, failure to connect to the host, and 504 responses.
    */
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
                delegate: NSURLSessionDelegate? = nil,
                delegateQueue: NSOperationQueue? = nil,
                autoRetries: Int = 0) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        self.numberOfRetries = autoRetries
    }
    
    
    
    // MARK: - Methods
    
    /**
        Creates a task that retrieves the contents of the specified URL.
     
        To start the task, you must call its `resume()` method.
     
        - parameter url:  The URL to retrieve data from.
     
        - returns: A data task.
    */
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.
     
        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.
     
        To start the task, you must call its `resume()` method.
     
        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
     
        - returns: A data task.
    */
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object, 
        and passes the response to the completion handler.
     
        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: A data task.
    */
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: nil, numberOfRetries: numberOfRetries)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        return dataTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.
     
        To start the task, you must call its `resume()` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume()` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: bodyData, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, bmsUrlSession: self, originalTask: originalTask, numberOfRetries: numberOfRetries)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume()` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
        The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
     
        - returns: An upload task.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let fileContents = NSData(contentsOfURL: fileURL)
        if fileContents == nil {
            BMSURLSession.logger.warn(message: "Cannot retrieve the contents of the file \(fileURL.absoluteString).")
        }
        
        let bmsRequest = BMSURLSessionUtility.addBMSHeaders(to: request, onlyIf: !isBMSAuthorizationRequest)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSessionUtility.generateBmsCompletionHandler(from: completionHandler, bmsUrlSession: self, urlSession: urlSession, request: bmsRequest, originalTask: originalTask, requestBody: fileContents, numberOfRetries: numberOfRetries)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        return uploadTask
    }
}



// Needed to use BMSURLSession and URLSession interchangeably
internal protocol NetworkSession {
    
    func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask
    func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask
    func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask
    func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask
    
    func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask
    func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask
    func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask
    func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask
}

extension NSURLSession: NetworkSession { }

    
    
#endif
