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

class LoginDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: LoginDataManager = {

        var manager = LoginDataManager()

        return manager

    }()

    /**
     Method is called when the user presses the sign in later button. It will sets the CurrentUser object's willLoginLater property to true
     */
    func loginLater() {

        CurrentUser.willLoginLater = true
    }

    /**
     Method will return true if the user is already authenticated or has pressed sign in later

     - returns: Bool
     */
    func isUserAuthenticatedOrPressedSignInLater() -> Bool {
        if isUserAlreadyAuthenticated() || CurrentUser.willLoginLater {
            return true
        } else {
           return false
        }
    }

    /**
     Method returns true if the user has already authenticated with facebook

     - returns: Bool
     */
    func isUserAlreadyAuthenticated() -> Bool {
        if CurrentUser.facebookUserId != "anonymous" && CurrentUser.fullName != "anonymous" {
            return true
        } else {
            return false
        }
    }

    /**
     Method logs out the user and will return success of failure in the callback parameter

     - parameter callback: ((success: Bool)->())
     */
    func logOut() {

        BMSClient.sharedInstance.authorizationManager.clearAuthorizationData()
        CurrentUser.logOut()

    }

}
