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

import BMSCore
import BMSAnalyticsAPI

internal class AuthorizationProcessManager {
    private var authorizationQueue:Queue<BmsCompletionHandler> = Queue<BmsCompletionHandler>()
    private var sessionId:String = ""
    private var preferences:AuthorizationManagerPreferences
    var completionHandler: BmsCompletionHandler?
    internal var authorizationFailureCount = 0
    internal static let logger = Logger.logger(forName: BMSSecurityConstants.authorizationProcessManagerLoggerName)
    
    
    internal init(preferences:AuthorizationManagerPreferences)
    {
        self.authorizationQueue = Queue<BmsCompletionHandler>()
        self.preferences = preferences
        self.preferences.persistencePolicy.set(PersistencePolicy.NEVER, shouldUpdateTokens: false);
        //generate new random session id
        sessionId = NSUUID().UUIDString
    }
    
    internal func startAuthorizationProcess(callback:BmsCompletionHandler?) {
        
        guard let unWrappedCallBack = callback else {
            self.handleAuthorizationFailure(AuthorizationProcessManagerError.CallBackFunctionIsNil)
            return
        }
        
        authorizationQueue.add(unWrappedCallBack)
        
        
        //start the authorization process only if this is the first time we ask for authorization
        if authorizationQueue.size == 1 {
            do {
                if preferences.clientId.get() == nil {
                    AuthorizationProcessManager.logger.info("starting registration process")
                    try invokeInstanceRegistrationRequest()
                } else {
                    AuthorizationProcessManager.logger.info("starting authorization process")
                    invokeAuthorizationRequest()
                }
            } catch {
                self.handleAuthorizationFailure(error)
            }
        } else {
            AuthorizationProcessManager.logger.info("authorization process already running, adding response listener to the queue");
            AuthorizationProcessManager.logger.debug("authorization process currently handling \(authorizationQueue.size) requests")
        }
    }
    
    private func invokeInstanceRegistrationRequest() throws {
        preferences.clientId.clear()
        SecurityUtils.deleteCertificateFromKeyChain(BMSSecurityConstants.certificateIdentifier)
        let options:RequestOptions = RequestOptions()
        options.parameters = try createRegistrationParams()
        options.headers = createRegistrationHeaders()
        options.requestMethod = HttpMethod.POST
        
        let callBack:BmsCompletionHandler = {(response: Response?, error: NSError?) in
            if error == nil {
                if let unWrappedResponse = response where unWrappedResponse.isSuccessful {
                    do {
                        try self.saveCertificateFromResponse(response)
                        self.invokeAuthorizationRequest()
                    } catch(let thrownError) {
                        self.handleAuthorizationFailure(thrownError)
                    }
                }
                else {
                    self.handleAuthorizationFailure(response, error: error)
                }
            } else {
                self.handleAuthorizationFailure(response, error: error)
            }
        }
        do {
            try authorizationRequestSend(BMSSecurityConstants.clientsInstanceEndPoint, options: options, completionHandler: callBack)
        } catch {
            self.handleAuthorizationFailure(error)
        }
    }
    
    private func createTokenRequestHeaders(grantCode:String) throws -> [String:String]{
        var payload = [String:String]()
        var headers = [String:String]()
        payload[BMSSecurityConstants.JSON_CODE_KEY] = grantCode
        do {
            let jws:String = try SecurityUtils.signCsr(payload, keyIds: (BMSSecurityConstants.publicKeyIdentifier, BMSSecurityConstants.privateKeyIdentifier), keySize: 512)
            headers = [String:String]()
            headers[BMSSecurityConstants.X_WL_AUTHENTICATE_HEADER_NAME] =  jws
            return headers
        } catch {
            throw AuthorizationProcessManagerError.FailedToCreateTokenRequestHeaders
        }
        
    }
    
    private func createTokenRequestParams(grantCode:String) throws -> [String:String] {
        guard let clientId = preferences.clientId.get() else {
            throw AuthorizationProcessManagerError.ClientIdIsNil
        }
        let params : [String : String] = [
            BMSSecurityConstants.JSON_CODE_KEY : grantCode,
            BMSSecurityConstants.client_id_String :  clientId,
            BMSSecurityConstants.JSON_GRANT_TYPE_KEY : BMSSecurityConstants.authorization_code_String,
            BMSSecurityConstants.JSON_REDIRECT_URI_KEY :BMSSecurityConstants.HTTP_LOCALHOST
        ]
        return params
        
    }
    
    private func createAuthorizationParams() throws -> [String:String]{
        guard let clientId = preferences.clientId.get() else {
            throw AuthorizationProcessManagerError.ClientIdIsNil
        }
        let params : [String:String] = [
            BMSSecurityConstants.JSON_RESPONSE_TYPE_KEY : BMSSecurityConstants.JSON_CODE_KEY,
            BMSSecurityConstants.client_id_String :  clientId,
            BMSSecurityConstants.JSON_REDIRECT_URI_KEY :  BMSSecurityConstants.HTTP_LOCALHOST
        ]
        return params
    }
    
