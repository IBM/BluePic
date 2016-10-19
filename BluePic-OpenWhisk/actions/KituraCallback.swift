/**
 * Callback to Kitura to invoke push notification
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
    
    let cloudantId: String = args["cloudantId"] as? String ?? ""
    let kituraHost: String = args["kituraHost"] as? String ?? ""
    let kituraPortInt: Int = args["kituraPort"] as? Int ?? 80
    let kituraPort: Int16 = Int16(kituraPortInt) as? Int16 ?? 80
    let kituraSchema: String = args["kituraSchema"] as? String ?? "http"
    let authHeader: String = args["authHeader"] as? String ?? ""
    
    var str = ""
    
    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema(kituraSchema),
                                                    .hostname(kituraHost),
                                                    .port(kituraPort),
                                                    .path("/push/images/\(cloudantId)")
    ]
    
    var requestHeaders = [String:String]()
    requestHeaders["Authorization"] = authHeader
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
    
    //workaround for JSON parsing defect in container
    str = str.replacingOccurrences(of: "\"", with: "\\\"")
    let result:[String:Any] = [
        "response": "\(str)"
    ]
    
    return result
}
