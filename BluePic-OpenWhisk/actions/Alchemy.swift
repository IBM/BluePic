/**
 * Run alchemy analysis
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
       
    let alchemyKey: String? = args["alchemyKey"] as? String
    let imageURL: String? = args["imageURL"] as? String
    
    let url: String = "https://gateway-a.watsonplatform.net/calls/url/URLGetRankedImageKeywords?url=\(imageURL!)&outputMode=json&apikey=\(alchemyKey!)"
    
    var str:String = ""

    HTTP.get(url) { response in

        do {
            str = try response!.readString()!
        } catch {
            print("Error \(error)")
        }
    }
    
    let result:[String:Any] = [
        "imageId":  args["imageId"],
        "imageDoc": args["imageDoc"],
        "alchemyResult": "\(str)",
        "weatherResult": args["weatherResult"],
        "latitude": args["latitude"],
        "longitude": args["longitude"],
        "imageURL": args["imageURL"]
    ]
    
    return result
}
