/*
*     Copyright 2016 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http:www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/
//
//  FacebookAuthenticationManager.swift

//
//  Created by Asaf Manassen on 09/02/2016.
//  Copyright © 2016 Asaf Manassen. All rights reserved.
//

import Foundation
import BMSCore
import BMSSecurity
import FBSDKLoginKit
import BMSAnalyticsAPI

open class FacebookAuthenticationManager: NSObject, AuthenticationDelegate {

    fileprivate static let FACEBOOK_REALM="wl_facebookRealm"
    fileprivate static let ACCESS_TOKEN_KEY="accessToken"
    fileprivate static let FACEBOOK_APP_ID_KEY="facebookAppId"
    let login: FBSDKLoginManager = FBSDKLoginManager()

    static let logger = Logger.logger(name: "bmssdk.security.FacebookAuthenticationManager")

    open static let sharedInstance: FacebookAuthenticationManager = FacebookAuthenticationManager()

    fileprivate override init() {
        super.init()
    }
    /**
     register for facebook realm in the authoraztion manager
     */
    open func register() {
        MCAAuthorizationManager.sharedInstance.registerAuthenticationDelegate(self, realm: FacebookAuthenticationManager.FACEBOOK_REALM) //register the delegate for facebook realm
    }

    /**
     logs out of Facebook

     - parameter completionHandler: the network request completion handler
     */
    open func logout(_ completionHandler: BMSCompletionHandler?) {
        login.logOut()
        MCAAuthorizationManager.sharedInstance.logout(completionHandler)
    }

    open func onAuthenticationChallengeReceived(_ authContext: AuthenticationContext, challenge: AnyObject) {
        //Make sure the user put Facebook appid in the plist
        guard Bundle.main.infoDictionary?["FacebookAppID"] != nil else {
            authContext.submitAuthenticationFailure(["Error":"Please Put your facebook appid in your info.plist" as AnyObject])
            return
        }
        //make sure the challange appId is the same as plist appId
        guard let appID = challenge[FacebookAuthenticationManager.FACEBOOK_APP_ID_KEY] as? String, appID == FBSDKLoginKit.FBSDKSettings.appID()
            else {
                authContext.submitAuthenticationFailure(["Error":"App Id from MCA server doesn't match the one defined in the .plist file" as AnyObject])
                return
        }

        //Facebook showing popup so it need to run on main thread
        DispatchQueue.main.async(execute: {
            self.login.logIn(withReadPermissions: ["public_profile"], from: nil) { result, error in
                guard error == nil, let result = result else {
                    authContext.submitAuthenticationFailure(["Error": error as AnyObject])
                    return
                }

                if result.isCancelled {
                    authContext.submitAuthenticationFailure(["Error": FacebookAuthenticationError.userCanceledLogin as AnyObject])
                } else {
                    let accessToken = FBSDKAccessToken.current().tokenString
                    authContext.submitAuthenticationChallengeAnswer([FacebookAuthenticationManager.ACCESS_TOKEN_KEY: accessToken as AnyObject])
                }
            }
        })
    }

    // MARK: Protocol implemantion

    open func onAuthenticationSuccess(_ info: AnyObject?) {
        FacebookAuthenticationManager.logger.debug(message: "onAuthenticationSuccess info = \(info)")
    }

    open func onAuthenticationFailure(_ info: AnyObject?) {
    }

    // MARK: App Delegate code handler
    /******    needed by facebook you need to call those methods from your app delegate *******/


    open func onOpenURL(_ application: UIApplication, url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    open func onFinishLaunching(_ application: UIApplication, withOptions launchOptions: [AnyHashable: Any]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

    }

}
