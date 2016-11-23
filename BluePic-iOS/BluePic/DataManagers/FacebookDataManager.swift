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

enum FacebookAuthenticationError: String {

    //Error when the Authentiction header is not found
    case authenticationHeaderNotFound

    //Error when the facebook user id is not found
    case facebookUserIdNotFound

    //Error when the facebook user identity is not found
    case facebookuserIdentifyNotFound

    //Error when user canceled login
    case userCanceledLogin

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
    fileprivate override init() {}


    /**
     Method will authenticate used with Facebook if the app has Facebook configured in the plist. It will return the facebook user id and facebook user full name if authentication was a success, else it will return a FacebookAuthenticationError.

     - parameter callback: ((facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ())
     */
    func loginWithFacebook(_ callback : @escaping ((_ facebookUserId: String?, _ facebookUserFullName: String?, _ error: FacebookAuthenticationError?) -> ())) {

        if isFacebookConfigured() {
            authenticateFacebookUser(callback)

        }
    }

    /**
     Method to check if Facebook SDK is setup on native iOS side and that all required keys have been added to the plist

     - returns: true if configured, false if not
     */
    fileprivate func isFacebookConfigured() -> Bool {

        guard let facebookAppID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
            let facebookDisplayName = Bundle.main.object(forInfoDictionaryKey: "FacebookDisplayName") as? String,
            let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [Any],
            let firstUrlType = urlTypes.first as? [String : Any],
            let urlSchemes = firstUrlType["CFBundleURLSchemes"] as? [String],
            let facebookURLScheme = urlSchemes.first else {

            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        if facebookAppID == "" || facebookAppID == "123456789" {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }
        if facebookDisplayName == "" {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        if facebookURLScheme == "" || facebookURLScheme == "fb123456789" || !(facebookURLScheme.hasPrefix("fb")) {
            print(NSLocalizedString("Is Facebook Congigured Error: Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook", comment: ""))
            return false
        }

        //success if made it past this point
        return true
    }

    /**
     Method authenticates user with facebook and returns the facebook user id and facebook user full name if authentication was a success, else it will return a FacebookAuthenticationError.

     - parameter callback: (facebookUserId : String?, facebookUserFullName : String?, error : FacebookAuthenticationError?) -> ()
     */
    fileprivate func authenticateFacebookUser(_ callback : @escaping (_ facebookUserId: String?, _ facebookUserFullName: String?, _ error: FacebookAuthenticationError?) -> ()) {

        let authManager = BMSClient.sharedInstance.authorizationManager

        authManager.obtainAuthorization { response, error in

            if let error = error, let dictionary = Utils.convertStringToDictionary(error.localizedDescription), let errorMessage = dictionary["Error"] as? String {
                if errorMessage == FacebookAuthenticationError.userCanceledLogin.rawValue {
                    print(NSLocalizedString("Authenticate Facebook User Error: User Canceled login", comment: ""))
                    callback(nil, nil, FacebookAuthenticationError.userCanceledLogin)
                } else {
                    print(NSLocalizedString("Authenticate Facebook User Error: Error obtaining Authentication Header.", comment: "") + " \(error.localizedDescription)")
                    callback(nil, nil, FacebookAuthenticationError.authenticationHeaderNotFound)
                }
            }
            //error is nil
            else {
                if let identity = authManager.userIdentity {
                    if let userId = identity.ID {
                        if let fullName = identity.displayName {
                            //success!
                            callback(userId, fullName, nil)
                        }
                    }
                    //error
                    else {
                        print(NSLocalizedString("Authenticate Facebook User Error: Valid Authentication Header and userIdentity, but id not found", comment: ""))
                        callback(nil, nil, FacebookAuthenticationError.facebookUserIdNotFound)
                    }

                }
                //error
                else {
                    print(NSLocalizedString("Authenticate Facebook User Error: Valid Authentication Header, but userIdentity not found. You have to configure the Facebook Mobile Client Access service available on Bluemix", comment: ""))
                    callback(nil, nil, FacebookAuthenticationError.facebookuserIdentifyNotFound)
                }
            }

        }
    }


    /**
     Method logs out the user by calling the FacebookAuthenticationManager's logout method

     - parameter completionHandler: BMSCompletionHandler?
     */
    func logOut(_ completionHandler: BMSCompletionHandler?) {

        FacebookAuthenticationManager.sharedInstance.logout(completionHandler: completionHandler)

    }

    /**
     Method returns the Facebook user identity

     - returns: UserIdentity?
     */
    func getFacebookUserIdentity() -> UserIdentity? {

        let authManager = BMSClient.sharedInstance.authorizationManager

        return authManager.userIdentity

    }


}
