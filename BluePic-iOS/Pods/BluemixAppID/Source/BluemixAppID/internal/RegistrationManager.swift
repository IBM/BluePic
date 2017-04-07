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
internal class RegistrationManager {
    private var appId:AppID
    internal var preferenceManager:PreferenceManager
    
    internal static let logger = Logger.logger(name: AppIDConstants.RegistrationManagerLoggerName)
    
    
    internal init(oauthManager:OAuthManager)
    {
        self.appId = oauthManager.appId
        self.preferenceManager = oauthManager.preferenceManager
    }
    
    
    public func ensureRegistered(callback : @escaping (AppIDError?) -> Void) {
        let storedClientId:String? = self.getRegistrationDataString(name: AppIDConstants.client_id_String)
        let storedTenantId:String? = self.preferenceManager.getStringPreference(name: AppIDConstants.tenantPrefName).get()
        if(storedClientId != nil && self.appId.tenantId == storedTenantId) {
            RegistrationManager.logger.debug(message: "OAuth client is already registered.")
            callback(nil)
        } else {
            RegistrationManager.logger.info(message: "Registering a new OAuth client")
            self.registerOAuthClient(callback: {(error: Error?) in
                guard error == nil else {
                    RegistrationManager.logger.error(message: "Failed to register OAuth client")
                    callback(AppIDError.registrationError(msg: "Failed to register OAuth client"))
                    return
                }
                
                RegistrationManager.logger.info(message: "OAuth client successfully registered.")
                callback(nil)
            })
        }
        
    }
    
    internal func registerOAuthClient(callback :@escaping (Error?) -> Void) {
        guard let registrationParams = try? createRegistrationParams() else {
            callback(AppIDError.registrationError(msg: "Could not create registration params"))
            return
        }
        let internalCallBack:BMSCompletionHandler = {(response: Response?, error: Error?) in
            if error == nil {
                if let unWrappedResponse = response, unWrappedResponse.isSuccessful, let responseText = unWrappedResponse.responseText {
                    self.preferenceManager.getJSONPreference(name: AppIDConstants.registrationDataPref).set(try? Utils.parseJsonStringtoDictionary(responseText))
                    self.preferenceManager.getStringPreference(name: AppIDConstants.tenantPrefName).set(self.appId.tenantId)
                    callback(nil)
                } else {
                    callback(AppIDError.registrationError(msg: "Could not register client"))
                }
            } else {
                callback(error)
            }
        }
        
        let request:Request = Request(url: Config.getServerUrl(appId: self.appId) + "/clients",method: HttpMethod.POST, headers: [Request.contentType : "application/json"], queryParameters: nil, timeout: 0)
        request.timeout = BMSClient.sharedInstance.requestTimeout
        let registrationParamsAsData = try? Utils.urlEncode(Utils.JSONStringify(registrationParams as AnyObject)).data(using: .utf8) ?? Data()
        sendRequest(request: request, registrationParamsAsData: registrationParamsAsData, internalCallBack: internalCallBack)
       
    }
    
    
    internal func sendRequest(request:Request, registrationParamsAsData:Data?, internalCallBack: @escaping BMSCompletionHandler) {
        request.urlSession.isBMSAuthorizationRequest = true
        request.send(requestBody: registrationParamsAsData, completionHandler: internalCallBack)
    }
    
    internal func generateKeyPair() throws {
        try SecurityUtils.generateKeyPair(512, publicTag: AppIDConstants.publicKeyIdentifier, privateTag: AppIDConstants.privateKeyIdentifier)
    }
    
    
    private func createRegistrationParams() throws -> [String:Any] {
        do {
            try generateKeyPair()
            let deviceIdentity = BaseDeviceIdentity()
            let appIdentity = BaseAppIdentity()
            var params = [String:Any]()
            params[AppIDConstants.JSON_REDIRECT_URIS_KEY] = [AppIDConstants.REDIRECT_URI_VALUE]
            params[AppIDConstants.JSON_TOKEN_ENDPOINT_AUTH_METHOD_KEY] = AppIDConstants.CLIENT_SECRET_BASIC
            params[AppIDConstants.JSON_RESPONSE_TYPES_KEY] =  [AppIDConstants.JSON_CODE_KEY]
            params[AppIDConstants.JSON_GRANT_TYPES_KEY] = [AppIDConstants.authorization_code_String, AppIDConstants.PASSWORD_STRING]
            params[AppIDConstants.JSON_CLIENT_NAME_KEY] = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            params[AppIDConstants.JSON_SOFTWARE_ID_KEY] =  appIdentity.ID
            params[AppIDConstants.JSON_SOFTWARE_VERSION_KEY] =  appIdentity.version
            params[AppIDConstants.JSON_DEVICE_ID_KEY] = deviceIdentity.ID
            params[AppIDConstants.JSON_MODEL_KEY] = deviceIdentity.model
            params[AppIDConstants.JSON_OS_KEY] = deviceIdentity.OS
            
            params[AppIDConstants.JSON_CLIENT_TYPE_KEY] = AppIDConstants.MOBILE_APP_TYPE
            
            let jwks : [[String:Any]] = [try SecurityUtils.getJWKSHeader()]
            
            let keys = [
                AppIDConstants.JSON_KEYS_KEY : jwks
            ]
            
            params[AppIDConstants.JSON_JWKS_KEY] =  keys
            return params
        } catch {
            throw AppIDError.registrationError(msg: "Failed to create registration params")
        }
    }
    
    
    public func getRegistrationData() -> [String:Any]? {
        return self.preferenceManager.getJSONPreference(name: AppIDConstants.registrationDataPref).getAsJSON()
    }
    
    public func getRegistrationDataString(name:String) -> String? {
        guard let registrationData = self.getRegistrationData() else {
            return nil
        }
        return registrationData[name] as? String
    }
    
    public func getRegistrationDataString(arrayName:String, arrayIndex:Int) -> String? {
        guard let registrationData = self.getRegistrationData() else {
            return nil
        }
        return (registrationData[arrayName] as? NSArray)?[arrayIndex] as? String
    }
    
    
    public func getRegistrationDataObject(name:String) -> [String:Any]? {
        guard let registrationData = self.getRegistrationData() else {
            return nil
        }
        return registrationData[name] as? [String:Any]
    }
    public func getRegistrationDataArray(name:String) -> NSArray? {
        guard let registrationData = self.getRegistrationData() else {
            return nil
        }
        return registrationData[name] as? NSArray
    }
    
    
    public func clearRegistrationData() {
        self.preferenceManager.getStringPreference(name: AppIDConstants.tenantPrefName).clear()
        self.preferenceManager.getJSONPreference(name: AppIDConstants.registrationDataPref).clear()
        
    }
    
    
}
