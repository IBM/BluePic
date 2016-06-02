/**
 * Callback to Kitura to invoke push notification
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
       
       
    let cloudantId: String? = String(args["cloudantId"]!)
    let kituraHost: String? = args["kituraHost"] as? String
    let kituraPortInt:Int? = args["kituraPort"] as? Int
    let kituraPort:Int16 = Int16(kituraPortInt!)
    let kituraSchema: String? = args["kituraSchema"] as? String
    let authHeader: String? = String(args["authHeader"]!)
    
    
    var str = "" 
    
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.schema(kituraSchema!))
    requestOptions.append(.hostname(kituraHost!))
    requestOptions.append(.port(kituraPort))
    requestOptions.append(.method("POST"))
    requestOptions.append(.path("/push/images/\(cloudantId!)"))
    
    var requestHeaders = [String:String]()
    requestHeaders["Authorization"] = authHeader!
    requestHeaders["Content-Length"] = "0"
    requestOptions.append(.headers(requestHeaders))
    
    
    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp {
            str = "HTTP \(resp.status)"
        }
        else {
            str = "Status error code or nil reponse received from Kitura server."
        }
    }
    req.end("--request body (ignore this value)--");
    
    let result:[String:Any] = [
        "imageId":  args["cloudantId"],
        "response": "\(str)"
    ]
    
    return result
}
