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
import BluemixAppID
import BMSCore

enum LoginViewModelNotification {
    case loginSuccess
    case loginFailure
    case userCanceledLogin
}

class LoginViewModel: NSObject, AuthorizationDelegate {

    var notifyLoginVC : ((_ loginViewModelNotification: LoginViewModelNotification) -> Void)!

    /**
     Method sets up the callback method to notify the login vc of login view model notifications

     - parameter notifyLoginVC: ((loginViewModelNotification : LoginViewModelNotification) -> ())

     - returns: LoginViewModel
     */
    init(notifyLoginVC: @escaping (_ loginViewModelNotification: LoginViewModelNotification) -> Void) {
        super.init()

        self.notifyLoginVC = notifyLoginVC

    }

    /**
     Method informs the LoginDataManager that the user decided to login later
     */
    func loginLater() {
        LoginDataManager.SharedInstance.loginLater()
    }

    // MARK: AuthorizationDelegate methods

    public func onAuthorizationSuccess(accessToken: AccessToken, identityToken: IdentityToken, response: Response?) {
        if let identities = identityToken.identities, let fullName = identityToken.name {

            // Determine if we have facebook identity information
            var facebookUserId: String?
            _ = identities.filter { dictionary in
                if let provider = dictionary["provider"] as? String, provider == "facebook" {
                    facebookUserId = dictionary["id"] as? String
                    return true
                }
                return false
            }

            guard let userId = facebookUserId else {
                print("Failed to attain user's Facebook information.")
                self.notifyLoginVC(LoginViewModelNotification.loginFailure)
                return
            }

            print("Success: \(accessToken)")
            CurrentUser.willLoginLater = false
            CurrentUser.facebookUserId = userId
            CurrentUser.fullName = fullName
            self.notifyLoginVC(LoginViewModelNotification.loginSuccess)
        } else {
            print("Failed to attain user's Facebook information.")
            self.notifyLoginVC(LoginViewModelNotification.loginFailure)
        }
    }

    public func onAuthorizationCanceled() {
        print("Login cancelled")
        self.notifyLoginVC(LoginViewModelNotification.userCanceledLogin)
    }

    public func onAuthorizationFailure(error: AuthorizationError) {
        print("Auth Error: \(error)")
        self.notifyLoginVC(LoginViewModelNotification.loginFailure)
    }

}
