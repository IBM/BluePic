//
//  MCARESTTestManager.swift
//  BluePic
//
//  Created by Alex Buck on 4/20/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import BMSCore

class MCARESTTestManager: NSObject {

    static let SharedInstance: MCARESTTestManager = {
        
        var manager = MCARESTTestManager()
        
        return manager
        
    }()
    
    
   
    func localHostTest(){
        
        let appRoute = "http://localhost:8090"//Utils.getKeyFromPlist("keys", key: "backend_route")
        let appGuid =  ""//Utils.getKeyFromPlist("keys", key: "GUID")
        
        //        let appRoute = "https://greatapp.mybluemix.net"
        //        let appGuid = "2fe35477-5410-4c87-1234-aca59511433b"
        let bluemixRegion = BMSClient.REGION_US_SOUTH
        
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(appRoute,
                                           bluemixAppGUID: appGuid,
                                           bluemixRegion: bluemixRegion)
        
        let request = Request(url: "/", method: HttpMethod.GET)
        //request.headers = ["foo":"bar"]
        //request.queryParameters = ["foo":"bar"]
        
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error :: \(error)")
            } else {
                print ("Success :: \(response?.responseText)")
            }
        }
        
        
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
        
        let request = Request(url: "/hello", method: HttpMethod.GET)
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
    

}
