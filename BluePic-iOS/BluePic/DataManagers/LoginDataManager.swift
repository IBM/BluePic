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

enum LoginDataManagerError {

    case FacebookAuthenticationError
    case UserCanceledLogin
    case ConnectionFailure

}

class LoginDataManager: NSObject {


    /// Shared instance of data manager
    static let SharedInstance: LoginDataManager = {

        var manager = LoginDataManager()

        return manager

    }()

    func login(callback : ((error: LoginDataManagerError?)->())) {

        ///Check if user is already authenticated from previous sesssions, aka check nsuserdefaults for user info
        if isUserAlreadyAuthenticated() {
            callback(error: nil)
        }
            //user not already authenticated from previous sessions
        else {

            //login with facebook
            FacebookDataManager.SharedInstance.loginWithFacebook({ (facebookUserId: String?, facebookUserFullName: String?, error: FacebookAuthenticationError?) in

                //facebook authentication failure
                if let error = error {

                    if error == FacebookAuthenticationError.UserCanceledLogin {
                        callback(error: LoginDataManagerError.UserCanceledLogin)
                    } else {
                        callback(error: LoginDataManagerError.FacebookAuthenticationError)
                    }

                }
                //facebook authentication success
                else {

                    //Check to make sure facebook id and name aren't nil
                    if let facebookUserId = facebookUserId, let facebookUserFullName = facebookUserFullName {

                        //try to register user with backend if the user doesn't already exist
                        BluemixDataManager.SharedInstance.checkIfUserAlreadyExistsIfNotCreateNewUser(facebookUserId, name: facebookUserFullName, callback: { success in

                            if success {
                                CurrentUser.willLoginLater = false
                                CurrentUser.facebookUserId = facebookUserId
                                CurrentUser.fullName = facebookUserFullName
                                callback(error: nil)
                            } else {
                                callback(error: LoginDataManagerError.ConnectionFailure )
                            }

                        })
                    }
                    //Facebook id and name were nil
                    else {
                        callback(error: LoginDataManagerError.FacebookAuthenticationError)
                    }
                }

            })

        }
    }


    func loginLater() {

        CurrentUser.willLoginLater = true

    }


    func isUserAuthenticatedOrPressedSignInLater() -> Bool {
        if isUserAlreadyAuthenticated() || CurrentUser.willLoginLater {
            return true
        } else {
           return false
        }
    }


    private func isUserAlreadyAuthenticated() -> Bool {
        if CurrentUser.facebookUserId != nil && CurrentUser.fullName != nil {
            return true
        } else {
            return false
        }
    }
}
