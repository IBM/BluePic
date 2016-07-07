/*
 *     Copyright 2015 IBM Corp.
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
import Foundation
import BMSCore
import BMSAnalyticsAPI

public class MCAAuthorizationManager : AuthorizationManager {
    
    /// Default scheme to use (default is https)
    public static var defaultProtocol: String = HTTPS_SCHEME
    public static let HTTP_SCHEME = "http"
    public static let HTTPS_SCHEME = "https"
    
    public static let CONTENT_TYPE = "Content-Type"
    
    private static let logger =  Logger.logger(forName: Logger.bmsLoggerPrefix + "MCAAuthorizationManager")
    
    internal var preferences:AuthorizationManagerPreferences
    
    //lock constant
    private var lockQueue = dispatch_queue_create("MCAAuthorizationManagerQueue", DISPATCH_QUEUE_CONCURRENT)
    
    private var challengeHandlers:[String:ChallengeHandler]
    
    /**
     - returns: The singelton instance
     */
    public static let sharedInstance = MCAAuthorizationManager()
    
    var processManager : AuthorizationProcessManager
    
    /**
     - returns: The locally stored authorization header or nil if the value does not exist.
     */
    public var cachedAuthorizationHeader:String? {
        get{
            var returnedValue:String? = nil
            dispatch_barrier_sync(lockQueue){
                if let accessToken = self.preferences.accessToken.get(), idToken = self.preferences.idToken.get() {
                    returnedValue = "\(BMSSecurityConstants.BEARER) \(accessToken) \(idToken)"
                }
            }
            return returnedValue
        }
    }
    
    /**
     - returns: User identity
     */
    public var userIdentity:UserIdentity? {
        get{
            let userIdentityJson = preferences.userIdentity.getAsMap()
            return MCAUserIdentity(map: userIdentityJson)
        }
    }
    
    /**
     - returns: Device identity
     */
    public var deviceIdentity:DeviceIdentity {
        get{
            let deviceIdentityJson = preferences.deviceIdentity.getAsMap()
            return MCADeviceIdentity(map: deviceIdentityJson)
        }
    }
    
    /**
     - returns: Application identity
     */
    public var appIdentity:AppIdentity {
        get{
            let appIdentityJson = preferences.appIdentity.getAsMap()
            return MCAAppIdentity(map: appIdentityJson)
        }
    }
    
    private init() {
        self.preferences = AuthorizationManagerPreferences()
        processManager = AuthorizationProcessManager(preferences: preferences)
        self.challengeHandlers = [String:ChallengeHandler]()
        
        challengeHandlers = [String:ChallengeHandler]()
        
        if preferences.deviceIdentity.get() == nil {
            preferences.deviceIdentity.set(MCADeviceIdentity().jsonData)
        }
        if preferences.appIdentity.get() == nil {
            preferences.appIdentity.set(MCAAppIdentity().jsonData)
        }
    }
    
    /**
     A response is an OAuth error response only if,
     1. it's status is 401 or 403.
     2. The value of the "WWW-Authenticate" header contains 'Bearer'.
     
     - Parameter httpResponse - Response to check the authorization conditions for.
     
     - returns: True if the response satisfies both conditions
     */
    
    public func isAuthorizationRequired(forHttpResponse httpResponse: Response) -> Bool {
        if let header = httpResponse.headers![caseInsensitive : BMSSecurityConstants.WWW_AUTHENTICATE_HEADER], authHeader : String = header as? String {
            guard let statusCode = httpResponse.statusCode else {
                return false
            }
            return isAuthorizationRequired(forStatusCode: statusCode, httpResponseAuthorizationHeader: authHeader)
        }
        
        return false
    }
    
    /**
     Check if the params came from response that requires authorization
     
     - Parameter statusCode - Status code of the response
     - Parameter responseAuthorizationHeader - Response header
     
     - returns: True if status is 401 or 403 and The value of the header contains 'Bearer'
     */
    
    public func isAuthorizationRequired(forStatusCode statusCode: Int, httpResponseAuthorizationHeader responseAuthorizationHeader: String) -> Bool {
        
        if (statusCode == 401 || statusCode == 403) && responseAuthorizationHeader.lowercaseString.containsString(BMSSecurityConstants.BEARER.lowercaseString){
            return true
        }
        
        return false
    }
    
    private func clearSessionCookie() {
        let cookiesStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = cookiesStorage.cookies {
            let jSessionCookies = cookies.filter() {$0.name == "JSESSIONID"}
            for cookie in jSessionCookies {
                cookiesStorage.deleteCookie(cookie)
            }
        }
    }
    
    /**
     Clear the local stored authorization data
     */
    
    public func clearAuthorizationData() {
        preferences.userIdentity.clear()
        preferences.idToken.clear()
        preferences.accessToken.clear()
        processManager.authorizationFailureCount = 0
        clearSessionCookie()
    }
    
    /**
     Adds the cached authorization header to the given URL connection object.
     If the cached authorization header is equal to nil then this operation has no effect.
     - Parameter request - The request to add the header to.
     */
    
    public func addCachedAuthorizationHeader(request: NSMutableURLRequest) {
        addAuthorizationHeader(request, header: cachedAuthorizationHeader)
    }
    
    private func addAuthorizationHeader(request: NSMutableURLRequest, header:String?) {
        guard let unWrappedHeader = header else {
            return
        }
        request.setValue(unWrappedHeader, forHTTPHeaderField: BMSSecurityConstants.AUTHORIZATION_HEADER)
    }
    
    
    /**
     Invoke process for obtaining authorization header.
     */
    
    public func obtainAuthorization(completionHandler completionHandler: BmsCompletionHandler?) {
        dispatch_barrier_async(lockQueue){
            self.processManager.startAuthorizationProcess(completionHandler)
        }
    }
    
    
    /**
     Registers a delegate that will handle authentication for the specified realm.
     
     - Parameter delegate - The delegate that will handle authentication challenges
     - Parameter realm -  The realm name
     */
    public func registerAuthenticationDelegate(delegate: AuthenticationDelegate, realm: String) {
        guard !realm.isEmpty else {
            MCAAuthorizationManager.logger.error("The realm name can't be empty")
            return;
        }
        
        let handler = ChallengeHandler(realm: realm, authenticationDelegate: delegate)
        challengeHandlers[realm] = handler
    }
    
    /**
     Unregisters the authentication delegate for the specified realm.
     - Parameter realm - The realm name
     */
    
    public func unregisterAuthenticationDelegate(realm: String) {
        guard !realm.isEmpty else {
            return
        }
        
        challengeHandlers.removeValueForKey(realm)
    }
    
    /**
     Returns the current persistence policy
     - returns: The current persistence policy
     */
    
    public func authorizationPersistencePolicy() -> PersistencePolicy {
        return preferences.persistencePolicy.get()
    }
    
    /**
     Sets a persistence policy
     - parameter policy - The policy to be set
     */
    
    public func setAuthorizationPersistencePolicy(policy: PersistencePolicy) {
        
        if preferences.persistencePolicy.get() != policy {
            preferences.persistencePolicy.set(policy, shouldUpdateTokens: true);
        }
    }
    
    /**
     Returns a challenge handler for realm
     - parameter realm - The realm for which a challenge handler is required.
     
     - returns: Challenge handler for the input's realm.
     */
    
    public func challengeHandlerForRealm(realm:String) -> ChallengeHandler?{
        return challengeHandlers[realm]
    }
    
    /**
     Logs out user from MCA
     - parameter completionHandler - This is an optional parameter. A completion handler that the app is calling this function wants to be called.
     */
    
    public func logout(completionHandler: BmsCompletionHandler?){
        self.clearAuthorizationData()
        processManager.logout(completionHandler)
    }
    
    
}
