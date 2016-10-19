/**
 * write data to Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    
    let cloudantDbName: String = args["cloudantDbName"] as? String ?? ""
    let cloudantUsername: String = args["cloudantUsername"] as? String ?? ""
    let cloudantPassword: String = args["cloudantPassword"] as? String ?? ""
    let cloudantHost: String = args["cloudantHost"] as? String ?? ""
    var cloudantBody: String = args["cloudantBody"] as? String ?? ""
    
    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema("https://"),
                                                    .hostname(cloudantHost),
                                                    .username(cloudantUsername),
                                                    .password(cloudantPassword),
                                                    .port(443),
                                                    .path("/\(cloudantDbName)/")
    ]
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))
    
    var str = ""
    if (cloudantBody == "") {
        str = "Error: Unable to serialize cloudantBody parameter as a String instance"
    }
    else {
        let requestData:Data? = cloudantBody.data(using: String.Encoding.utf8, allowLossyConversion: true)
        
        if let data = requestData {
            
            let req = HTTP.request(requestOptions) { response in
                do {
                    if let responseUnwrapped = response {
                        if let responseStr = try responseUnwrapped.readString() {
                            str = responseStr
                        }
                    }
                } catch {
                    print("Error \(error)")
                }
            }
            req.end(data);
        }
    }
    
    //workaround for JSON parsing defect in container
    str = str.replacingOccurrences(of: "\"", with: "\\\"")
    let result:[String:Any] = [
        "cloudantId": args["cloudantId"],
        "cloudantResult": str
    ]
    
    return result
}
