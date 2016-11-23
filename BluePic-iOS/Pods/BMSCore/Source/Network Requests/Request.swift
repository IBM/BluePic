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
    Sends HTTP network requests. It is recommended to use this class instead of `BaseRequest`.

    For more information on `Request`, see the documentation for `BaseRequest`.
*/
open class Request: BaseRequest {
    
    
    // MARK: Properties (internal)
    
    internal var oauthFailCounter = 0
    
    internal var savedRequestBody: Data?
    
    
    
    // MARK: Method override
    
    /**
        Send the request asynchronously with an optional request body.

        The response received from the server is packaged into a `Response` object which is passed back via the supplied completion handler.

        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.

        - parameter requestBody: The HTTP request body.
        - parameter completionHandler: The block that will be called when this request finishes.
     */
    public override func send(requestBody: Data? = nil, completionHandler: BMSCompletionHandler?) {
        
        let authManager: AuthorizationManager = BMSClient.sharedInstance.authorizationManager
        
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            self.headers["Authorization"] = authHeader
        }
        
        savedRequestBody = requestBody
        
        let sendCompletionHandler : BMSCompletionHandler = {(response: Response?, error: Error?) in
            
            guard error == nil else {
				if let completionHandler = completionHandler{
					completionHandler(response, error)
				}
                return
            }
			
			let authManager = BMSClient.sharedInstance.authorizationManager
            guard let unWrappedResponse = response,
					authManager.isAuthorizationRequired(for: unWrappedResponse) &&
                    self.oauthFailCounter < 2
			else {
                self.oauthFailCounter += 1
                if (response?.statusCode)! >= 400 {
                    completionHandler?(response, BMSCoreError.serverRespondedWithError)
                }
                else {
                    completionHandler?(response, nil)
                }
                return
            }
            
            self.oauthFailCounter += 1
            
            let authCallback: BMSCompletionHandler = {(response: Response?, error:Error?) in
                if error == nil {
                    if let myRequestBody = self.requestBody {
                        self.send(requestBody: myRequestBody, completionHandler: completionHandler)
                    }
                    else {
                        self.send(completionHandler: completionHandler)
                    }
                } else {
                    completionHandler?(response, error)
                }
            }
			authManager.obtainAuthorization(completionHandler: authCallback)
        }
        
        super.send(requestBody: requestBody, completionHandler: sendCompletionHandler)
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
/**
    Sends HTTP network requests. It is recommended to use this class instead of `BaseRequest`.

    When building a Request object, all components of the HTTP request must be provided in the initializer, except for the `requestBody`, which can be supplied as Data when sending the request via `send(requestBody:completionHandler:)`.

    For more information on `Request`, see the documentation for `BaseRequest`.
*/
public class Request: BaseRequest {
    
    
    // MARK: Properties (internal)
    
    internal var oauthFailCounter = 0
    
    internal var savedRequestBody: NSData?
    
    
    
    // MARK: Method overrides
    
    /**
        Send the request asynchronously with an optional request body.

        The response received from the server is packaged into a `Response` object which is passed back via the supplied completion handler.

        If the `resourceUrl` string is a malformed url or if the `queryParameters` cannot be appended to it, the completion handler will be called back with an error and a nil `Response`.

        - parameter requestBody: The HTTP request body.
        - parameter completionHandler: The block that will be called when this request finishes.
     */
    public override func send(requestBody requestBody: NSData? = nil, completionHandler: BMSCompletionHandler?) {
    
        let authManager: AuthorizationManager = BMSClient.sharedInstance.authorizationManager
        
        if let authHeader: String = authManager.cachedAuthorizationHeader {
            self.headers["Authorization"] = authHeader
        }
        
        savedRequestBody = requestBody
        
        let sendCompletionHandler : BMSCompletionHandler = {(response: Response?, error: NSError?) in
        
            guard error == nil else {
                if let callback = completionHandler {
                    callback(response, error)
                }
                return
            }
    
            let authManager = BMSClient.sharedInstance.authorizationManager
            guard let unWrappedResponse = response where
                                          authManager.isAuthorizationRequired(for: unWrappedResponse) &&
                                          self.oauthFailCounter < 2
            else {
                self.oauthFailCounter += 1
                if (response?.statusCode)! >= 400 {
                    completionHandler?(response, NSError(domain: BMSCoreError.domain, code: BMSCoreError.serverRespondedWithError.rawValue, userInfo: nil))
                }
                else {
                    completionHandler?(response, nil)
                }
                return
            }
    
            self.oauthFailCounter += 1
        
            let authCallback: BMSCompletionHandler = {(response: Response?, error:NSError?) in
                if error == nil {
                    if let myRequestBody = self.requestBody {
                        self.send(requestBody: myRequestBody, completionHandler: completionHandler)
                    }
                    else {
                        self.send(completionHandler: completionHandler)
                    }
                }
                else {
                    completionHandler?(response, error)
                }
            }
            authManager.obtainAuthorization(completionHandler: authCallback)
        }
        
        super.send(requestBody: requestBody, completionHandler: sendCompletionHandler)
    }

}



#endif
