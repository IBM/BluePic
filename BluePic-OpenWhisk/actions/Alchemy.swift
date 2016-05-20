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
    
    // Force KituraNet call to run synchronously on a global queue
    var str:String = ""
    dispatch_sync(dispatch_get_global_queue(0, 0)) {

            Http.get(url) { response in

                do {
                   str = try response!.readString()!
                } catch {
                    print("Error \(error)")
                }

            }
    }
    
    let result:[String:Any] = [
        "userId":  args["userId"],
        "userDoc": args["userDoc"],
        "imageId":  args["userId"],
        "imageDoc": args["imageDoc"],
        "alchemyResult": "\(str)",
        "weatherResult": args["weatherResult"],
        "language": args["language"],
        "units":  args["units"],
        "latitude": args["latitude"],
        "longitude": args["longitude"],
        "imageURL": args["imageURL"]
    ]
    
    return result
}
