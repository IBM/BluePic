//
//  Image.swift
//  BluePic
//
//  Created by Alex Buck on 4/29/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import BMSCore

class Image: NSObject {

    
    var id : String?
    var displayName : String?
    var fileName : String?
    var timeStamp : String?
    var url : String?
    var usersName : String?
    
    init?(_ dict : [String : AnyObject]) {
        
        super.init()
        
        //if let dict = Utils.convertResponseToDictionary(response){
            
            if let id = dict["_id"] as? String,
                let displayName = dict["displayName"] as? String,
                let fileName = dict["fileName"] as? String,
                let url = dict["url"] as? String,
                let user = dict["user"] as? [String : AnyObject],
                let usersName = user["name"] as? String {
                
                self.id = id
                self.displayName = displayName
                self.fileName = fileName
                self.url = url
                self.usersName = usersName
        
            }else{
                return nil
            }
            
//        }
//        else{
//            return nil
//        }
        
    }

    
}
