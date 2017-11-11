/**
 * write data to Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var result: [String:Any] = [
        "cloudantId": str,
        "cloudantResult": str
    ]

    guard let cloudantDbName = args["cloudantDbName"] as? String,
        let cloudantUsername = args["cloudantUsername"] as? String,
        let cloudantPassword = args["cloudantPassword"] as? String,
        let cloudantHost = args["cloudantHost"] as? String,
        let cloudantBody = args["cloudantBody"] as? String,
        let cloudantId = args["cloudantId"] as? String else {

            print("Error: missing a required parameter for writing a Cloudant document.")
            return result
    }

    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema("https://"),
                                                    .hostname(cloudantHost),
                                                    .username(cloudantUsername),
                                                    .password(cloudantPassword),
                                                    .port(443),
                                                    .path("/\(cloudantDbName)/")
    ]

    var headers = [String: String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))

    if (cloudantBody == "") {
        str = "Error: Unable to serialize cloudantBody parameter as a String instance"
    } else {
        let requestData: Data? = cloudantBody.data(using: String.Encoding.utf8, allowLossyConversion: true)

        if let data = requestData {

            let req = HTTP.request(requestOptions) { response in
                do {
                    if let responseUnwrapped = response,
                        let responseStr = try responseUnwrapped.readString() {
                        str = responseStr
                    }
                } catch {
                    print("Error \(error)")
                }
            }
            req.end(data)
        }
    }

    result = [
        "cloudantId": cloudantId,
        "cloudantResult": str
    ]

    return result
}
