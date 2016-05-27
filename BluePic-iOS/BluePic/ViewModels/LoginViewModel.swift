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

enum LoginViewModelNotification {
    case LoginSuccess
    case LoginFailure
    case UserCanceledLogin
}

class LoginViewModel: NSObject {

    var notifyLoginVC : ((loginViewModelNotification: LoginViewModelNotification) -> ())!

    /**
     Method sets up the callback method to notify the login vc of login view model notifications

     - parameter notifyLoginVC: ((loginViewModelNotification : LoginViewModelNotification) -> ())

     - returns: LoginViewModel
     */
    init(notifyLoginVC: ((loginViewModelNotification: LoginViewModelNotification) -> ())) {
        super.init()

        self.notifyLoginVC = notifyLoginVC

    }

    /**
     Method informs the LoginDataManager that the user decided to login later
     */
    func loginLater() {
        LoginDataManager.SharedInstance.loginLater()
    }


    /**
     Method tells the LoginDataManager to begin the login process. We will eventually receieve the result of the login and we we handle errors or success by notifying the login vc appropriately.
     */
    func authenticateWithFacebook() {

        LoginDataManager.SharedInstance.login({ error in

            if error == nil {
                self.notifyLoginVC(loginViewModelNotification: LoginViewModelNotification.LoginSuccess)
            } else if error == LoginDataManagerError.UserCanceledLogin {
                self.notifyLoginVC(loginViewModelNotification: LoginViewModelNotification.UserCanceledLogin)
            } else {
                self.notifyLoginVC(loginViewModelNotification: LoginViewModelNotification.LoginFailure)
            }

        })
    }

}
