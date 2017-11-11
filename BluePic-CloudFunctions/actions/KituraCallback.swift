/**
 * Callback to Kitura to invoke push notification
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var result: [String:Any] = [
        "response": str
    ]

    guard let cloudantId: String = args["cloudantId"] as? String,
        let kituraHost: String = args["kituraHost"] as? String,
        let kituraPortInt: Int = args["kituraPort"] as? Int,
        let authHeader: String = args["authHeader"] as? String else {

            print("Error: missing a required parameter for the Kitura callback action.")
            return result
    }

    let kituraSchema: String = args["kituraSchema"] as? String ?? "http"

    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema(kituraSchema),
                                                    .hostname(kituraHost),
                                                    .port(Int16(kituraPortInt)),
                                                    .path("/push/images/\(cloudantId)")
    ]

    var requestHeaders = [String: String]()
    requestHeaders["Authorization"] = authHeader
    requestHeaders["Content-Length"] = "0"
    requestOptions.append(.headers(requestHeaders))

    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp {
            str = "HTTP \(resp.status)"
        } else {
            str = "Status error code or nil reponse received from Kitura server."
        }
    }
    req.end("--request body (ignore this value)--")

    result = [
        "response": "\(str)"
    ]

    return result
}
