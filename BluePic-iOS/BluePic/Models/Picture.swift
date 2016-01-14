/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

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
