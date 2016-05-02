//
//  User.swift
//  BluePic
//
//  Created by Alex Buck on 4/29/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import BMSCore

class User: NSObject {

    var facebookID : String?
    var name : String?
    
    
    
    init(_ response: Response?) {
        
        super.init()
        
        if let dict = Utils.convertResponseToDictionary(response){
        
            let facebookID = dict["_id"] as? String ?? ""
            let name = dict["name"] as? String ?? ""
            
            self.facebookID = facebookID
            self.name = name
           
        }
        else{
            
            print("invalid JSON")
        }
   
    }
    
    
    
//    class func createUserFromResponse(response : Response?) {
//        
//        if let dict = Utils.convertResponseToDictionary(response){
//            
//            
//            if let facebookID = dict["_id"] as? String,
//                let name = dict["name"] as? String {
//                
//                let user = User()
//                
//                
//                user.face
//                
//                
//                
//            }
//            
//            
//            
//            let facebookID = dict["_id"] as? String ?? ""
//            let name = dict["name"] as? String ?? ""
//            
//            self.facebookID = facebookID
//            self.name = name
//            
//        }
//        else{
//            
//            print("invalid JSON")
//        }
//  
//    }
    

        
}

    
    
    
    
    
    
    
    

