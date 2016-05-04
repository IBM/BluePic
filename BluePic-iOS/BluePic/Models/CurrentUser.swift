//
//  CurrentUser.swift
//  BluePic
//
//  Created by Alex Buck on 5/4/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class CurrentUser: NSObject {


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
