/**
 * Setup parameters for CloudantRead action, for reading image document from Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    
    let imageId: String? = String(args["imageId"]!)
    
    let result:[String:Any] = [
        "cloudantId": imageId
    ]

    return result
}
