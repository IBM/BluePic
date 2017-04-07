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


    
/**
    Contains useful response data from an HTTP request made by the `Request` class.
*/
public class Response {
	
    
    // MARK: - Properties
    
    /// The HTTP status of the response.
    public let statusCode: Int?
    
    /// HTTP headers from the response.
    public let headers: [AnyHashable: Any]?
    
    /// The body of the response.
    /// Returns nil if there is no body or the body cannot be converted to a `String`.
    public let responseText: String?
    
    /// The body of the response.
    /// Returns nil if there is no body or if the response is not valid `Data`.
    public let responseData: Data?

    /// The response is considered successful if the returned status code is in the 2xx range.
    public let isSuccessful: Bool
    
    
    
    // MARK: - Properties (internal)
    
    internal let httpResponse: HTTPURLResponse?
    
    internal let isRedirect: Bool
    
    
    
    // MARK: - Initializer
    
    /**
        Converts an `HTTPURLResponse` to a more accessible response object.

        - parameter responseData: Data returned from the server.
        - parameter httpResponse: Response object returned from the `URLSession` request.
        - parameter isRedirect:   True if the response requires a redirect.
    */
    public init(responseData: Data?, httpResponse: HTTPURLResponse?, isRedirect: Bool) {
        
        self.isRedirect = isRedirect
        self.httpResponse = httpResponse
        self.headers = httpResponse?.allHeaderFields
        self.statusCode = httpResponse?.statusCode
        
        self.responseData = responseData
        if let responseData = responseData {
            self.responseText = String(data: responseData, encoding: .utf8)
        }
        else {
            self.responseText = nil
        }
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    
/**
    Contains useful response data from an HTTP request made by the `Request` class.
*/
public class Response {
    
    
    // MARK: - Properties
    
    /// The HTTP status of the response.
    public let statusCode: Int?
    
    /// HTTP headers from the response.
    public let headers: [NSObject: AnyObject]?
    
    /// The body of the response.
    /// Returns nil if there is no body or the body cannot be converted to a `String`.
    public let responseText: String?
    
    /// The body of the response.
    /// Returns nil if there is no body or if the response is not valid `NSData`.
    public let responseData: NSData?
    
    /// The response is considered successful if the returned status code is in the 2xx range.
    public let isSuccessful: Bool
    
    
    
    // MARK: - Properties (internal)
    
    internal let httpResponse: NSHTTPURLResponse?
    
    internal let isRedirect: Bool
    
    
    
    // MARK: - Initializer
    
    /**
        Converts an `NSHTTPURLResponse` to a more accessible `Response` object.

        - parameter responseData: Data returned from the server.
        - parameter httpResponse: Response object returned from the `NSURLSession` request.
        - parameter isRedirect:   True if the response requires a redirect.
    */
    public init(responseData: NSData?, httpResponse: NSHTTPURLResponse?, isRedirect: Bool) {
    
        self.isRedirect = isRedirect
        self.httpResponse = httpResponse
        self.headers = httpResponse?.allHeaderFields
        self.statusCode = httpResponse?.statusCode
        
        self.responseData = responseData
        if responseData != nil, let responseAsNSString = NSString(data: responseData!, encoding: NSUTF8StringEncoding) {
            self.responseText = String(responseAsNSString)
        }
        else {
            self.responseText = nil
        }
        
        if let status = statusCode {
            isSuccessful = (200..<300 ~= status)
        }
        else {
            isSuccessful = false
        }
    }
    
}



#endif
