/**
 * write data to Cloudant
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
    let cloudantBody: String? = args["cloudantBody"] as? String
    
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.Username(cloudantUsername!))
    requestOptions.append(.Password(cloudantPassword!))
    requestOptions.append(.Schema("https://"))
    requestOptions.append(.Hostname(cloudantHost!))
    requestOptions.append(.Port(443))
    requestOptions.append(.Method("POST"))
    requestOptions.append(.Path("/\(cloudantDbName!)/"))
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.Headers(headers))
    
    
    var str = "" 
    if let body = cloudantBody {
        let requestData:NSData? = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        if let data = requestData {
            
            dispatch_sync(dispatch_get_global_queue(0, 0)) {
                let req = Http.request(requestOptions) { response in
                    do {
                        str = try response!.readString()!
                    } catch {
                        print("Error \(error)")
                    }
                }
                req.end(data);
            }
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
