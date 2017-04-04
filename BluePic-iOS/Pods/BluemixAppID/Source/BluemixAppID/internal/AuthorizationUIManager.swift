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

public class AuthorizationUIManager {
    var oAuthManager:OAuthManager
    var authorizationDelegate:AuthorizationDelegate
    var authorizationUrl:String
    var redirectUri:String
    private static let logger =  Logger.logger(name: Logger.bmsLoggerPrefix + "AppIDAuthorizationUIManager")
    var loginView:safariView?
    init(oAuthManager: OAuthManager, authorizationDelegate: AuthorizationDelegate, authorizationUrl: String, redirectUri: String) {
        self.oAuthManager = oAuthManager
        self.authorizationDelegate = authorizationDelegate
        self.authorizationUrl = authorizationUrl
        self.redirectUri = redirectUri
    }
    
    public func launch() {
        AuthorizationUIManager.logger.debug(message: "Launching safari view")
        loginView =  safariView(url: URL(string: authorizationUrl )!)
        loginView?.authorizationDelegate = authorizationDelegate
        let mainView  = UIApplication.shared.keyWindow?.rootViewController
        DispatchQueue.main.async {
            mainView?.present(self.loginView!, animated: true, completion:  nil)
        }
    }
    
    public func application(_ application: UIApplication, open url: URL, options :[UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        
        func tokenRequest(code: String?, errMsg:String?) {
            loginView?.dismiss(animated: true, completion: { () -> Void in
                guard errMsg == nil else {
                    self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure(errMsg!))
                    return
                }
                guard let unwrappedCode = code else {
                    self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Failed to extract grant code"))
                    return
                }
                AuthorizationUIManager.logger.debug(message: "Obtaining tokens")
                
                self.oAuthManager.tokenManager?.obtainTokens(code: unwrappedCode, authorizationDelegate: self.authorizationDelegate)
            })
        }
        
        if let err = Utils.getParamFromQuery(url: url, paramName: "error") {
            loginView?.dismiss(animated: true, completion: { () -> Void in
                let errorDescription = Utils.getParamFromQuery(url: url, paramName: "error_description")
                let errorCode = Utils.getParamFromQuery(url: url, paramName: "error_code")
                AuthorizationUIManager.logger.error(message: "error: " + err)
                AuthorizationUIManager.logger.error(message: "errorCode: " + (errorCode ?? "not available"))
                AuthorizationUIManager.logger.error(message: "errorDescription: " + (errorDescription ?? "not available"))
                self.authorizationDelegate.onAuthorizationFailure(error: AuthorizationError.authorizationFailure("Failed to obtain access and identity tokens"))
            })
            return false
        } else {
            let urlString = url.absoluteString
            if urlString.lowercased().hasPrefix(AppIDConstants.REDIRECT_URI_VALUE.lowercased()) == true {
                // gets the query, then sepertes it to params, then filters the one the is "code" then takes its value
                if let code =  Utils.getParamFromQuery(url: url, paramName: AppIDConstants.JSON_CODE_KEY) {
                    tokenRequest(code: code, errMsg: nil)
                    return true
                } else {
                    AuthorizationUIManager.logger.debug(message: "Failed to extract grant code")
                    tokenRequest(code: nil, errMsg: "Failed to extract grant code")
                    return false
                }
            }
            return false
        }
        
    }
    
 
    
    
}
