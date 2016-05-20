/**
 * Setup parameters for weather and alchemy actions,
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    let cloudantResult: String? = args["cloudantResult"] as? String
    let userDocString:String? = args["userDoc"] as? String
    let user:[String:Any]? = convert(input:userDocString!)
    let language:String? = user!["language"] as? String 
    let unitsOfMeasurement:String? = user!["unitsOfMeasurement"] as? String 
    let image:[String:Any]? = convert(input:cloudantResult!)
    let location:[String:Any]? = image!["location"] as? [String:Any] 
    let imageUrl:String? = image!["url"] as? String 
    
    let result:[String:Any] = [
        "userId":  args["userId"],
        "userDoc": args["userDoc"],
        "imageId":  args["userId"],
        "imageDoc": cloudantResult!,
        "alchemyResult": args["alchemyResult"],
        "weatherResult": args["weatherResult"],
        "language":language!,
        "units":unitsOfMeasurement!,
        "latitude":"\(location!["latitude"]!)",
        "longitude":"\(location!["longitude"]!)",
        "imageURL":imageUrl!,
    ]

    // return, which should be a dictionary
    return result
}

func convert(input:String) -> [String: Any]? {
    
    var result:[String:Any]?
    let data = input.bridge().dataUsingEncoding(NSUTF8StringEncoding)
     do {
        result = try NSJSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
    } catch {
        print("Error \(error)")
    }
    
    return result;
}
