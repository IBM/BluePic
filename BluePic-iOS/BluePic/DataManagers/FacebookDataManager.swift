//
//  FacebookDataManager.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/18/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class FacebookDataManager: NSObject {
    enum NetworkRequest {
        case Success
        case Failure
    }
    
    class func authenticateUser(callback : ((networkRequest : NetworkRequest) -> ())){
        if (self.checkIMFClient() && self.checkAuthenticationConfig()) {
            self.getAuthToken(callback)
        }
        else{
            callback(networkRequest: NetworkRequest.Failure)
        }
        
    }
    
    
    class func getAuthToken(callback : ((networkRequest: NetworkRequest) -> ())) {
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
                        let userName = identity["displayName"]
                        print("Authenticated user \(userName) with id \(userID)")
                        callback(networkRequest: NetworkRequest.Success)
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
    
    
    class func checkIMFClient() -> Bool {
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
    
    
    
    class func checkAuthenticationConfig() -> Bool {
        if (self.isFacebookConfigured()) {
            return true
        } else {
            print("Authentication is not configured in Info.plist. You have to configure Info.plist with the same Authentication method configured on Bluemix such as Facebook")
            return false
        }
        
        
    }
    
    
    class func isFacebookConfigured() -> Bool {
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
        
        

        print("Facebook Authentication Configured:\nFacebookAppID \(facebookAppID)\nFacebookDisplayName \(facebookDisplayName)\nFacebookURLScheme \(facebookURLScheme)")
        return true;
    }
    
    
    
}
