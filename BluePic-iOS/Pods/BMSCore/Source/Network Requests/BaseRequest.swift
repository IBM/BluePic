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


// MARK: HttpMethod

/**
    The HTTP method to be used in the `Request` class initializer.
*/
public enum HttpMethod: String {
    case GET, POST, PUT, DELETE, TRACE, HEAD, OPTIONS, CONNECT, PATCH
}



// MARK: - BmsCompletionHandler

/**
    The type of callback sent with BMS network requests
*/
public typealias BmsCompletionHandler = (Response?, NSError?) -> Void



// MARK: - BaseRequest

/**
    Build and send HTTP network requests.

    When building a Request object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as either NSData or plain text when sending the request via one of the following methods:

        sendString(requestBody: String, withCompletionHandler callback: BmsCompletionHandler?)
        sendData(requestBody: NSData, withCompletionHandler callback: BmsCompletionHandler?)
*/
public class BaseRequest: NSObject, NSURLSessionTaskDelegate {
    
    
    // MARK: Constants
    
    public static let CONTENT_TYPE = "Content-Type"
    
    
    
    // MARK: Properties (API)
    
    /// URL that the request is being sent to
    public private(set) var resourceUrl: String
    
    /// HTTP method (GET, POST, etc.)
    public let httpMethod: HttpMethod
    
    /// Request timeout measured in seconds
    public var timeout: Double
    
    /// All request headers
    public var headers: [String: String] = [:]
    
    /// Query parameters to append to the `resourceURL`
    public var queryParameters: [String: String]?
    
    /// The request body can be set when sending the request via the `sendString` or `sendData` methods.
    public private(set) var requestBody: NSData?
    
    /// Determines whether request should follow http redirects
    public var allowRedirects : Bool = true
	
	/// Deterimes the cache policy to use for sending request
	public var cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy
    
    
    
    // MARK: Properties (internal)
    
    // Public access required by BMSSecurity framework
    // The request timeout is set in this NSURLSession's configuration
    public var networkSession: NSURLSession!
    
    // Public access required by BMSAnalytics framework
    public private(set) var startTime: NSTimeInterval = 0.0
    
    // Public access required by BMSAnalytics framework
    public private(set) var trackingId: String = ""
    
    // Public access required by BMSAnalytics framework
    // This will obtain a value when the Analytics class from BMSAnalytics is initialized
    public static var requestAnalyticsData: String?

    var networkRequest: NSMutableURLRequest
    
	private static let logger = Logger.logger(forName: Logger.bmsLoggerPrefix + "request")
    
    
    
    // MARK: Initializer
    
