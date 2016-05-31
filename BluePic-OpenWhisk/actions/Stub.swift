/**
 * Setup parameters for CloudantRead action, for reading user document from Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    
    let imageId: String? = args["imageId"] as? String
    
    let result:[String:Any] = [
        "imageId": imageId,
        "success": true
    ]

    // return, which should be a dictionary
    print("Result is (result!)")
    return result
}
