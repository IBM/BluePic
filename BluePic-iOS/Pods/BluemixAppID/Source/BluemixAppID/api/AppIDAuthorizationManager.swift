/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import Foundation
import BMSCore

public class AppIDAuthorizationManager: BMSCore.AuthorizationManager {


    internal var oAuthManager:OAuthManager
    private static let logger =  Logger.logger(name: Logger.bmsLoggerPrefix + "AppIDAuthorizationManager")
    
    
    /**
     Intializes the App ID Authorization Manager
     @param appid An AppID instance
     */
    public init(appid:AppID) {
        self.oAuthManager = appid.oauthManager!
    }

    /**
     A response is an OAuth error response only if,
     1. it's status is 401 or 403.
     2. The value of the "WWW-Authenticate" header contains 'Bearer'.
     
     - Parameter httpResponse - Response to check the authorization conditions for.
     
     - returns: True if the response satisfies both conditions
     */
    
    
    public func isAuthorizationRequired(for httpResponse: Response) -> Bool {
        AppIDAuthorizationManager.logger.debug(message: "isAuthorizationRequired")
        return AuthorizationHeaderHelper.isAuthorizationRequired(for: httpResponse)
    }
    
    /**
     Check if the params came from response that requires authorization
     
     - Parameter statusCode - Status code of the response
     - Parameter responseAuthorizationHeader - Response header
     
     - returns: True if status is 401 or 403 and The value of the header contains 'Bearer'
     */
    
    
    public func isAuthorizationRequired(for statusCode: Int, httpResponseAuthorizationHeader
        responseAuthorizationHeader: String) -> Bool {
        return AuthorizationHeaderHelper.isAuthorizationRequired(statusCode: statusCode, header: responseAuthorizationHeader)
    }
    
    
    
    
    public func obtainAuthorization(completionHandler callback: BMSCompletionHandler?) {
        AppIDAuthorizationManager.logger.debug(message: "obtainAuthorization")
        class innerAuthorizationDelegate: AuthorizationDelegate {
            var callback:BMSCompletionHandler?
            init(callback:BMSCompletionHandler?) {
                self.callback = callback
            }
            
            func onAuthorizationFailure(error err:AuthorizationError) {
                callback?(nil,err)
            }
            
            func onAuthorizationCanceled () {
                callback?(nil, AuthorizationError.authorizationFailure("Authorization canceled"))
            }
            
            func onAuthorizationSuccess (accessToken:AccessToken, identityToken:IdentityToken, response:Response?) {
                callback?(response,nil)
            }
            
        }
        
        oAuthManager.authorizationManager?.launchAuthorizationUI(authorizationDelegate: innerAuthorizationDelegate(callback: callback))
    }
    
    public func clearAuthorizationData() {
        AppIDAuthorizationManager.logger.debug(message: "clearAuthorizationData")
        self.oAuthManager.tokenManager?.clearStoredToken()
    }
    
    
    
    
    
    
    /**
     - returns: The locally stored authorization header or nil if the value does not exist.
     */
    public var cachedAuthorizationHeader:String? {
        get {
            AppIDAuthorizationManager.logger.debug(message: "getCachedAuthorizationHeader")
            guard let accessToken = self.accessToken, let identityToken = self.identityToken else {
                return nil
            }
            return "Bearer " + accessToken.raw + " " + identityToken.raw
        }
    }
    
    
    
    /**
     Returns the UserIdentity object constructed from the Identity Token if there is one
     */
    public var userIdentity:UserIdentity? {
        let idToken = self.identityToken
        let identity:[String:Any] = [
            BaseUserIdentity.Key.authorizedBy : idToken?.authenticationMethods ?? "",
            BaseUserIdentity.Key.displayName : idToken?.name ?? "",
            BaseUserIdentity.Key.ID : idToken?.subject ?? ""
        ]
        return BaseUserIdentity(map: identity)
        
    }
    /**
     Returns the a DeviceIdentity object
     */
    public var deviceIdentity:DeviceIdentity {
        return BaseDeviceIdentity()
        
    }
    /**
     Returns the an AppIdentity object
     */
    public var appIdentity:AppIdentity {
        return BaseAppIdentity()
    }
    
    /**
     Returns the latest access token
     */
    public var accessToken:AccessToken? {
        return self.oAuthManager.tokenManager?.latestAccessToken
    }
    
    /**
     Returns the latest identity token
     */
    public var identityToken:IdentityToken? {
        return self.oAuthManager.tokenManager?.latestIdentityToken
    }
    
    /**
     Adds the cached authorization header to the given URL connection object.
     If the cached authorization header is equal to nil then this operation has no effect.
     - Parameter request - The request to add the header to.
     */
    
    public func addCachedAuthorizationHeader(_ request: NSMutableURLRequest) {
        AppIDAuthorizationManager.logger.debug(message: "addCachedAuthorizationHeader")
        addAuthorizationHeader(request, header: cachedAuthorizationHeader)
    }
    
    private func addAuthorizationHeader(_ request: NSMutableURLRequest, header:String?) {
        AppIDAuthorizationManager.logger.debug(message: "addAuthorizationHeader")
        guard let unWrappedHeader = header else {
            return
        }
        request.setValue(unWrappedHeader, forHTTPHeaderField: AppIDConstants.AUTHORIZATION_HEADER)
    }
    
    /**
     Removes saved tokens
     */
    public func logout() {
        self.clearAuthorizationData()
    }
    
    
    
    
    
}
