/**
 * write data to Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    
    let cloudantDbName: String? = args["cloudantDbName"] as? String
    let cloudantUsername: String? = args["cloudantUsername"] as? String
    let cloudantPassword: String? = args["cloudantPassword"] as? String
    let cloudantHost: String? = args["cloudantHost"] as? String
    let cloudantBody: String? = args["cloudantBody"] as? String
    
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.username(cloudantUsername!))
    requestOptions.append(.password(cloudantPassword!))
    requestOptions.append(.schema("https://"))
    requestOptions.append(.hostname(cloudantHost!))
    requestOptions.append(.port(443))
    requestOptions.append(.method("POST"))
    requestOptions.append(.path("/\(cloudantDbName!)/"))
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))
    
    
    var str = "" 
    if let body = cloudantBody {
        let requestData:NSData? = body.data(using: NSUTF8StringEncoding, allowLossyConversion: true)
        
        if let data = requestData {
            
            let req = HTTP.request(requestOptions) { response in
                do {
                    str = try response!.readString()!
                } catch {
                    print("Error \(error)")
                }
            }
            req.end(data);
        }
    }
    else {
        str = "Error: Unable to serialize cloudantBody parameter as a String instance"
    }
    
    let result:[String:Any] = [
        "cloudantId": args["cloudantId"],
        "cloudantResult": str
    ]
    return result
}
