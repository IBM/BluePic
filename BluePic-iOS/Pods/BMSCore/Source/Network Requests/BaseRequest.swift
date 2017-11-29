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



// MARK: - Swift 3

#if swift(>=3.0)

    

/**
    The HTTP method to be used in the `Request` class initializer.
*/
public enum HttpMethod: String {
    
    ///
    case GET
    ///
    case POST
    ///
    case PUT
    ///
    case DELETE
    ///
    case TRACE
    ///
    case HEAD
    ///
    case OPTIONS
    /// 
    case CONNECT
    ///
    case PATCH
}

    

// MARK: - BMSCompletionHandler

/**
    Callback for network requests made with `Request`.
*/
public typealias BMSCompletionHandler = (Response?, Error?) -> Void



/**
    Sends HTTP network requests.
    
    `BaseRequest` is a simpler alternative to `BMSURLSession` that requires no familiarity with Swift's [URLSession](https://developer.apple.com/reference/foundation/urlsession) API.
     
    When building a BaseRequest object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as Data when sending the request via `send(requestBody:completionHandler:)`.
     
    - important: It is recommended to use the `Request` class instead of `BaseRequest`, since it will replace `BaseRequest` in the future.
*/
@available(*, deprecated, message: "Please use the Request class instead.")
open class BaseRequest: NSObject, URLSessionTaskDelegate {
    
    
    // MARK: - Constants
    
    public static let contentType = "Content-Type"
    
    
    
    // MARK: - Properties
    
    /// URL that the request is being sent to.
    public private(set) var resourceUrl: String
    
    /// The HTTP method (GET, POST, etc.).
    public let httpMethod: HttpMethod
    
    /// Request timeout measured in seconds.
    public var timeout: Double
    
    /// All request headers.
    public var headers: [String: String] = [:]
    
    /// The query parameters to append to the `resourceURL`.
    public var queryParameters: [String: String]?
    
    /// The request body is set when sending the request via `send(requestBody:completionHandler:)`.
    public private(set) var requestBody: Data?
    
    /// Determines whether request should follow HTTP redirects.
    public var allowRedirects : Bool = true
	
	/// Deterimes the cache policy to use for sending request.
	public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    
    
    // MARK: - Properties (internal)
    
    // The old session that handles sending requests. 
    // This will be replaced by `urlSession` once BMSSecurity 3.0 is released.
    // Public access required by BMSSecurity framework.
    public var networkSession: URLSession?
    
    // The new session that handles sending requests.
    // Meant to replace `networkSession`.
    // Public access required by BMSSecurity framework.
    public var urlSession: BMSURLSession!
    
    // The unique ID to keep track of each request.
    // Public access required by BMSAnalytics framework.
    open private(set) var trackingId: String = ""
    
    // Metadata for the request.
    // This will obtain a value when the Analytics class from BMSAnalytics is initialized.
    // Public access required by BMSAnalytics framework.
    public static var requestAnalyticsData: String?

    // The current request.
    var networkRequest: URLRequest
    
