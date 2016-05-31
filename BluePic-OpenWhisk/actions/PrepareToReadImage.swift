/**
 * Setup parameters for CloudantRead action, for reading image document from Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    var imageId: String? = args["imageId"] as? String
    var cloudantResult: String? = args["cloudantResult"] as? String
    
    let result:[String:Any] = [
        "imageId": imageId,
        "imageDoc": "",
        "alchemyResult":"",
        "weatherResult":"",
        "cloudantId":imageId
    ]

    // return, which should be a dictionary
    return result
}
