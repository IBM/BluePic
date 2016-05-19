/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/


import UIKit
import BMSCore

enum FacebookAuthenticationError {
    case PlistNotConfigured
    case AuthenticationHeaderNotFound
    case FacebookUserIdNotFound
    case FacebookuserIdentifyNotFound
    case UserCanceledLogin
    
}


/// Manages all facebook authentication state and calls
class FacebookDataManager: NSObject {
    
    /// Shared instance of data manager
    static let SharedInstance: FacebookDataManager = {
        
        var manager = FacebookDataManager()
        
        
        return manager
        
    }()
    

    private override init() {} //This prevents others from using the default '()' initializer for this class.

    
    func loginWithFacebook(callback : ((facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ())){
        
        if(isFacebookConfigured()){
            authenticateFacebookUser(callback)
            
        }
    }
    
    
    /**
     Method to check if Facebook SDK is setup on native iOS side and all required keys have been added to plist
     
     - returns: true if configured, false if not
     */
    private func isFacebookConfigured() -> Bool {
        let facebookAppID = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookAppID") as? NSString
        let facebookDisplayName = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookDisplayName") as? NSString
        let urlTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as? NSArray
        
        let urlTypes0 = urlTypes!.firstObject as? NSDictionary
        let urlSchemes = urlTypes0!["CFBundleURLSchemes"] as? NSArray
        let facebookURLScheme = urlSchemes!.firstObject as? NSString
        
        if (facebookAppID == nil || facebookAppID!.isEqualToString("") || facebookAppID == "123456789") {
            print("Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook")
            return false
        }
        if (facebookDisplayName == nil || facebookDisplayName!.isEqualToString("")) {
            print("Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook")
            return false
        }
        
        if (facebookURLScheme == nil || facebookURLScheme!.isEqualToString("") || facebookURLScheme!.isEqualToString("fb123456789") || !(facebookURLScheme!.hasPrefix("fb"))) {
            print("Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook")
            return false
        }
        
        //success if made it past this point
        
        print("Facebook Auth configured, getting ready to show native FB Login:\nFacebookAppID \(facebookAppID!)\nFacebookDisplayName \(facebookDisplayName!)\nFacebookURLScheme \(facebookURLScheme!)")
        return true;
    }
    

    private func authenticateFacebookUser(callback : ((facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ())) {
        
        let authManager = BMSClient.sharedInstance.authorizationManager
        authManager
        authManager.obtainAuthorization(completionHandler: {(response: Response?, error: NSError?) in
            
            //error
            if let errorObject = error {
                //user canceled login
                if(errorObject.code == -1){
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.UserCanceledLogin)
                }
                else{
                    //"Error obtaining Authentication Header.\nCheck Bundle Identifier and Bundle version string\n\n"
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.AuthenticationHeaderNotFound)
                }
            }
                //no error
            else {
                if let identity = authManager.userIdentity {
                    if let userId = identity.id  {
                        if let fullName = identity.displayName {
                            //success!
                            callback(facebookUserId: userId, facebookUserFullName: fullName, error: nil)
                        }
                    }
                    else {
                        print("Valid Authentication Header and userIdentity, but id not found")
                        callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.FacebookUserIdNotFound)
                    }
                    
                }
                else {
                    print("Valid Authentication Header, but userIdentity not found. You have to configure one of the methods available in Advanced Mobile Service on Bluemix, such as Facebook")
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.FacebookuserIdentifyNotFound)
                }

            }
            
        })
        
    }

}


