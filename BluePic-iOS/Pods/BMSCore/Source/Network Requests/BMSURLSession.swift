/*
*     Copyright 2016 IBM Corp.
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



// MARK: - Swift 3

#if swift(>=3.0)


    
/// Callback for data tasks created with BMSURLSession.
public typealias BMSDataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void
    

    
/**
    A wrapper around Swift's `URLSession` API that incorporates
    Bluemix Mobile Services. Use this API to gather analytics data on your network requests
    and/or to access backends that are protected by Mobile Client Access.

    Currently, `BMSURLSession` only supports `URLSessionDataTask` and `URLSessionUploadTask`.

    For more information, refer to the documentation for `NSURLSession` in the Swift `Foundation` framework.
*/
public struct BMSURLSession {

    
    private let configuration: URLSessionConfiguration
    
    private let delegate: URLSessionDelegate?
    
    private let delegateQueue: OperationQueue?
    
    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    /**
        Creates a network session similar to `URLSession`.

        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
    */
    public init(configuration: URLSessionConfiguration = .default,
                delegate: URLSessionDelegate? = nil,
                delegateQueue: OperationQueue? = nil) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    
    
    // MARK: - Data tasks
    
    /**
        Creates a task that retrieves the contents of the specified URL.

        To start the task, you must call its `resume` method.

        - parameter url:  The URL to retrieve data from.
    */
    public func dataTask(with url: URL) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.

