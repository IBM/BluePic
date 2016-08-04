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


/**
    Contains useful data received from an HTTP network response.
*/
public class Response {
	
    // MARK: Properties (API)
    
    /// HTTP status of the response
    public let statusCode: Int?
    
    /// HTTP headers from the response
    public let headers: [NSObject: AnyObject]?
    
    /// The body of the response as a String.
    /// Returns nil if there is no body or an exception occurred when building the response string.
    public let responseText: String?
    
    /// The body of the response as NSData.
    /// Returns nil if there is no body or if the response is not valid NSData.
    public let responseData: NSData?
    
    /// Does the response contain a 2xx status code
    public let isSuccessful: Bool
    
    // MARK: Properties (internal)
    
#if swift(>=3.0)
    internal let httpResponse: HTTPURLResponse?
#else
    internal let httpResponse: NSHTTPURLResponse?
#endif
    
    internal let isRedirect: Bool
    
    
    
    // MARK: Initializer
    
#if swift(>=3.0)
    
    /**
        Store data from the NSHTTPURLResponse
         
        - parameter responseData: Data returned from the server
        - parameter httpResponse: Response object returned from the NSURLSession request
        - parameter isRedirect:   True if the response requires a redirect
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
    
#else
    
    /**
        Store data from the NSHTTPURLResponse
    
        - parameter responseData: Data returned from the server
        - parameter httpResponse: Response object returned from the NSURLSession request
        - parameter isRedirect:   True if the response requires a redirect
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

    
#endif
    
}
