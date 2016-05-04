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
    
    
    
    
    
}
