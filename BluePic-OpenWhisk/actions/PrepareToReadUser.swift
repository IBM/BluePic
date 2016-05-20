/**
 * Setup parameters for CloudantRead action, for reading user document from Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    
    var userId: String? = args["userId"] as? String
    var imageId: String? = args["imageId"] as? String
    
    let result:[String:Any] = [
        "userId": userId,
        "userDoc": "",
        "imageId": imageId,
        "imageDoc": "",
        "alchemyResult":"",
        "weatherResult":"",
        "cloudantId":userId
    ]

    // return, which should be a dictionary
    print("Result is (result!)")
    return result
}