    private func invokeAuthorizationRequest() {
        let options:RequestOptions = RequestOptions()
        
        do {
            options.parameters = try createAuthorizationParams()
            options.headers = [String:String]()
            addSessionIdHeader(&options.headers)
            options.requestMethod = HttpMethod.GET
            let callBack:BmsCompletionHandler = {(response: Response?, error: NSError?) in
                guard response?.statusCode != 400 else {
                    self.authorizationFailureCount+=1
                    if self.authorizationFailureCount < 2 {
                        SecurityUtils.clearDictValuesFromKeyChain(BMSSecurityConstants.AuthorizationKeyChainTagsDictionary)
                        self.preferences.clientId.clear()
                        self.startAuthorizationProcess(self.authorizationQueue.remove())
                    }
                    return
                }
                if error == nil {
                    if let unWrappedResponse = response {
                        do {
                            let location:String = try self.extractLocationHeader(unWrappedResponse)
                            let grantCode:String = try self.extractGrantCode(location)
                            self.invokeTokenRequest(grantCode)
                        } catch(let thrownError) {
                            self.handleAuthorizationFailure(thrownError)
                        }
                    }
                    else {
                        self.handleAuthorizationFailure(response, error: error)
                    }
                } else {
                    self.handleAuthorizationFailure(response, error: error)
                }
            }
            try authorizationRequestSend(BMSSecurityConstants.authorizationEndPoint, options: options,completionHandler: callBack)
            
        } catch {
            self.handleAuthorizationFailure(error)
        }
    }
    
    private func invokeTokenRequest(grantCode:String) {
        
        
        let options:RequestOptions  = RequestOptions()
        do {
            options.parameters = try createTokenRequestParams(grantCode)
            options.headers = try createTokenRequestHeaders(grantCode)
            addSessionIdHeader(&options.headers)
            options.requestMethod = HttpMethod.POST
            let callback:BmsCompletionHandler = {(response: Response?, error: NSError?) in
                if error == nil {
                    if let unWrappedResponse = response where unWrappedResponse.isSuccessful {
                        do {
                            try self.saveTokenFromResponse(unWrappedResponse)
                            self.handleAuthorizationSuccess(unWrappedResponse, error: error)
                        } catch(let thrownError) {
                            self.handleAuthorizationFailure(thrownError)
                        }
                    }
                    else {
                        self.handleAuthorizationFailure(response, error: error)
                    }
                } else {
                    self.handleAuthorizationFailure(response, error: error)
                }
            }
            try authorizationRequestSend(BMSSecurityConstants.tokenEndPoint, options: options, completionHandler: callback)
        } catch {
            self.handleAuthorizationFailure(error)
        }
    }
    
    private func authorizationRequestSend(path:String, options:RequestOptions, completionHandler: BmsCompletionHandler?)  throws {
        
        do {
            let authorizationRequestManager:AuthorizationRequestManager = AuthorizationRequestManager(completionHandler: completionHandler)
            try  authorizationRequestManager.send(path, options: options )
        } catch  {
            throw AuthorizationProcessManagerError.FailedToSendAuthorizationRequest
        }
    }
    
