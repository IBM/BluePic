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

class CurrentUser: NSObject {

    /// Grab facebook user id of user from NsUserDefaults
    class var facebookUserId: String? {
        get {
            if let userId = NSUserDefaults.standardUserDefaults().objectForKey("facebook_user_id") as? String {
                return userId
            }
            else{
                return nil
            }
        }
        set(userId) {
            
            NSUserDefaults.standardUserDefaults().setObject(userId, forKey: "facebook_user_id")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    /// grab full name of user from NSUserDefaults
    class var fullName : String? {
        get {
            if let full_name = NSUserDefaults.standardUserDefaults().objectForKey("user_full_name") as? String {
                return full_name
            }
            else{
                return nil
            }
        }
        set(user_full_name) {
            
            NSUserDefaults.standardUserDefaults().setObject(user_full_name, forKey: "user_full_name")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    
    /// generate string for the users facebook profile picture url
    class var facebookProfilePictureURL : String {
        get {
            if let facebookUserId = CurrentUser.facebookUserId {
                return kFacebookProfilePictureURLPrefix + facebookUserId + kFacebookProfilePictureURLPostfix
            }
            else{
                return ""
            }
        }
    }
    
    /// Grab bool value representing if the user has chosen to login later or not from NSUSerDefaults
    class var willLoginLater : Bool {
        get {
            if let log_in_later = NSUserDefaults.standardUserDefaults().objectForKey("log_in_later") as? Bool{
                return log_in_later
            }
            else{
                return false
            }
        }
        set(log_in_later) {
            NSUserDefaults.standardUserDefaults().setObject(log_in_later, forKey: "log_in_later")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
   
    }

    
    /// Prefix for url needed to get user profile picture given their unique id (id goes after this)
    private static let kFacebookProfilePictureURLPrefix = "http://graph.facebook.com/"
    
    /// Postfix for url needed to get user profile picture given their unique id (id goes before this)
    private static let kFacebookProfilePictureURLPostfix = "/picture?type=large"
    
}
