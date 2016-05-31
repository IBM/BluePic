/**
 * Setup parameters for weather and alchemy actions,
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
    
    let cloudantResult: String? = args["cloudantResult"] as? String
    let cloudantResultData = cloudantResult!.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!

    let image = JSON(data: cloudantResultData)
    let location = image["location"]
    let imageUrl = image["url"].string
    
    let result:[String:Any] = [
        "imageId":  args["imageId"],
        "imageDoc": cloudantResult!,
        "alchemyResult": args["alchemyResult"],
        "weatherResult": args["weatherResult"],
        "latitude":"\(location["latitude"].double!)",
        "longitude":"\(location["longitude"].double!)",
        "imageURL":imageUrl!,
    ]

    return result
}