    /**
        Constructs a new request with the specified URL, using the specified HTTP method.
        Additionally this constructor sets a custom timeout.

        - parameter url:             The resource URL
        - parameter method:          The HTTP method to use
        - parameter headers:         Optional headers to add to the request.
        - parameter queryParameters: Optional query parameters to add to the request.
        - parameter timeout:         Timeout in seconds for this request
		- parameter cachePolicy:	 Cache policy to use when sending request
    
        - Note: A relative URL may be supplied if the `BMSClient` class is initialized with an app route beforehand.
    */
    public init(url: String,
               headers: [String: String]?,
               queryParameters: [String: String]?,
               method: HttpMethod = HttpMethod.GET,
               timeout: Double = BMSClient.sharedInstance.defaultRequestTimeout,
               cachePolicy: NSURLRequestCachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy) {
        
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
        networkRequest = NSMutableURLRequest()

		self.cachePolicy = cachePolicy
		
        super.init()
                
        self.networkSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    
    
    // MARK: Methods (API)
    
    /**
        Add a request body and send the request asynchronously.
    
        If the Content-Type header is not already set, it will be set to "text/plain".
    
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.
    
        - parameter requestBody: HTTP request body as NSString
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    public func sendString(requestBody: String, completionHandler: BmsCompletionHandler?) {
        self.requestBody = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Don't want to overwrite content type if it has already been specified as something else
        if headers[BaseRequest.CONTENT_TYPE] == nil {
            headers[BaseRequest.CONTENT_TYPE] = "text/plain"
        }
        
		self.sendWithCompletionHandler(completionHandler)
    }
    
    /**
        Add a request body and send the request asynchronously.
        
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.
    
        - parameter requestBody: HTTP request body as NSData
        - parameter withCompletionHandler: The closure that will be called when this request finishes
    */
    public func sendData(requestBody: NSData, completionHandler: BmsCompletionHandler?) {
        self.requestBody = requestBody
		self.sendWithCompletionHandler(completionHandler)
    }
    
    
    /**
        Send the request asynchronously.
    
        The response received from the server is packaged into a `Response` object which is passed back via the completion handler parameter.
    
        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.

        - parameter completionHandler: The closure that will be called when this request finishes
    */
    public func sendWithCompletionHandler(completionHandler: BmsCompletionHandler?) {
        
        // Add metadata to the request header so that analytics data can be obtained for ALL bms network requests
        
        // The analytics server needs this ID to match each request with its corresponding response
        self.trackingId = NSUUID().UUIDString
        headers["x-wl-analytics-tracking-id"] = self.trackingId
        
        if let requestMetadata = BaseRequest.requestAnalyticsData {
            self.headers["x-mfp-analytics-metadata"] = requestMetadata
        }
        
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        
        if let url = NSURL(string: self.resourceUrl) {
            
            buildAndSendRequestWithUrl(url, callback: completionHandler)
        }
        else {
            let urlErrorMessage = "The supplied resource url is not a valid url."
            BaseRequest.logger.error(urlErrorMessage)
            let malformedUrlError = NSError(domain: BMSCoreError.domain, code: BMSCoreError.MalformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
            completionHandler?(nil, malformedUrlError)
        }
    }
    
    
    
    // MARK: Methods (internal)
    
    
    private func buildAndSendRequestWithUrl(url: NSURL, callback: BmsCompletionHandler?) {
        
        var requestUrl = url
        
        // A callback that builds the Response object and passes it to the user
        let buildAndSendResponse = {
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let networkResponse = Response(responseData: data, httpResponse: response as? NSHTTPURLResponse, isRedirect: self.allowRedirects)
            
            // TODO: Add back in when the Analytics server supports this functionality (estimated for May 2016)
            //            let responseMetadata = Analytics.generateInboundResponseMetadata(self, response: networkResponse, url: originalUrl)
            //            Request.logger.analytics(responseMetadata)
            
            callback?(networkResponse as Response, error)
        }
        
        // Add query parameters to URL
        if queryParameters != nil {
            guard let urlWithQueryParameters = BaseRequest.appendQueryParameters(queryParameters!, toURL: requestUrl) else {
                // This scenario does not seem possible due to the robustness of appendQueryParameters(), but it will stay just in case
                let urlErrorMessage = "Failed to append the query parameters to the resource url."
                BaseRequest.logger.error(urlErrorMessage)
                let malformedUrlError = NSError(domain: BMSCoreError.domain, code: BMSCoreError.MalformedUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: urlErrorMessage])
                callback?(nil, malformedUrlError)
                return
            }
            requestUrl = urlWithQueryParameters
        }
        
        // Build request
        resourceUrl = String(requestUrl)
        networkRequest.URL = requestUrl
        networkRequest.HTTPMethod = httpMethod.rawValue
        networkRequest.allHTTPHeaderFields = headers
        networkRequest.HTTPBody = requestBody
		networkRequest.cachePolicy = cachePolicy
        
        BaseRequest.logger.debug("Sending Request to " + resourceUrl)
        
        // Send request
        self.networkSession.dataTaskWithRequest(networkRequest as NSURLRequest, completionHandler: buildAndSendResponse).resume()
    }
    
    
    /**
        Returns the supplied URL with query parameters appended to it; the original URL is not modified.
        Characters in the query parameters that are not URL safe are automatically converted to percent-encoding.
    
        - parameter parameters:  The query parameters to be appended to the end of the url
        - parameter originalURL: The url that the parameters will be appeneded to
    
        - returns: The original URL with the query parameters appended to it
    */
    static func appendQueryParameters(parameters: [String: String], toURL originalUrl: NSURL) -> NSURL? {
        
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
    
    
    
    // MARK: NSURLSessionTaskDelegate
    
    // Handle HTTP redirection
    public func URLSession(session: NSURLSession,
                          task: NSURLSessionTask,
                          willPerformHTTPRedirection response: NSHTTPURLResponse,
                          newRequest request: NSURLRequest,
                          completionHandler: ((NSURLRequest?) -> Void))
    {
        var redirectRequest: NSURLRequest?
        if allowRedirects {
            BaseRequest.logger.debug("Redirecting: " + String(session))
            redirectRequest = request
        }
        
        completionHandler(redirectRequest)
    }
    
}
