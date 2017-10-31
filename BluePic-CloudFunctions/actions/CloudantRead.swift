/**
 * read data from Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var result: [String:Any] = [
        "document": str
    ]

    guard let cloudantDbName = args["cloudantDbName"] as? String,
        let cloudantHost = args["cloudantHost"] as? String,
        let cloudantUsername = args["cloudantUsername"] as? String,
        let cloudantPassword = args["cloudantPassword"] as? String,
        let cloudantId = args["cloudantId"] as? String else {

            print("Error: missing a required parameter for reading a Cloudant document.")
            return result
    }

    var requestOptions: [ClientRequest.Options] = [ .method("GET"),
                                                    .schema("https://"),
                                                    .hostname(cloudantHost),
                                                    .username(cloudantUsername),
                                                    .password(cloudantPassword),
                                                    .port(443),
                                                    .path("/\(cloudantDbName)/\(cloudantId)")
    ]

    var headers = [String: String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))

    let req = HTTP.request(requestOptions) { response in
        do {
            if let response = response,
                let responseStr = try response.readString() {
                str = responseStr
            }
        } catch {
            print("Error: \(error)")
        }
    }
    req.end()

    result = [
        "document": str
    ]

    return result
}
