/**
 * Copyright IBM Corporation 2015-2016
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


/// Manages all user authentication state and calls
class UserManager: NSObject {

    enum UserAuthenticationState {
        case SignedInWithFacebook
        case SignedOut
    }

    /// Shared instance of user manager
    static let SharedInstance: UserManager = {
        var manager = UserManager()
        return manager
    }()
    
    
    private override init() {} //This prevents others from using the default '()' initializer for this class.
    
    /// Display name for user
    var userDisplayName: String?
    
    /// Unique user ID
    var uniqueUserID: String?
    
    /// User's authentication state
    var userAuthenticationState = UserAuthenticationState.SignedOut
    
    
    /// Facebook
    /// Prefix for url needed to get user profile picture given their unique id (id goes after this)
    let facebookProfilePictureURLPrefix = "http://graph.facebook.com/"
    
    /// Postfix for url needed to get user profile picture given their unique id (id goes before this)
    let facebookProfilePictureURLPostfix = "/picture?type=large"
    
    
    /**
     Method will try to show login screen if not authenticated.
     */
    func tryToShowLoginScreen() {
        self.showLoginIfUserNotAuthenticated()
    }
    
    
    
    /**
     Method will pull down latest data, and try to show login screen if user is not authenticated nor has pressed "sign in later" button
     
     - parameter presentingVC: tab bar VC to present login VC on
     */
    func showLoginIfUserNotAuthenticated() {
        // start pulling photos (will automatically hide loading when successful)
        PhotosDataManager.SharedInstance.getFeedData() {(pictures, error) in
            if let error = error {
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(.PhotosListFailure(error))
            }
            else {
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(.PhotosListSuccess(pictures!))
            }
        }
        
        //check if user is already authenticated previously
        if let userID = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? String {
            if let userName = NSUserDefaults.standardUserDefaults().objectForKey("user_name") as? String {
                self.userDisplayName = userName
                self.uniqueUserID = userID
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.GotPastLoginCheck)
            }
        }
        else { //user not authenticated
            
            //show login if user hasn't pressed "sign in later" (first time logging in)
            if !NSUserDefaults.standardUserDefaults().boolForKey("hasPressedLater") {
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.UserNotAuthenticated)
                
            } else { //user pressed "sign in later"
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.GotPastLoginCheck)                
            }
        }
        
    }
    
    
    /**
     Method to return a url for the user's profile picture
     
     - returns: string representing the image url
     */
    func getUserProfilePictureURL() -> String {
        if userAuthenticationState == .SignedInWithFacebook {
            return getUserFacebookProfilePictureURL()
        }
        else{
            return ""
        }
    }
    
    /**
     Method to return a url for the user's profile picture
     
     - returns: string representing the image url
     */
    private func getUserFacebookProfilePictureURL() -> String {
        if let facebookID = uniqueUserID {
            let profilePictureURL = facebookProfilePictureURLPrefix + facebookID + facebookProfilePictureURLPostfix
            return profilePictureURL
        }
        else{
            return ""
        }
    }

    
    func signOut() {
        userDisplayName = nil
        uniqueUserID = nil
        if userAuthenticationState == .SignedInWithFacebook {
            signOutFromFacebook()
        }
        userAuthenticationState = .SignedOut
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_id")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_name")
        NSUserDefaults.standardUserDefaults().synchronize()

        DataManagerCalbackCoordinator.SharedInstance.sendNotification(.UserSignedOut)

    }
    
    private func signOutFromFacebook() {
        FBSDKLoginManager().logOut()
    }

    
}