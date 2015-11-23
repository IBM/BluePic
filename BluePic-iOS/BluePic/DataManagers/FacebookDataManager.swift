//
//  FacebookDataManager.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/18/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

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
     Method to auth user using Facebook SDK
     
     - parameter callback: Success or Failure
     */
    func authenticateUser(callback : ((networkRequest : NetworkRequest) -> ())){
        if (self.checkIMFClient() && self.checkAuthenticationConfig()) {
            self.getAuthToken(callback)
        }
        else{
            callback(networkRequest: NetworkRequest.Failure)
        }
        
    }
    
    
    /**
     Method to get authentication token from Facebook SDK
     
     - parameter callback: Success or Failure
     */
    func getAuthToken(callback : ((networkRequest: NetworkRequest) -> ())) {
       let authManager = IMFAuthorizationManager.sharedInstance()
        authManager.obtainAuthorizationHeaderWithCompletionHandler( {(response: IMFResponse?, error: NSError?) in
            let errorMsg = NSMutableString()
            
            //error
            if let errorObject = error {
                callback(networkRequest: NetworkRequest.Failure)
                errorMsg.appendString("Error obtaining Authentication Header.\nCheck Bundle Identifier and Bundle version string\n\n")
                if let responseObject = response {
                    if let responseString = responseObject.responseText {
                        errorMsg.appendString(responseString)
                    }
                }
                let userInfo = errorObject.userInfo
                errorMsg.appendString(userInfo.description)
            }
                
                //no error
            else {
                if let identity = authManager.userIdentity {
                    if let userID = identity["id"] as?NSString {
                        if let userName = identity["displayName"] as? NSString {
                        
                            //save username and id to shared instance of this class
                            self.fbUniqueUserID = userID as String
                            self.fbUserDisplayName = userName as String
                        
                            //set user logged in
                            self.isLoggedIn = true
                            
                            //save user id and name for future app launches
                            NSUserDefaults.standardUserDefaults().setObject(userID, forKey: "user_id")
                            NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "user_name")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
//                            // save that user has logged in to user defaults
//                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoggedIn")
//                            NSUserDefaults.standardUserDefaults().synchronize()
                        
                        print("Authenticated user \(userName) with id \(userID)")
                            
                        self.checkIfUserExistsOnCloudantAndPushIfNeeded()
                            
                        callback(networkRequest: NetworkRequest.Success)
                        }
                    }
                    else {
                        print("Valid Authentication Header and userIdentity, but id not found")
                        callback(networkRequest: NetworkRequest.Failure)
                    }
                    
                }
                else {
                    print("Valid Authentication Header, but userIdentity not found. You have to configure one of the methods available in Advanced Mobile Service on Bluemix, such as Facebook")
                    callback(networkRequest: NetworkRequest.Failure)
                }
                
                
            }
            
            })
        
    }
    
    
    /**
     Method to check to make sure IMFClient is valid (route and GUID)
     
     - returns: true or false if valid or not
     */
    func checkIMFClient() -> Bool {
        let imfClient = IMFClient.sharedInstance()
        let route = imfClient.backendRoute
        let guid = imfClient.backendGUID
        
        if (route == nil || route.length == 0) {
            print ("Invalid Route.\n Check applicationRoute in appdelegate")
            return false
        }
        
        if (guid == nil || guid.length == 0) {
            print ("Invalid GUID.\n Check applicationId in appdelegate")
            return false
        }
        return true
        
    }
    
    
    
    /**
     Method to check if Facebook is configured
     
     - returns: true if configured, false if not
     */
    func checkAuthenticationConfig() -> Bool {
        if (self.isFacebookConfigured()) {
            return true
        } else {
            print("Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook")
            return false
        }
        
        
    }
    
    
    /**
     Method to check if Facebook SDK is setup on native iOS side and all required keys have been added to plist
     
     - returns: true if configured, false if not
     */
    func isFacebookConfigured() -> Bool {
        let facebookAppID = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookAppID") as? NSString
        let facebookDisplayName = NSBundle.mainBundle().objectForInfoDictionaryKey("FacebookDisplayName") as? NSString
        let urlTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as? NSArray
        
        let urlTypes0 = urlTypes!.firstObject as? NSDictionary
        let urlSchemes = urlTypes0!["CFBundleURLSchemes"] as? NSArray
        let facebookURLScheme = urlSchemes!.firstObject as? NSString
        
        if (facebookAppID == nil || facebookAppID!.isEqualToString("") || facebookAppID == "123456789") {
            return false
        }
        if (facebookDisplayName == nil || facebookDisplayName!.isEqualToString("")) {
            return false
        }
        
        if (facebookURLScheme == nil || facebookURLScheme!.isEqualToString("") || facebookURLScheme!.isEqualToString("fb123456789") || !(facebookURLScheme!.hasPrefix("fb"))) {
            return false
        }
        
        //success if made it past this point
        
        
        
        //save app ID and app display name to this class
        self.fbAppID = facebookAppID! as String
        self.fbAppDisplayName = facebookDisplayName! as String
        

        print("Facebook Authentication Configured:\nFacebookAppID \(facebookAppID!)\nFacebookDisplayName \(facebookDisplayName!)\nFacebookURLScheme \(facebookURLScheme!)")
        return true;
    }
    
    func checkIfUserExistsOnCloudantAndPushIfNeeded() {
        
        //Check if doc with fb id exists
        if(!CloudantSyncClient.SharedInstance.doesExist(self.fbUniqueUserID!))
        {
            //Create profile document locally
            CloudantSyncClient.SharedInstance.createProfileDoc(self.fbUniqueUserID!, name: self.fbUserDisplayName!)
            //Push new profile document to remote database
            CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
            
        }
        
    }
    
    
    
}