    private func saveTokenFromResponse(response:Response) throws {
        do {
            if let data = response.responseData, responseJson =  try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]{
                if let accessTokenFromResponse = responseJson[caseInsensitive : BMSSecurityConstants.JSON_ACCESS_TOKEN_KEY] as? String, idTokenFromResponse =
                    responseJson[caseInsensitive : BMSSecurityConstants.JSON_ID_TOKEN_KEY] as? String {
                    //save the tokens
                    preferences.idToken.set(idTokenFromResponse)
                    preferences.accessToken.set(accessTokenFromResponse)
                    AuthorizationProcessManager.logger.debug("token successfully saved")
                    if let userIdentity = getUserIdentityFromToken(idTokenFromResponse)
                    {
                        preferences.userIdentity.set(userIdentity)
                    }
                }
            }
        } catch  {
            throw AuthorizationProcessManagerError.COULD_NOT_SAVE_TOKEN(("\(error)"))
        }
    }
    private func getUserIdentityFromToken(idToken:String) -> [String:AnyObject]?
    {
        do {
            if let decodedIdTokenData = Utils.decodeBase64WithString(idToken.componentsSeparatedByString(".")[1]), let _ = NSString(data: decodedIdTokenData, encoding: NSUTF8StringEncoding), decodedIdTokenString = String(data: decodedIdTokenData, encoding: NSUTF8StringEncoding), userIdentity = try Utils.parseJsonStringtoDictionary(decodedIdTokenString)[caseInsensitive : BMSSecurityConstants.JSON_IMF_USER_KEY] as? [String:AnyObject] {
                return userIdentity
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func createRegistrationParams() throws -> [String:String]{
        do {
            var params = [String:String]()
            try SecurityUtils.generateKeyPair(512, publicTag: BMSSecurityConstants.publicKeyIdentifier, privateTag: BMSSecurityConstants.privateKeyIdentifier)
            let csrValue:String = try SecurityUtils.signCsr(BMSSecurityConstants.deviceInfo, keyIds: (BMSSecurityConstants.publicKeyIdentifier, BMSSecurityConstants.privateKeyIdentifier), keySize: 512)
            params[BMSSecurityConstants.JSON_CSR_KEY] = csrValue
            return params
        } catch {
            throw AuthorizationProcessManagerError.FailedToCreateRegistrationParams
        }
    }
    
    private func createRegistrationHeaders() -> [String:String]{
        var headers = [String:String]()
        addSessionIdHeader(&headers)
        
        return headers
    }
    
    private func extractLocationHeader(response:Response) throws -> String {
        if let location = response.headers?[caseInsensitive : BMSSecurityConstants.LOCATION_HEADER_NAME], stringLocation = location as? String {
            AuthorizationProcessManager.logger.debug("Location header extracted successfully")
            return stringLocation
        } else {
            throw AuthorizationProcessManagerError.CouldNotExtractLocationHeader
        }
    }
    
    
    private func extractGrantCode(urlString:String) throws -> String{
        
        if let url:NSURL = NSURL(string: urlString), code = Utils.getParameterValueFromQuery(url.query, paramName: BMSSecurityConstants.JSON_CODE_KEY, caseSensitive: false)  {
            AuthorizationProcessManager.logger.debug("Grant code extracted successfully")
            return code
        } else {
            throw AuthorizationProcessManagerError.CouldNotExtractGrantCode
        }
    }
    
    private func saveCertificateFromResponse(response:Response?) throws {
        guard let responseBody:String? = response?.responseText, data = responseBody?.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw JsonUtilsErrors.JsonIsMalformed
        }
        do {
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject], certificateString = jsonResponse[caseInsensitive : BMSSecurityConstants.JSON_CERTIFICATE_KEY] as? String {
                //handle certificate
                let certificate =  try SecurityUtils.getCertificateFromString(certificateString)
                try  SecurityUtils.checkCertificatePublicKeyValidity(certificate, publicKeyTag: BMSSecurityConstants.publicKeyIdentifier)
                try SecurityUtils.saveCertificateToKeyChain(certificate, certificateLabel: BMSSecurityConstants.certificateIdentifier)
                
                //save the clientId separately
                if let id = jsonResponse[caseInsensitive : BMSSecurityConstants.JSON_CLIENT_ID_KEY] as? String? {
                    preferences.clientId.set(id)
                } else {
                    throw AuthorizationProcessManagerError.CertificateDoesNotIncludeClientId                     }
            }else {
                throw AuthorizationProcessManagerError.ResponseDoesNotIncludeCertificate
            }
        }
        AuthorizationProcessManager.logger.debug("certificate successfully saved")
    }
    private func addSessionIdHeader(inout headers:[String:String]) {
        headers[BMSSecurityConstants.X_WL_SESSION_HEADER_NAME] =  self.sessionId
    }
    private func handleAuthorizationSuccess(response: Response, error: NSError?) {
        while !self.authorizationQueue.isEmpty() {
            if let next:BmsCompletionHandler = authorizationQueue.remove() {
                next(response, error)
            }
        }
    }
    
    private func handleAuthorizationFailure(error: ErrorType) {
        self.handleAuthorizationFailure(nil, error: NSError(domain: BMSSecurityConstants.BMSSecurityErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"\(error)"]))
    }
    
    private func handleAuthorizationFailure(response: Response?,  error: NSError?)
    {
        AuthorizationProcessManager.logger.error("Authorization process failed")
        if let unwrappedError = error {
            AuthorizationProcessManager.logger.error(unwrappedError.debugDescription)
        }
        while !self.authorizationQueue.isEmpty() {
            if let next:BmsCompletionHandler = authorizationQueue.remove() {
                next(response, error)
            }
        }
        
    }
    internal func logout(completionHandler: BmsCompletionHandler?) {
        
        let options:RequestOptions  = RequestOptions()
        guard let clientId = preferences.clientId.get() else {
            AuthorizationProcessManager.logger.info("Could not log out because client id is nil. Device is either not registered or client id has been deleted.")
            if let unWrappedCompletionHandler = completionHandler {
                unWrappedCompletionHandler(nil, NSError(domain: BMSSecurityConstants.BMSSecurityErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not log out because client id is nil. Device is either not registered or client id has been deleted."]))
            }
            return
        }
        options.headers = [String:String]()
        self.addSessionIdHeader(&options.headers)
        options.parameters = [BMSSecurityConstants.client_id_String :  clientId]
        options.requestMethod = HttpMethod.GET
        do {
            try authorizationRequestSend("logout", options:options, completionHandler: completionHandler)
        } catch {
            AuthorizationProcessManager.logger.info("Could not log out")
            if let unWrappedCompletionHandler = completionHandler {
                unWrappedCompletionHandler(nil, NSError(domain: BMSSecurityConstants.BMSSecurityErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not log out."]))
            }
        }
        
    }
}