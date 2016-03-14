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


/// Manages all facebook authentication state and calls
class FacebookDataManager: NSObject {
    
    /// Shared instance of data manager
    static let SharedInstance: FacebookDataManager = {
        
        var manager = FacebookDataManager()
        
        return manager
        
    }()
    

    private override init() {} //This prevents others from using the default '()' initializer for this class.

    /// Facebook app ID
    var fbAppID: String?
    
    /// Display name for the app on Facebook
    var fbAppDisplayName: String?
    
    /// Display name for user on Facebook
    var fbUserDisplayName: String?
    
    /// Unique user ID given from Facebook API
    var fbUniqueUserID: String?
    
    /// Bool if user is authenticated with facebook
    var isLoggedIn = false
    
    /// Prefix for url needed to get user profile picture given their unique id (id goes after this)
    let facebookProfilePictureURLPrefix = "http://graph.facebook.com/"
    
    /// Postfix for url needed to get user profile picture given their unique id (id goes before this)
    let facebookProfilePictureURLPostfix = "/picture?type=large"
    
    /**
     Custom enum for whether facebook authentication was successful or not
     
     - Success: successful
     - Failure: failure to connect
     */
    enum NetworkRequest {
        case Success
        case Failure
    }
    

    /**
     Method will try to show login screen if not authenticated with Facebook.
    */
    func tryToShowLoginScreen() {
        self.showLoginIfUserNotAuthenticated()
    }
    
    
    
    /**
     Method will pull down latest cloudant data, and try to show login screen if user is not authenticated nor has pressed "sign in later" button
     
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
                self.fbUserDisplayName = userName
                self.fbUniqueUserID = userID
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
    func getUserFacebookProfilePictureURL() -> String {
        if let facebookID = fbUniqueUserID {
            
            let profilePictureURL = facebookProfilePictureURLPrefix + facebookID + facebookProfilePictureURLPostfix
            
            return profilePictureURL
        }
        else{
            return ""
        }
    }
    
    
    func signOut() {
        FBSDKLoginManager().logOut()
        
        fbUserDisplayName = nil
        fbUniqueUserID = nil
        isLoggedIn = false
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_id")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_name")
        NSUserDefaults.standardUserDefaults().synchronize()

        DataManagerCalbackCoordinator.SharedInstance.sendNotification(.UserSignedOut)
    }
    
    
    
}
