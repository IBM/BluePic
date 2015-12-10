//
//  Picture.swift
//  BluePic
//
//  Created by Alex Buck on 12/2/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class Picture: NSObject {

    var url : String?
    
    var image : UIImage?
    
    var displayName : String?
    
    var timeStamp : Double?
    
    var ownerName : String?
    
    var width : CGFloat?
    
    var height : CGFloat?
    
    var fileName : String?
    
    let kDefaultWidthAndHeight : CGFloat = 100
    
    
    
    func setWidthAndHeight(width : String?, height : String?){
        
        if let w = width {
            if w != "" {
                self.width = CGFloat((w as NSString).floatValue)
            }
        }
        
        if let h = height {
            if h != "" {
                self.height = CGFloat((h as NSString).floatValue)
            }
        }
        
  
    }
    
    
}
