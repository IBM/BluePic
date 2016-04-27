//
//  DataManager.swift
//  BluePic
//
//  Created by Alex Buck on 4/25/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import BMSCore

class BluemixDataManager: NSObject {
    
    static let SharedInstance: BluemixDataManager = {
        
        var manager = BluemixDataManager()
        
        return manager
        
    }()
    
    //End Points
    private let kImagesEndPoint = "images"
    private let kUsersEndPoint = "users"
    
    
    //Plist Keys
    private let kKeysPlistName = "keys"
    private let kIsLocalKey = "isLocal"
    private let kBluemixBaseURLKey_local = "bluemixBaseURL_local"
    private let kBluemixBaseURLKey_remote = "bluemixBaseURL_remote"
    private let kBluemixAppRouteKey = "bluemixAppRoute"
    private let kBluemixAppGUIDKey = "bluemixAppGUID"
    private let kBluemixAppRegionKey = "bluemixAppRegion"
    
    
    
    func initilizeBluemixAppRoute(){
        
        let appRoute = getBluemixAppRoute()
        let appGuid =  getBluemixAppGUID()
        let bluemixRegion = getBluemixAppRegion()
        
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(appRoute,
                                           bluemixAppGUID: appGuid,
                                           bluemixRegion: bluemixRegion)
        
    }
    
    
    private func isLocal() -> Bool {
        return Utils.getBoolValueWithKeyFromPlist(kKeysPlistName, key: kIsLocalKey)
    }
    
    func getBluemixBaseURL() -> String {
        if(isLocal()){
            return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixBaseURLKey_local)
        }
        else{
            return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixBaseURLKey_remote)
        }
    }
    
    func getBluemixAppRoute() -> String {
        return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixAppRouteKey)
    }
    
    func getBluemixAppGUID() -> String {
        return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixAppGUIDKey)
    }
    
    func getBluemixAppRegion() -> String {
        return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixAppRegionKey)
    }
    
    func localHostHelloTest(){
        
        let appRoute = "http://localhost:8090"//Utils.getKeyFromPlist("keys", key: "backend_route")
        let appGuid =  ""//Utils.getKeyFromPlist("keys", key: "GUID")
        
        //        let appRoute = "https://greatapp.mybluemix.net"
        //        let appGuid = "2fe35477-5410-4c87-1234-aca59511433b"
        let bluemixRegion = BMSClient.REGION_US_SOUTH
        
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(appRoute,
                                           bluemixAppGUID: appGuid,
                                           bluemixRegion: bluemixRegion)
        
        let request = Request(url: "/images", method: HttpMethod.GET)
        //request.headers = ["foo":"bar"]
        //request.queryParameters = ["foo":"bar"]
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
        //        let logger = Logger.loggerForName("FirstLogger")
        //
        //        logger.debug("This is a debug message")
        //        logger.error("This is an error message")
        //        logger.info("This is an info message")
        //        logger.warn("This is a warning message")
        
        
    }

    
    
    
    
    func getImages(){
        
        let request = Request(url: getBluemixBaseURL() + "/" + kImagesEndPoint, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
  
    }
    
    
    func getUsers(){
        
        let request = Request(url: "/" + kUsersEndPoint, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
    }
    
    func getUserById(userId : String){
        
        let request = Request(url: "/" + kUsersEndPoint + "/" + userId, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
    }
    
    
    func createNewUser(name : String){
        
        let request = Request(url: "/" + kUsersEndPoint, method: HttpMethod.POST)
        request.headers = ["name": name]
        //request.queryParameters = ["foo":"bar"]
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
        
    }
    
    ///users/:userId/images/:fileName/:displayName
    func postNewImage(userId : String, fileName : String, displayName : String,  image: NSData){
        
        let request = Request(url: "/" + kUsersEndPoint + "/" + userId + "/" + fileName + "/" + displayName, method: HttpMethod.POST)
        
        //NEED TO ADD IMAGE TO PAYLOAD
        //request.headers = ["name": name]
        //request.queryParameters = ["foo":"bar"]
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
    }
    
    
 
    
}
