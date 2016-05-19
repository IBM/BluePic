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
    
    

    func login(callback : ((error : FacebookAuthenticationError?)->())){
        
        ///Check if user is already authenticated from previous sesssions, aka check nsuserdefaults for user info
        if(isUserAlreadyAuthenticated()){
            callback(error: nil)
        }
            //user not already authenticated from previous sessions
        else{
            
            //login with facebook
            FacebookDataManager.SharedInstance.loginWithFacebook({ (facebookUserId: String?, facebookUserFullName : String?, error: FacebookAuthenticationError?) in
                
                //facebook authentication failure
                if(error != nil){
                    callback(error: error)
                }
                //facebook authentication success
                else{
                    
                    let language = LocationDataManager.SharedInstance.getLanguageLocale()
                    let unitsOfMeasurement = LocationDataManager.SharedInstance.getUnitsOfMeasurement()
                    
                    //try to register user with backend if the user doesn't already exist
                    //We know facebookUserId and facebookUserFullName aren't nil because there wasn't an error
                    BluemixDataManager.SharedInstance.checkIfUserAlreadyExistsIfNotCreateNewUser(facebookUserId!, name: facebookUserFullName!, language: language, unitsOfMeasurement: unitsOfMeasurement, callback: { success in
                        //return the result of this which will determine whether login was a success or not
                        
                        if(success){
                            CurrentUser.willLoginLater = false
                            CurrentUser.facebookUserId = facebookUserId!
                            CurrentUser.fullName = facebookUserFullName!
                        }
                        
                        print("success finding user")
                       
                        callback(error: nil)
                    })
                }

            })
            
        }
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
