//
//  DataManager.swift
//  BluePic
//
//  Created by Alex Buck on 4/25/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import BMSCore


enum BlueMixDataManagerError: ErrorType {
    case DocDoesNotExist
}

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
    private let kBluemixBaseRequestURLKey_local = "bluemixBaseRequestURL_local"
    private let kBluemixBaseRequestURLKey_remote = "bluemixBaseRequestURL_remote"
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
    
    func getBluemixBaseRequestURL() -> String {
        if(isLocal()){
            return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixBaseRequestURLKey_local)
        }
        else{
            return Utils.getStringValueWithKeyFromPlist(kKeysPlistName, key: kBluemixBaseRequestURLKey_remote)
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

    
    
    
    
    func getImages(result : (images : [Image]?)-> ()){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kImagesEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                result(images: nil)
                print ("Error :: \(error)")
            } else {
                
                let images = self.parseGetImagesResponse(response, userId: nil, usersName: nil)
                result(images: images)
            }
        }
  
    }
    
    func getImagesByUserId(userId : String, usersName : String, result : (images : [Image]?)-> ()){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId + "/" + kImagesEndPoint
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                //result(images: nil)
                print ("Error :: \(error)")
            } else {
                
                let images = self.parseGetImagesResponse(response, userId: userId, usersName: usersName)
                result(images: images)
                
                let response = Utils.convertResponseToDictionary(response)
                print(response)
            }
        }
        
    }
    
    private func parseGetImagesResponse(response : Response?, userId : String?, usersName : String?) -> [Image]{
        var images = [Image]()
        
        if let dict = Utils.convertResponseToDictionary(response),
            let records = dict["records"] as? [[String:AnyObject]]{
            
            for var record in records {
                
                if let userId = userId, let usersName = usersName {
                    
                    var user = [String : AnyObject]()
                    user["name"] = usersName
                    user["_id"] = userId
                    record["user"] = user

                }
                
                
                if let image = Image(record){
                    images.append(image)
                }
            }
  
        }
        
        return images
    }
    
    
    func getUsers(){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint
        
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
    }
    
    func getUserById(userId : String, result: (user : User?) -> ()){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId
        
        let request = Request(url: requestURL, method: HttpMethod.GET)
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error Getting User By Id :: \(error)")
               result(user: nil)
            } else {
                var user = User(response)
                result(user: user)
                print ("Success :: \(response?.responseText)")
            }
        }
    }
    
    func doesUserAlreadyExist(userId : String, result : (doesUserAlreadyExist : Bool) -> ()){
    
        getUserById(userId, result: { user in
            
            if user != nil {
                result(doesUserAlreadyExist: true)
            }
            else{
                result(doesUserAlreadyExist: false)
            }
            
        })
    }
    
    
    private func createNewUser(userId : String, name : String, result : ((user : User?) -> ())){
        
        let requestURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint
        
        let request = Request(url: requestURL, method: HttpMethod.POST)
        
        //request.headers = ["Content-Type" : "application/json"]
        
        let json = ["_id": userId, "name": name]

        
        do{
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            
            request.sendData(jsonData, completionHandler: { (response, error) -> Void in
                if let error = error {
                    result(user: nil)
                    print ("Error  Creating New User :: \(error)")
                } else {
                    let user = User(response)
                    result(user: user)
                    print ("Success :: \(response?.responseText)")
                }
            })
            
        } catch {
            result(user: nil)
            
        }
        
    }
    
    
    func checkIfUserAlreadyExistsIfNotCreateNewUser(userId : String, name : String, callback : ((success : Bool) -> ())){

        getUserById(userId, result: { user in
            
            if(user != nil){
               callback(success: true)
            }
            else{
                self.createNewUser(userId, name: name, result: { user in
                    
                    if(user != nil){
                        callback(success: true)
                    }
                    else{
                        callback(success: false)
                    }

                })
            }
            
        })

    }
    
    

    func createNewUserIfUserDoesntAlreadyExistElseReturnExistingUser(userId : String, name : String, result : ((user : User?) -> ())){
        
        getUserById(userId, result: { user in
            
            if let user = user {
                result(user: user)
            }
            else{
                self.createNewUser(userId, name: name, result: { user in
                    result(user: user)
                })
            }
   
        })
    }
    
    //users/:userId/images/:fileName/:displayName/:width/:height/:latitude/:longitude/:location - POST
    func postNewImage(userId : String, fileName : String, displayName : String, width : CGFloat, height : CGFloat, latitude : String, longitude : String, city : String,  image: NSData){
        
        let tempURL = getBluemixBaseRequestURL() + "/" + kUsersEndPoint + "/" + userId + "/" + kImagesEndPoint + "/" + fileName + "/" + displayName + "/" + "\(width)" + "/" + "\(height)" + "/" + latitude + "/" + longitude + "/" + city
        
        let requestURL = tempURL.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())!

        //"multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        print(requestURL)
        let request = Request(url: requestURL, method: HttpMethod.POST)
        
        
        //image/png
        //application/x-www-form-urlencoded
        
        
        request.headers = ["Content-Type" : "image/png"]
        
        //let request = Request(url: "/" + kUsersEndPoint + "/" + userId + "/" + kImagesEndPoint + "/" + fileName + "/" + displayName, method: HttpMethod.POST)
        
        //NEED TO ADD IMAGE TO PAYLOAD
        //request.headers = ["name": name]
        //request.queryParameters = ["foo":"bar"]
        
     
        
        request.sendData(image, completionHandler: { (response, error) -> Void in
            if let error = error {
                print ("Error uploading image :: \(error)")
            } else {
                
                 var dict = Utils.convertResponseToDictionary(response)
                //print(dict)
                var user = [String : AnyObject]()
                
                user["name"] = "Test User"
                user["_id"] = "1234"
                dict!["user"] = user
                print(dict)
                
                let image = Image(dict!)
                
                print(image?.url!)
                
                
                //print ("Success uploading image :: \(response?.responseText)")
            }
        })
        
        
        
    }
    
    
 
    
}

