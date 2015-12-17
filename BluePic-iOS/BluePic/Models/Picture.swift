/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

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
