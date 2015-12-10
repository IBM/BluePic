//
//  LoginViewModel.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/9/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class LoginViewModel: NSObject {
    
    var fbAuthCallback: ((Bool!)->())!
    
    
    
    init(fbAuthCallback: ((Bool!)->())) {
        super.init()
        
        self.fbAuthCallback = fbAuthCallback
        
        
    }
    
    
    /**
     Method to attempt authenticating with Facebook and call the callback if failure, otherwise will continue to object storage container creation
     */
    func authenticateWithFacebook() {
        FacebookDataManager.SharedInstance.authenticateUser({(response: FacebookDataManager.NetworkRequest) in
            if (response == FacebookDataManager.NetworkRequest.Success) {
                print("successfully logged into facebook with keys:")
                if let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
                    if let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName {
                        print("\(userID)")
                        print("\(userDisplayName)")
                        //save that user has not pressed login later
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasPressedLater")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        //add container once to object storage
                        self.createObjectStorageContainer(userID)
                        
                    }
                }
            }
            else {
                print("failure logging into facebook")
                self.fbAuthCallback(false)

            }
        })
 
    }
    
    
    /**
     Method to attempt creating an object storage container and call callback upon completion (success or failure)
     
     - parameter userID: <#userID description#>
     */
    func createObjectStorageContainer(userID: String!) {
        print("Creating object storage container...")
        ObjectStorageDataManager.SharedInstance.objectStorageClient.createContainer(userID, onSuccess: {(name) in
            print("Successfully created object storage container with name \(name)") //success closure
            self.fbAuthCallback(true)
            }, onFailure: {(error) in //failure closure
                print("Facebook auth successful, but error creating Object Storage container: \(error)")
                self.fbAuthCallback(false)
        })
        
    }
    

}
