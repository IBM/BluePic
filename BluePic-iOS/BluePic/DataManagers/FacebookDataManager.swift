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

/// Manages all facebook authentication state and calls
class FacebookDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: FacebookDataManager = {

        var manager = FacebookDataManager()

        return manager

    }()

    /**
     Method prevents others from using the default '()' initializer for this class.
     */
    fileprivate override init() {}

    /**
     Method to check if Facebook credentials are setup on native iOS side and that all required keys have been added to the plist

     - returns: true if configured, false if not
     */
    internal func isFacebookConfigured() -> Bool {

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
     Method returns the Facebook user identity

     - returns: UserIdentity?
     */
    func getFacebookUserIdentity() -> UserIdentity? {

        let authManager = BMSClient.sharedInstance.authorizationManager

        return authManager.userIdentity

    }

}