        To start the task, you must call its `resume` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func dataTask(with url: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        return dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.

        To start the task, you must call its `resume` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
    */
    public func dataTask(with request: URLRequest) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTask(with: bmsRequest)
        
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object,
        and passes the response to the completion handler.

        To start the task, you must call its `resume` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func dataTask(with request: URLRequest, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let dataTask = urlSession.dataTask(with: bmsRequest, completionHandler: bmsCompletionHandler)
        
        return dataTask
    }
    
    
    
    // MARK: - Upload tasks
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, from: bodyData, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        let urlSession = URLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping BMSDataTaskCompletionHandler) -> URLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTask(with: bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    
    // MARK: - Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: URLRequest) -> URLRequest {
        
        var bmsRequest = request
        
        // Security
        let authManager = BMSClient.sharedInstance.authorizationManager
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Analytics
        bmsRequest.setValue(UUID().uuidString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
        if let requestMetadata = BaseRequest.requestAnalyticsData {
            bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
        }
        
        return bmsRequest
    }
    
    
    internal static func isAuthorizationManagerRequired(for response: URLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? HTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["Www-Authenticate"] as? String,
            authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new URLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: URLSession, request: URLRequest, originalTask: BMSURLSessionTaskType, handleTask: @escaping (URLSessionTask?) -> Void){
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:Error?) in
            
            if error == nil && response?.statusCode != nil && (response?.statusCode)! >= 200 && (response?.statusCode)! < 300 {
                
                // Resend the original request with the "Authorization" header
                
                var request = request
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                // Figure out the original URLSessionTask created by the user, and pass it back to the completionHandler
                switch originalTask {
                    
                case .dataTask:
                    handleTask(urlSession.dataTask(with: request))
                    
                case .dataTaskWithCompletionHandler(let completionHandler):
                    handleTask(urlSession.dataTask(with: request, completionHandler: completionHandler))
                    
                case .uploadTaskWithFile(let file):
                    handleTask(urlSession.uploadTask(with: request, fromFile: file))
                    
                case .uploadTaskWithData(let data):
                    handleTask(urlSession.uploadTask(with: request, from: data))
                    
                case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
                    handleTask(urlSession.uploadTask(with: request, fromFile: file, completionHandler: completionHandler))
                    
                case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
                    handleTask(urlSession.uploadTask(with: request, from: data, completionHandler: completionHandler))
                }
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleTask(nil)
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: @escaping BMSDataTaskCompletionHandler, urlSession: URLSession, request: URLRequest, originalTask: BMSURLSessionTaskType) -> BMSDataTaskCompletionHandler {
        
        return { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if BMSURLSession.isAuthorizationManagerRequired(for: response) {
                
                // Resend the original request with the "Authorization" header added
                BMSURLSession.handleAuthorizationChallenge(session: urlSession, request: request, originalTask: originalTask, handleTask: { (urlSessionTask) in
                    
                    if let taskWithAuthorization = urlSessionTask {
                        taskWithAuthorization.resume()
                    }
                    else {
                        completionHandler(data, response, error)
                    }
                })
            }
            else {
                completionHandler(data, response, error)
            }
        }
    }
}
    
    
    
// List of the supported types of URLSessionTask
// Stored in BMSURLSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(URL)
    case uploadTaskWithData(Data)
    case uploadTaskWithFileAndCompletionHandler(URL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(Data?, BMSDataTaskCompletionHandler)
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
   
// MARK: BMSURLSession (Swift 2)
    
/// Callback for data tasks created with BMSURLSession.
public typealias BMSDataTaskCompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void


/**
    A wrapper around Swift's `URLSession` API that incorporates
    Bluemix Mobile Services. Use this API to gather analytics data on your network requests
    and/or to access backends that are protected by Mobile Client Access.

    Currently, `BMSURLSession` only supports `URLSessionDataTask` and `URLSessionUploadTask`.

    For more information, refer to the documentation for `NSURLSession` in the Swift `Foundation` framework.
*/
public struct BMSURLSession {
    
    
    private let configuration: NSURLSessionConfiguration
    
    private let delegate: NSURLSessionDelegate?
    
    private let delegateQueue: NSOperationQueue?
    
    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "urlSession")
    
    
    
    /**
        Creates a network session similar to `NSURLSession`.
     
        - parameter configuration:  Defines the behavior of the session.
        - parameter delegate:       Handles session-related events. If nil, use task methods that take completion handlers.
        - parameter delegateQueue:  Queue for scheduling the delegate calls and completion handlers.
    */
    public init(configuration: NSURLSessionConfiguration = .defaultSessionConfiguration(),
                delegate: NSURLSessionDelegate? = nil,
                delegateQueue: NSOperationQueue? = nil) {
        
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    
    
    // MARK: - Data tasks
    
    /**
        Creates a task that retrieves the contents of the specified URL.
     
        To start the task, you must call its `resume` method.
     
        - parameter url:  The URL to retrieve data from.
    */
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url))
    }
    
    
    /**
        Creates a task that retrieves the contents of the specified URL, and passes the response to the completion handler.
     
        To start the task, you must call its `resume` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter url:                The URL to retrieve data from.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func dataTaskWithURL(url: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        return dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: completionHandler)
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object.
     
        To start the task, you must call its `resume` method.
     
        - parameter request:  An object that provides request-specific information
                              such as the URL, cache policy, request type, and body data.
    */
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.dataTask
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest)
        
        return dataTask
    }
    
    
    /**
        Creates a task that retrieves the contents of a URL based on the specified request object, 
        and passes the response to the completion handler.
     
        To start the task, you must call its `resume` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.
     
        - parameter request:            An object that provides request-specific information
                                        such as the URL, cache policy, request type, and body data.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionDataTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.dataTaskWithCompletionHandler(completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let dataTask = urlSession.dataTaskWithRequest(bmsRequest, completionHandler: bmsCompletionHandler)
        
        return dataTask
    }
    
    
    
    // MARK: - Upload tasks
    
    /**
        Creates a task that uploads data to the URL specified in the request object.
     
        To start the task, you must call its `resume` method.

        - parameter request:   An object that provides request-specific information
                               such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:  The body data for the request.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithData(bodyData)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads data to the URL specified in the request object.

        To start the task, you must call its `resume` method.
     
        - note: It is not recommended to use this method if the session was created with a delegate.
                The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter bodyData:           The body data for the request.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithDataAndCompletionHandler(bodyData, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromData: bodyData, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - parameter request:  An object that provides request-specific information
                              such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:  The location of the file to upload.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFile(fileURL)
        let parentDelegate = BMSURLSessionDelegate(parentDelegate: delegate, originalTask: originalTask)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: parentDelegate, delegateQueue: delegateQueue)
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL)
        
        return uploadTask
    }
    
    
    /**
        Creates a task that uploads a file to the URL specified in the request object.

        To start the task, you must call its `resume` method.

        - note: It is not recommended to use this method if the session was created with a delegate.
        The completion handler will override all delegate methods except those for handling authentication challenges.

        - parameter request:            An object that provides request-specific information
                                        such as the URL and cache policy. The request body is ignored.
        - parameter fileURL:            The location of the file to upload.
        - parameter completionHandler:  The completion handler to call when the request is complete.
    */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: BMSDataTaskCompletionHandler) -> NSURLSessionUploadTask {
        
        let bmsRequest = BMSURLSession.addBMSHeaders(to: request)
        
        let urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        let originalTask = BMSURLSessionTaskType.uploadTaskWithFileAndCompletionHandler(fileURL, completionHandler)
        let bmsCompletionHandler = BMSURLSession.generateBmsCompletionHandler(from: completionHandler, urlSession: urlSession, request: request, originalTask: originalTask)
        
        let uploadTask = urlSession.uploadTaskWithRequest(bmsRequest, fromFile: fileURL, completionHandler: bmsCompletionHandler)
        
        return uploadTask
    }
    
    
    
    // MARK: - Helpers
    
    // Inject BMSSecurity and BMSAnalytics into the request object by adding headers
    internal static func addBMSHeaders(to request: NSURLRequest) -> NSURLRequest {
        
        let bmsRequest = request.mutableCopy() as! NSMutableURLRequest
        
        // Security
        let authManager = BMSClient.sharedInstance.authorizationManager
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            bmsRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Analytics
        bmsRequest.setValue(NSUUID().UUIDString, forHTTPHeaderField: "x-wl-analytics-tracking-id")
        if let requestMetadata = BaseRequest.requestAnalyticsData {
            bmsRequest.setValue(requestMetadata, forHTTPHeaderField: "x-mfp-analytics-metadata")
        }
        
        return bmsRequest
    }
    
    
    internal static func isAuthorizationManagerRequired(response: NSURLResponse?) -> Bool {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        
        if let response = response as? NSHTTPURLResponse,
            let wwwAuthHeader = response.allHeaderFields["WWW-Authenticate"] as? String
            where authManager.isAuthorizationRequired(for: response.statusCode, httpResponseAuthorizationHeader: wwwAuthHeader) {
            
            return true
        }
        return false
    }
    
    
    // Handle the challenge with AuthorizationManager from BMSSecurity.
    // If authentication is successful, a new NSURLSessionTask is generated.
    // This new task is the same as the original task, but now with the "Authorization" header needed to complete the request successfully.
    internal static func handleAuthorizationChallenge(session urlSession: NSURLSession, request: NSMutableURLRequest, originalTask: BMSURLSessionTaskType, handleTask: (NSURLSessionTask?) -> Void) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        let authCallback: BMSCompletionHandler = {(response: Response?, error:NSError?) in
            
            if error == nil && response?.statusCode >= 200 && response?.statusCode < 300 {
                
                // Resend the original request with the "Authorization" header
                
                let authManager = BMSClient.sharedInstance.authorizationManager
                if let authHeader: String = authManager.cachedAuthorizationHeader {
                    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                }
                
                // Figure out the original NSURLSessionTask created by the user, and resend it
                switch originalTask {
                    
                case .dataTask:
                    handleTask(urlSession.dataTaskWithRequest(request))
                    
                case .dataTaskWithCompletionHandler(let completionHandler):
                    handleTask(urlSession.dataTaskWithRequest(request, completionHandler: completionHandler))
                    
                case .uploadTaskWithFile(let file):
                    handleTask(urlSession.uploadTaskWithRequest(request, fromFile: file))
                    
                case .uploadTaskWithData(let data):
                    handleTask(urlSession.uploadTaskWithRequest(request, fromData: data))
                    
                case .uploadTaskWithFileAndCompletionHandler(let file, let completionHandler):
                    handleTask(urlSession.uploadTaskWithRequest(request, fromFile: file, completionHandler: completionHandler))
                    
                case .uploadTaskWithDataAndCompletionHandler(let data, let completionHandler):
                    handleTask(urlSession.uploadTaskWithRequest(request, fromData: data, completionHandler: completionHandler))
                }
            }
            else {
                BMSURLSession.logger.error(message: "Authorization process failed. \nError: \(error). \nResponse: \(response).")
                handleTask(nil)
            }
        }
        authManager.obtainAuthorization(completionHandler: authCallback)
    }
    
    
    // Required to hook in challenge handling via AuthorizationManager
    internal static func generateBmsCompletionHandler(from completionHandler: BMSDataTaskCompletionHandler, urlSession: NSURLSession, request: NSURLRequest, originalTask: BMSURLSessionTaskType) -> BMSDataTaskCompletionHandler {
        
        return { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if BMSURLSession.isAuthorizationManagerRequired(response) {
                
                let originalRequest = request.mutableCopy() as! NSMutableURLRequest
                BMSURLSession.handleAuthorizationChallenge(session: urlSession, request: originalRequest, originalTask: originalTask, handleTask: { (urlSessionTask) in
                    
                    if let taskWithAuthorization = urlSessionTask {
                        taskWithAuthorization.resume()
                    }
                    else {
                        completionHandler(data, response, error)
                    }
                })
            }
            else {
                completionHandler(data, response, error)
            }
        }
    }
}
    
    
    
// List of the supported types of NSURLSessionTask
// Stored in BMSURLSession to determine what type of task to use when resending the request after authenticating with MCA
internal enum BMSURLSessionTaskType {
    
    case dataTask
    case dataTaskWithCompletionHandler(BMSDataTaskCompletionHandler)
    
    case uploadTaskWithFile(NSURL)
    case uploadTaskWithData(NSData)
    case uploadTaskWithFileAndCompletionHandler(NSURL, BMSDataTaskCompletionHandler)
    case uploadTaskWithDataAndCompletionHandler(NSData?, BMSDataTaskCompletionHandler)
}

    
    
#endif
