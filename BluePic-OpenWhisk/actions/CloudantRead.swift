/**
 * Stub code for reading data from Cloudant in a whisk action
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    let cloudantDbName: String? = args["cloudantDbName"] as? String
    let cloudantUsername: String? = args["cloudantUsername"] as? String
    let cloudantPassword: String? = args["cloudantPassword"] as? String
    let cloudantHost: String? = args["cloudantHost"] as? String
    let cloudantId: String? = args["cloudantId"] as? String
    
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.Username(cloudantUsername!))
    requestOptions.append(.Password(cloudantPassword!))
    requestOptions.append(.Schema("https://"))
    requestOptions.append(.Hostname(cloudantHost!))
    requestOptions.append(.Port(443))
    requestOptions.append(.Method("GET"))
    requestOptions.append(.Path("/\(cloudantDbName!)/\(cloudantId!)"))
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.Headers(headers))
    
    var str = "" 
    dispatch_sync(dispatch_get_global_queue(0, 0)) {
        let req = Http.request(requestOptions) { response in
            do {
                str = try response!.readString()!
            } catch {
                print("Error \(error)")
            }
        }
        req.end();
    }
    
    var cloudantResult:[String:Any]?
    
    // Convert to NSData
    let data = str.bridge().dataUsingEncoding(NSUTF8StringEncoding)
     do {
        cloudantResult = try NSJSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
    } catch {
        print("Error \(error)")
    }
    
    let result:[String:Any] = [
        "cloudantResult": cloudantResult!
    ]
    return result
}