	private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "request")
    
    
    
    // MARK: - Initializer
    
    /**
        Creates a new request.

        - parameter url:                The resource URL.
        - parameter method:             The HTTP method.
        - parameter headers:            Optional headers to add to the request.
        - parameter queryParameters:    Optional query parameters to add to the request.
        - parameter timeout:            Timeout in seconds for this request.
        - parameter cachePolicy:        Cache policy to use when sending request.
        - parameter autoRetries:        The number of times to retry each request if it fails to send. The conditions for retries are: request timeout, loss of network connectivity, failure to connect to the host, and 504 responses.
     
        - Note: A relative `url` may be supplied if the `BMSClient` class is initialized with a Bluemix app route beforehand.
    */
    public init(url: String,
               method: HttpMethod = HttpMethod.GET,
               headers: [String: String]? = nil,
               queryParameters: [String: String]? = nil,
               timeout: Double = BMSClient.sharedInstance.requestTimeout,
               cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
               autoRetries: Int = 0) {
        
        // Relative URL
        if (!url.contains("http://") && !url.contains("https://")),
            let bmsAppRoute = BMSClient.sharedInstance.bluemixAppRoute {
                
            self.resourceUrl = bmsAppRoute + url
        }
        // Absolute URL
        else {
            self.resourceUrl = url
        }

        self.httpMethod = method
        if headers != nil {
            self.headers = headers!
        }
        self.timeout = timeout
        self.queryParameters = queryParameters
                
        // Set timeout and initialize network session and request
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout

		self.cachePolicy = cachePolicy
        
        self.networkRequest = URLRequest(url: URL(string: "PLACEHOLDER")!)
		
        super.init()
                
        self.urlSession = BMSURLSession(configuration: configuration, delegate: self, delegateQueue: nil, autoRetries: autoRetries)
    }

    
    
    // MARK: - Methods

    /**
        Send the request asynchronously with an optional request body.
        
        The response received from the server is packaged into a `Response` object which is passed back via the supplied completion handler.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.
    
        - parameter requestBody: The HTTP request body.
        - parameter completionHandler: The block that will be called when this request finishes.
    */
    public func send(requestBody: Data? = nil, completionHandler: BMSCompletionHandler?) {
        
        self.requestBody = requestBody
        
        if let url = URL(string: self.resourceUrl) {
            buildAndSendRequest(url: url, callback: completionHandler)
        }
        else {
            let urlErrorMessage = "The supplied resource url is not a valid url."
            BaseRequest.logger.error(message: urlErrorMessage)
            completionHandler?(nil, BMSCoreError.malformedUrl)
        }
    }
    
    
    
    // MARK: - Methods (internal)
    
    private func buildAndSendRequest(url: URL, callback: BMSCompletionHandler?) {
        
        // Wrapper for the original completion handler that converts the NSURLResponse into a Response object
        let buildAndSendResponse = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            let networkResponse = Response(responseData: data, httpResponse: response as? HTTPURLResponse, isRedirect: self.allowRedirects)
            
            var error = error
            if error == nil, let statusCode = networkResponse.statusCode, statusCode >= 400 {
                error = BMSCoreError.serverRespondedWithError
            }
                
            callback?(networkResponse, error)
        }
        
        var requestUrl = url
        
        // Add query parameters to URL
        if queryParameters != nil {
            guard let urlWithQueryParameters = BaseRequest.append(queryParameters: queryParameters!, toURL: requestUrl) else {
                // This scenario does not seem possible due to the robustness of appendQueryParameters(), but it will stay just in case
                let urlErrorMessage = "Failed to append the query parameters to the resource url."
                BaseRequest.logger.error(message: urlErrorMessage)
                callback?(nil, BMSCoreError.malformedUrl)
                return
            }
            requestUrl = urlWithQueryParameters
        }
        
        // Build request
        resourceUrl = String(describing: requestUrl)
        networkRequest.url = requestUrl
        networkRequest.httpMethod = httpMethod.rawValue
        networkRequest.httpBody = requestBody
		networkRequest.cachePolicy = cachePolicy
        for header in self.headers {
            networkRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        BaseRequest.logger.debug(message: "Sending Request to " + resourceUrl)
        
        // Send request
        // Use `networkSession` instead of `urlSession` only if using an old version of BMSSecurity that doesn't support BMSURLSession.
        if networkSession != nil {
            self.networkSession!.dataTask(with: networkRequest, completionHandler: buildAndSendResponse).resume()
        }
        else {
            self.urlSession.dataTask(with: networkRequest, completionHandler: buildAndSendResponse).resume()
        }
    }
    
    
    /**
        Returns the supplied URL with query parameters appended to it; the original URL is not modified.
        Characters in the query parameters that are not URL safe are automatically converted to percent-encoding.
    
        - parameter parameters:  The query parameters to be appended to the end of the url
        - parameter originalURL: The url that the parameters will be appeneded to
    
        - returns: The original URL with the query parameters appended to it
    */
    static func append(queryParameters: [String: String], toURL originalUrl: URL) -> URL? {
        
        if queryParameters.isEmpty {
            return originalUrl
        }
        
        var parametersInURLFormat = [URLQueryItem]()
        for (key, value) in queryParameters {
            parametersInURLFormat += [URLQueryItem(name: key, value: value)]
        }
        
        if var newUrlComponents = URLComponents(url: originalUrl, resolvingAgainstBaseURL: false) {
            if newUrlComponents.queryItems != nil {
                newUrlComponents.queryItems!.append(contentsOf: parametersInURLFormat)
            }
            else {
                newUrlComponents.queryItems = parametersInURLFormat
            }
            return newUrlComponents.url
        }
        else {
            return nil
        }
    }
    
    
    
    // MARK: - URLSessionTaskDelegate
    
    // Handle HTTP redirection
    public func urlSession(_ session: URLSession,
                          task: URLSessionTask,
                          willPerformHTTPRedirection response: HTTPURLResponse,
                          newRequest request: URLRequest,
                          completionHandler: @escaping (URLRequest?) -> Void) {
        
        var redirectRequest: URLRequest?
        if allowRedirects {
            BaseRequest.logger.debug(message: "Redirecting: " + String(describing: session))
            redirectRequest = request
        }
        
        completionHandler(redirectRequest)
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    

/**
    The HTTP method to be used in the `Request` class initializer.
*/
public enum HttpMethod: String {

    ///
    case GET
    ///
    case POST
    ///
    case PUT
    ///
    case DELETE
    ///
    case TRACE
    ///
    case HEAD
    ///
    case OPTIONS
    ///
    case CONNECT
    ///
    case PATCH
}
    
    
    
// MARK: - BMSCompletionHandler

/**
    Callback for network requests made with `Request`.
*/
public typealias BMSCompletionHandler = (Response?, NSError?) -> Void
    


/**
    Sends HTTP network requests.

    `BaseRequest` is a simpler alternative to `BMSURLSession` that requires no familiarity with Swift's [NSURLSession](https://developer.apple.com/reference/foundation/urlsession) API.

    When building a BaseRequest object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as NSData when sending the request via `send(requestBody:completionHandler:)`.

    - important: It is recommended to use the `Request` class instead of `BaseRequest`, since it will replace `BaseRequest` in the future.
*/
@available(*, deprecated, message="Please use the Request class instead.")
public class BaseRequest: NSObject, NSURLSessionTaskDelegate {
    
    
    // MARK: - Constants
    
    public static let contentType = "Content-Type"
    
    
    
    // MARK: - Properties
    
    /// URL that the request is being sent to.
    public private(set) var resourceUrl: String
    
    /// The HTTP method (GET, POST, etc.).
    public let httpMethod: HttpMethod
    
    /// Request timeout measured in seconds.
    public var timeout: Double
    
    /// All request headers.
    public var headers: [String: String] = [:]
    
    /// Query parameters to append to the `resourceURL`.
    public var queryParameters: [String: String]?
    
    /// The request body is set when sending the request via `send(requestBody:completionHandler:)`.
    public private(set) var requestBody: NSData?
    
    /// Determines whether request should follow HTTP redirects.
    public var allowRedirects : Bool = true
    
    /// Deterimes the cache policy to use for sending request.
    public var cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy
    
    
    
    // MARK: - Properties (internal)
    
    // The old session that handles sending requests.
    // This will be replaced by `urlSession` once BMSSecurity 3.0 is released.
    // Public access required by BMSSecurity framework.
    public var networkSession: NSURLSession?
    
    // The new session that handles sending requests.
    // Meant to replace `networkSession`.
    // Public access required by BMSSecurity framework.
    public var urlSession: BMSURLSession!
    
    // The unique ID to keep track of each request.
    // Public access required by BMSAnalytics framework.
    public private(set) var trackingId: String = ""
    
    // Metadata for the request.
    // This will obtain a value when the Analytics class from BMSAnalytics is initialized.
    // Public access required by BMSAnalytics framework.
    public static var requestAnalyticsData: String?
    
    // The current request.
    var networkRequest: NSMutableURLRequest
    
    private static let logger = Logger.logger(name: Logger.bmsLoggerPrefix + "request")
    
    
    
    // MARK: - Initializer
    
    /**
        Creates a new request.

        - parameter url:                The resource URL.
        - parameter method:             The HTTP method.
        - parameter headers:            Optional headers to add to the request.
        - parameter queryParameters:    Optional query parameters to add to the request.
        - parameter timeout:            Timeout in seconds for this request.
        - parameter cachePolicy:        Cache policy to use when sending request.
        - parameter autoRetries:        The number of times to retry each request if it fails to send. The conditions for retries are: request timeout, loss of network connectivity, failure to connect to the host, and 504 responses.

        - Note: A relative `url` may be supplied if the `BMSClient` class is initialized with a Bluemix app route beforehand.
    */
    public init(url: String,
               method: HttpMethod = HttpMethod.GET,
               headers: [String: String]? = nil,
               queryParameters: [String: String]? = nil,
               timeout: Double = BMSClient.sharedInstance.requestTimeout,
               cachePolicy: NSURLRequestCachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy,
               autoRetries: Int = 0) {
    
        // Relative URL
        if (!url.containsString("http://") && !url.containsString("https://")),
            let bmsAppRoute = BMSClient.sharedInstance.bluemixAppRoute {
            
            self.resourceUrl = bmsAppRoute + url
        }
        // Absolute URL
        else {
            self.resourceUrl = url
        }
        
        self.httpMethod = method
        if headers != nil {
            self.headers = headers!
        }
        self.timeout = timeout
        self.queryParameters = queryParameters
        
        // Set timeout and initialize network session and request
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeout
        
        self.cachePolicy = cachePolicy
        
        self.networkRequest = NSMutableURLRequest(URL: NSURL(string: "PLACEHOLDER")!)
        
        super.init()
        
        self.urlSession = BMSURLSession(configuration: configuration, delegate: self, delegateQueue: nil, autoRetries: autoRetries)
    }
    
    
    
    // MARK: - Methods
    
    /**
        Send the request asynchronously with an optional request body.

        The response received from the server is packaged into a `Response` object which is passed back via the supplied completion handler.

        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.

        - parameter requestBody: The HTTP request body.
        - parameter completionHandler: The block that will be called when this request finishes.
    */
    public func send(requestBody requestBody: NSData? = nil, completionHandler: BMSCompletionHandler?) {
        
        self.requestBody = requestBody

        if let url = NSURL(string: self.resourceUrl) {
            buildAndSendRequest(url: url, callback: completionHandler)
        }
        else {
            let urlErrorMessage = "The supplied resource url is not a valid url."
            BaseRequest.logger.error(message: urlErrorMessage)
            let malformedUrlError = NSError(domain: BMSCoreError.domain, code: BMSCoreError.malformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
            completionHandler?(nil, malformedUrlError)
        }
    }
    
    
    
    // MARK: - Methods (internal)
    
    private func buildAndSendRequest(url url: NSURL, callback: BMSCompletionHandler?) {

        // Wrapper for the original completion handler that converts the NSURLResponse into a Response object
        let buildAndSendResponse = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let networkResponse = Response(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            var error = error
            if error == nil, let statusCode = networkResponse.statusCode where statusCode >= 400 {
                error = NSError(domain: BMSCoreError.domain, code: BMSCoreError.serverRespondedWithError.rawValue, userInfo: nil)
            }
            
            callback?(networkResponse, error)
        }
    
        var requestUrl = url
    
        // Add query parameters to URL
        if queryParameters != nil {
            guard let urlWithQueryParameters = BaseRequest.append(queryParameters: queryParameters!, toURL: requestUrl) else {
                // This scenario does not seem possible due to the robustness of appendQueryParameters(), but it will stay just in case
                let urlErrorMessage = "Failed to append the query parameters to the resource url."
                BaseRequest.logger.error(message: urlErrorMessage)
                let malformedUrlError = NSError(domain: BMSCoreError.domain, code: BMSCoreError.malformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
                callback?(nil, malformedUrlError)
                return
            }
            requestUrl = urlWithQueryParameters
        }
        
        // Build request
        resourceUrl = String(requestUrl)
        networkRequest.URL = requestUrl
        networkRequest.HTTPMethod = httpMethod.rawValue
        networkRequest.HTTPBody = requestBody
        networkRequest.cachePolicy = cachePolicy
        for header in self.headers {
            networkRequest.setValue(header.1, forHTTPHeaderField: header.0)
        }
        
        BaseRequest.logger.debug(message: "Sending Request to " + resourceUrl)
        
        // Send request
        // Use `networkSession` instead of `urlSession` only if using an old version of BMSSecurity that doesn't support BMSURLSession.
        if networkSession != nil {
            self.networkSession!.dataTaskWithRequest(networkRequest, completionHandler: buildAndSendResponse).resume()
        }
        else {
            self.urlSession.dataTaskWithRequest(networkRequest, completionHandler: buildAndSendResponse).resume()
        }
    }
    
    
    /**
        Returns the supplied URL with query parameters appended to it; the original URL is not modified.
        Characters in the query parameters that are not URL safe are automatically converted to percent-encoding.

        - parameter parameters:  The query parameters to be appended to the end of the url
        - parameter originalURL: The url that the parameters will be appeneded to

        - returns: The original URL with the query parameters appended to it
    */
    static func append(queryParameters parameters: [String: String], toURL originalUrl: NSURL) -> NSURL? {
    
        if parameters.isEmpty {
            return originalUrl
        }
        
        var parametersInURLFormat = [NSURLQueryItem]()
        for (key, value) in parameters {
            parametersInURLFormat += [NSURLQueryItem(name: key, value: value)]
        }
        
        if let newUrlComponents = NSURLComponents(URL: originalUrl, resolvingAgainstBaseURL: false) {
            if newUrlComponents.queryItems != nil {
                newUrlComponents.queryItems!.appendContentsOf(parametersInURLFormat)
            }
            else {
                newUrlComponents.queryItems = parametersInURLFormat
            }
            return newUrlComponents.URL
        }
        else {
            return nil
        }
    }
    
    
    
    // MARK: - NSURLSessionTaskDelegate
    
    // Handle HTTP redirection
    public func URLSession(session: NSURLSession,
                          task: NSURLSessionTask,
                          willPerformHTTPRedirection response: NSHTTPURLResponse,
                          newRequest request: NSURLRequest,
                          completionHandler: ((NSURLRequest?) -> Void)) {
    
        var redirectRequest: NSURLRequest?
        if allowRedirects {
            BaseRequest.logger.debug(message: "Redirecting: " + String(session))
            redirectRequest = request
        }
    
        completionHandler(redirectRequest)
    }
    
}


    
#endif
