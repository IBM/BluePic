/**
 * Copyright IBM Corporation 2016
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

    //Error when the Authentiction header is not found
    case AuthenticationHeaderNotFound

    //Error when the facebook user id is not found
    case FacebookUserIdNotFound

    //Error when the facebook user identity is not found
    case FacebookuserIdentifyNotFound

    //Error when user canceled login
    case UserCanceledLogin

}

/// Manages all facebook authentication state and calls
class FacebookDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: FacebookDataManager = {

        var manager = FacebookDataManager()

        return manager

    }()

    /**
     Method prevents others from using the default '()' initializer for this class.

     - returns:
     */
    private override init() {}


    /**
     Method will authenticate used with Facebook if the app has Facebook configured in the plist. It will return the facebook user id and facebook user full name if authentication was a success, else it will return a FacebookAuthenticationError.

     - parameter callback: ((facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ())
     */
    func loginWithFacebook(callback : ((facebookUserId: String?, facebookUserFullName: String?, error: FacebookAuthenticationError?) -> ())) {

        if isFacebookConfigured() {
            authenticateFacebookUser(callback)

        }
    }

    /**
     Method to check if Facebook SDK is setup on native iOS side and that all required keys have been added to the plist

     - returns: true if configured, false if not
     */
    private func isFacebookConfigured() -> Bool {

        guard let facebookAppID = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookAppID") as? NSString,
            facebookDisplayName = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookDisplayName") as? NSString,
            urlTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as? NSArray,
            firstUrlType = urlTypes.firstObject as? NSDictionary,
            urlSchemes = firstUrlType["CFBundleURLSchemes"] as? NSArray,
            facebookURLScheme = urlSchemes.firstObject as? NSString else {

            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        if facebookAppID.isEqualToString("") || facebookAppID == "123456789" {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }
        if facebookDisplayName.isEqualToString("") {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        if facebookURLScheme.isEqualToString("") || facebookURLScheme.isEqualToString("fb123456789") || !(facebookURLScheme.hasPrefix("fb")) {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        //success if made it past this point
        return true
    }

    /**
     Method authenticates user with facebook and returns the facebook user id and facebook user full name if authentication was a success, else it will return a FacebookAuthenticationError.

     - parameter callback: ((facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ())
     */
    private func authenticateFacebookUser(callback : ((facebookUserId: String?, facebookUserFullName: String?, error: FacebookAuthenticationError?) -> ())) {

        let authManager = BMSClient.sharedInstance.authorizationManager
        authManager.obtainAuthorization(completionHandler: {(response: Response?, error: NSError?) in

            //error
            if let errorObject = error {
                //user canceled login
                if errorObject.code == -1 {
                    print(NSLocalizedString("Authenticate Facebook User Error: User Canceled login:", comment: "") + " \(errorObject.localizedDescription)")
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.UserCanceledLogin)
                } else {
                    print(NSLocalizedString("Authenticate Facebook User Error: Error obtaining Authentication Header.", comment: "") + " \(errorObject.localizedDescription)")
                    //"Error obtaining Authentication Header.\nCheck Bundle Identifier and Bundle version string\n\n"
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.AuthenticationHeaderNotFound)
                }
            }
            //error is nil
            else {
                if let identity = authManager.userIdentity {
                    if let userId = identity.id {
                        if let fullName = identity.displayName {
                            //success!
                            callback(facebookUserId: userId, facebookUserFullName: fullName, error: nil)
                        }
                    }
                    //error
                    else {
                        print(NSLocalizedString("Authenticate Facebook User Error: Valid Authentication Header and userIdentity, but id not found", comment: ""))
                        callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.FacebookUserIdNotFound)
                    }

                }
                //error
                else {
                    print(NSLocalizedString("Authenticate Facebook User Error: Valid Authentication Header, but userIdentity not found. You have to configure the Facebook Mobile Client Access service available on Bluemix", comment: ""))
                    callback(facebookUserId: nil, facebookUserFullName: nil, error: FacebookAuthenticationError.FacebookuserIdentifyNotFound)
                }
            }

        })
    }
}
