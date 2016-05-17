/**
 * Stub code for reading data from Cloudant in a whisk action
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
       
    let alchemyKey: String? = args["alchemyKey"] as? String
    let imageURL: String? = args["imageURL"] as? String
    
    let url: String = "https://gateway-a.watsonplatform.net/calls/url/URLGetRankedImageKeywords?url=\(imageURL!)&outputMode=json&apikey=\(alchemyKey!)"
    
    
    // Force KituraNet call to run synchronously on a global queue
    var str = "No response"
    dispatch_sync(dispatch_get_global_queue(0, 0)) {

            Http.get(url) { response in

                do {
                   str = try response!.readString()!
                } catch {
                    print("Error \(error)")
                }

            }
    }

    // Assume string is JSON
    print("Got string \(str)")
    var result:[String:Any]?

    // Convert to NSData
    let data = str.bridge().dataUsingEncoding(NSUTF8StringEncoding)!
    do {
        result = try NSJSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    } catch {
        print("Error \(error)")
    }

    // return, which should be a dictionary
    print("Result is \(result!)")
    return result!
}
