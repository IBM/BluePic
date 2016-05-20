/**
 * Sample code using the experimental Swift 3 runtime
 * with links to KituraNet and GCD
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {

    // Force KituraNet call to run synchronously on a global queue
    var str = "No response"
    dispatch_sync(dispatch_get_global_queue(0, 0)) {

            Http.get("https://gateway-a.watsonplatform.net/calls/url/URLGetRankedImageKeywords?url=http://i.telegraph.co.uk/multimedia/archive/03541/Barack-Obama-gets-_3541878k.jpg&outputMode=json&apikey=e74a1e5d8d81292aa8f203f1491203b9779b8975") { response in

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
