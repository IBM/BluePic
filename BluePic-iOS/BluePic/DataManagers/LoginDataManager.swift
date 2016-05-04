//
//  LoginDataManager.swift
//  BluePic
//
//  Created by Alex Buck on 5/4/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class LoginDataManager: NSObject {

    
    /// Shared instance of data manager
    static let SharedInstance: LoginDataManager = {
        
        var manager = LoginDataManager()
        
        return manager
        
    }()
    
    
    
    
    
    func login(){
        

    }
    
    
    func loginLater(){
        
        CurrentUser.willLoginLater = true
 
    }
    
    
    func isUserAuthenticatedOrPressedSignInLater() -> Bool {
        if(isUserAlreadyAuthenticated() || CurrentUser.willLoginLater){
            return true
        }
        else{
           return false
        }
    }
    

    private func isUserAlreadyAuthenticated() -> Bool {
        if(CurrentUser.facebookUserId != nil && CurrentUser.fullName != nil){
            return true
        }
        else{
            return false
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
