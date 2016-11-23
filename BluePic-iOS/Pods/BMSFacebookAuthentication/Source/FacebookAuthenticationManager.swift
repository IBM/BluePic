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

#if swift(>=3.0)
@objc public class FacebookAuthenticationManager :NSObject,AuthenticationDelegate{
    
    private static let FACEBOOK_REALM="wl_facebookRealm";
    private static let ACCESS_TOKEN_KEY="accessToken";
    private static let FACEBOOK_APP_ID_KEY="facebookAppId";
    let login:FBSDKLoginManager = FBSDKLoginManager()
    
    static let logger = Logger.logger(name: "bmssdk.security.FacebookAuthenticationManager")
    
    public static let sharedInstance:FacebookAuthenticationManager = FacebookAuthenticationManager()
    
    private override init() {
        super.init()
    }
    /**
     register for facebook realm in the authoraztion manager
     */
    public func register() {
        MCAAuthorizationManager.sharedInstance.registerAuthenticationDelegate(self, realm: FacebookAuthenticationManager.FACEBOOK_REALM) //register the delegate for facebook realm
    }
    /**
     logs out of Facebook
     */
    public func logout(completionHandler: BMSCompletionHandler?){
        login.logOut()
        MCAAuthorizationManager.sharedInstance.logout(completionHandler)
    }
    
    public func onAuthenticationChallengeReceived(_ authContext : AuthenticationContext, challenge : AnyObject) {
        //Make sure the user put Facebook appid in the plist
        guard Bundle.main.infoDictionary?["FacebookAppID"] != nil else{
            authContext.submitAuthenticationFailure(["Error":"Please Put your facebook appid in your info.plist" as AnyObject])
            return
        }
        //make sure the challange appId is the same as plist appId
        guard let appID = challenge[FacebookAuthenticationManager.FACEBOOK_APP_ID_KEY] as? String, appID == FBSDKLoginKit.FBSDKSettings.appID()
            else{
                authContext.submitAuthenticationFailure(["Error":"App Id from MCA server doesn't match the one defined in the .plist file" as AnyObject])
                return
        }
        
        //Facebook showing popup so it need to run on main thread
        DispatchQueue.main.async {
            
            let handler:FBSDKLoginManagerRequestTokenHandler = {(result:FBSDKLoginManagerLoginResult?, error:Error?) -> Void in
                guard error == nil else {
                    authContext.submitAuthenticationFailure(["Error":error as AnyObject])
                    return
                }
                
                if (result?.isCancelled)! {
                    authContext.submitAuthenticationFailure(["Error":"The user canceled the operation" as AnyObject])
                }
                else{
                    let accessToken = FBSDKAccessToken.current().tokenString
                    authContext.submitAuthenticationChallengeAnswer([FacebookAuthenticationManager.ACCESS_TOKEN_KEY:accessToken! as AnyObject])
                }
                
            }
            
            self.login.logIn(withReadPermissions: ["public_profile"], from: nil, handler: handler)
        }
    }
    //MARK: Protocol implemantion
    
    public func onAuthenticationSuccess(_ info : AnyObject?) {
        FacebookAuthenticationManager.logger.debug(message: "onAuthenticationSuccess info = \(info)")
    }
    
    public func onAuthenticationFailure(_ info : AnyObject?) {
    }
    
    //MARK: App Delegate code handler
    /******    needed by facebook you need to call those methods from your app delegate *******/
    
    public func onOpenURL(application: UIApplication, url: URL,
                          sourceApplication: String?,annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,open: url,sourceApplication: sourceApplication,annotation: annotation)
    }
    
    public func onOpenURL(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(
            app,
            open: url as URL!,
            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String,
            annotation: options[UIApplicationOpenURLOptionsKey.annotation]
        )
    }
    
    public func onFinishLaunching(application: UIApplication, withOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
    
}
#else
@objc public class FacebookAuthenticationManager :NSObject,AuthenticationDelegate{
    
    private static let FACEBOOK_REALM="wl_facebookRealm";
    private static let ACCESS_TOKEN_KEY="accessToken";
    private static let FACEBOOK_APP_ID_KEY="facebookAppId";
    let login:FBSDKLoginManager = FBSDKLoginManager()
    
    static let logger = Logger.logger(name: "bmssdk.security.FacebookAuthenticationManager")
    
    public static let sharedInstance:FacebookAuthenticationManager = FacebookAuthenticationManager()
    
    private override init() {
        super.init()
    }
    /**
     register for facebook realm in the authoraztion manager
     */
    public func register() {
        MCAAuthorizationManager.sharedInstance.registerAuthenticationDelegate(self, realm: FacebookAuthenticationManager.FACEBOOK_REALM) //register the delegate for facebook realm
    }
    /**
     logs out of Facebook
     */
    public func logout(completionHandler: BMSCompletionHandler?){
        login.logOut()
        MCAAuthorizationManager.sharedInstance.logout(completionHandler)
    }
    
    public func onAuthenticationChallengeReceived(authContext : AuthenticationContext, challenge : AnyObject) {
        //Make sure the user put Facebook appid in the plist
        guard NSBundle.mainBundle().infoDictionary?["FacebookAppID"] != nil else{
            authContext.submitAuthenticationFailure(["Error":"Please Put your facebook appid in your info.plist"])
            return
        }
        //make sure the challange appId is the same as plist appId
        guard let appID = challenge[FacebookAuthenticationManager.FACEBOOK_APP_ID_KEY] as? String where appID == FBSDKLoginKit.FBSDKSettings.appID()
            else{
                authContext.submitAuthenticationFailure(["Error":"App Id from MCA server doesn't match the one defined in the .plist file"])
                return
        }
        
        //Facebook showing popup so it need to run on main thread
        dispatch_async(dispatch_get_main_queue(), {
            self.login.logInWithReadPermissions(["public_profile"], fromViewController: nil,
                handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
                    guard error == nil else{
                        authContext.submitAuthenticationFailure(["Error":error])
                        return
                    }
                    
                    if result.isCancelled{
                        authContext.submitAuthenticationFailure(["Error":"The user canceled the operation"])
                    }
                    else{
                        let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                        authContext.submitAuthenticationChallengeAnswer([FacebookAuthenticationManager.ACCESS_TOKEN_KEY:accessToken])
                    }
                    
            })
        })
    }
    //MARK: Protocol implemantion
    
    public func onAuthenticationSuccess(info : AnyObject?) {
        FacebookAuthenticationManager.logger.debug(message: "onAuthenticationSuccess info = \(info)")
    }
    
    public func onAuthenticationFailure(info : AnyObject?) {
    }
    
    //MARK: App Delegate code handler
    /******    needed by facebook you need to call those methods from your app delegate *******/
    
    
    public func onOpenURL(application: UIApplication, url: NSURL,
                          sourceApplication: String?,annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,openURL: url,sourceApplication: sourceApplication,annotation: annotation)
    }
    
    public func onFinishLaunching(application: UIApplication, withOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
}
#endif
