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
public class AuthorizationManager {

    static var logger = Logger.logger(name: AppIDConstants.RegistrationManagerLoggerName)
    var registrationManager:RegistrationManager
    var appid:AppID
    var oAuthManager:OAuthManager
    var authorizationUIManager:AuthorizationUIManager?
    init(oAuthManager:OAuthManager) {
        self.oAuthManager = oAuthManager
        self.appid = oAuthManager.appId
        self.registrationManager = oAuthManager.registrationManager!
    }

    internal func getAuthorizationUrl(idpName:String?, accessToken : String?) -> String {
        var url = Config.getServerUrl(appId: self.appid) + AppIDConstants.OAUTH_AUTHORIZATION_PATH + "?" + AppIDConstants.JSON_RESPONSE_TYPE_KEY + "=" + AppIDConstants.JSON_CODE_KEY
        if let clientId = self.registrationManager.getRegistrationDataString(name: AppIDConstants.client_id_String) {
            url += "&" + AppIDConstants.client_id_String + "=" + clientId
        }
        if let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0) {
            url +=  "&" + AppIDConstants.JSON_REDIRECT_URI_KEY + "=" + redirectUri
        }
        url += "&" + AppIDConstants.JSON_SCOPE_KEY + "=" + AppIDConstants.OPEN_ID_VALUE
        if let unWrappedIdpName = idpName {
            url += "&idp=" + unWrappedIdpName
        }
        if let unWrappedAccessToken = accessToken {
            url += "&appid_access_token=" + unWrappedAccessToken
        }
        return url
    }

    internal func launchAuthorizationUI(accessTokenString:String? = nil, authorizationDelegate:AuthorizationDelegate) {

        self.registrationManager.ensureRegistered(callback: {(error:AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }
            let authorizationUrl = self.getAuthorizationUrl(idpName: nil, accessToken:accessTokenString)
            let redirectUri = self.registrationManager.getRegistrationDataString(arrayName: AppIDConstants.JSON_REDIRECT_URIS_KEY, arrayIndex: 0)
            self.authorizationUIManager = AuthorizationUIManager(oAuthManager: self.oAuthManager, authorizationDelegate: authorizationDelegate, authorizationUrl: authorizationUrl, redirectUri: redirectUri!)
            self.authorizationUIManager?.launch()

        })
    }


    internal func loginAnonymously(accessTokenString:String?, allowCreateNewAnonymousUsers: Bool, authorizationDelegate:AuthorizationDelegate) {
        self.registrationManager.ensureRegistered(callback: {(error:AppIDError?) in
            guard error == nil else {
                AuthorizationManager.logger.error(message: error!.description)
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(error!.description))
                return
            }

            let accessTokenToUse = accessTokenString != nil ? accessTokenString : self.oAuthManager.tokenManager?.latestAccessToken?.raw

            if accessTokenToUse == nil && !allowCreateNewAnonymousUsers {
                authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Not allowed to create new anonymous users"))
                return
            }

            let authorizationUrl = self.getAuthorizationUrl(idpName: AppIDConstants.AnonymousIdpName, accessToken:accessTokenToUse)

            let internalCallback:BMSCompletionHandler = {(response: Response?, error: Error?) in
                if error == nil {
                    if let unWrapperResponse = response {
                        let urlString = self.extractUrlString(body : unWrapperResponse.responseText)
                        if urlString != nil {
                            let url = URL(string: urlString!)

                            if url != nil {

                                if let err = Utils.getParamFromQuery(url: url!, paramName: "error") {
                                    // authorization endpoint returned error
                                    let errorDescription = Utils.getParamFromQuery(url: url!, paramName: "error_description")
                                    let errorCode = Utils.getParamFromQuery(url: url!, paramName: "error_code")
                                    AuthorizationManager.logger.error(message: "error: " + err)
                                    AuthorizationManager.logger.error(message: "errorCode: " + (errorCode ?? "not available"))
                                    AuthorizationManager.logger.error(message: "errorDescription: " + (errorDescription ?? "not available"))
                                    authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Failed to obtain access and identity tokens"))
                                    return

                                } else {
                                    // authorization endpoint success
                                    if urlString!.lowercased().hasPrefix(AppIDConstants.REDIRECT_URI_VALUE.lowercased()) == true {
                                        if let code =  Utils.getParamFromQuery(url: url!, paramName: AppIDConstants.JSON_CODE_KEY) {
                                            self.oAuthManager.tokenManager?.obtainTokens(code: code, authorizationDelegate: authorizationDelegate)
                                            return
                                        }
                                    }
                                }
                            }
                        }
                    }
                    self.logAndFail(message: "Failed to extract grant code", delegate: authorizationDelegate)
                } else {
                    self.logAndFail(message: "Unable to get response from server", delegate: authorizationDelegate)
                }
            }

            let request = Request(url: authorizationUrl,method: HttpMethod.GET, headers: nil, queryParameters: nil, timeout: 0)
            request.timeout = BMSClient.sharedInstance.requestTimeout
            request.allowRedirects = false
            self.sendRequest(request: request, internalCallBack: internalCallback)

        })

    }

    private func logAndFail(message : String, delegate: AuthorizationDelegate) {
        AuthorizationManager.logger.debug(message : message)
        delegate.onAuthorizationFailure( error: AuthorizationError.authorizationFailure(message))
    }

    private func extractUrlString(body: String?) -> String? {
        if let unWrappedBody = body {
            let r = unWrappedBody.range(of: AppIDConstants.REDIRECT_URI_VALUE)
            if r != nil {
                return unWrappedBody.substring(from: r!.lowerBound)

            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    internal func sendRequest(request:Request, internalCallBack: @escaping BMSCompletionHandler) {
        request.send(completionHandler: internalCallBack)
    }


    public func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return (self.authorizationUIManager?.application(application, open: url, options: options))!
    }




}
