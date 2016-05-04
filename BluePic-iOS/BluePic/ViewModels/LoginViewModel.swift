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

enum LoginViewModelNotification {
    case LoginSuccess
    case LoginFailure
}

class LoginViewModel: NSObject {
    
    var notifyLoginVC : ((loginViewModelNotification : LoginViewModelNotification) -> ())!
    
    /**
     Method to initialize view model with the appropriate callback
     
     - parameter fbAuthCallback: callback to be executed on completion of trying to authenticate with Facebook
     
     - returns: an instance of this view model
     */
    init(notifyLoginVC: ((loginViewModelNotification : LoginViewModelNotification) -> ())) {
        super.init()
        
        self.notifyLoginVC = notifyLoginVC
        
    }
    
    func loginLater(){
        LoginDataManager.SharedInstance.loginLater()
    }
    
    
    /**
     Method to attempt authenticating with Facebook and call the callback if failure, otherwise will continue to object storage container creation
     */
    func authenticateWithFacebook() {
        
        LoginDataManager.SharedInstance.login({ success in
        
            if(success){
                self.notifyLoginVC(loginViewModelNotification: LoginViewModelNotification.LoginSuccess)
            }
            else{
                self.notifyLoginVC(loginViewModelNotification: LoginViewModelNotification.LoginFailure)
            }
        
        })
    }

}
