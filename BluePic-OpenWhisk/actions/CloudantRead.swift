/**
 * read data from Cloudant 
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {

    let cloudantDbName: String? = args["cloudantDbName"] as? String
    let cloudantUsername: String? = args["cloudantUsername"] as? String
    let cloudantPassword: String? = args["cloudantPassword"] as? String
    let cloudantHost: String? = args["cloudantHost"] as? String
    let cloudantId: String? = String(args["cloudantId"]!)
    
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.username(cloudantUsername!))
    requestOptions.append(.password(cloudantPassword!))
    requestOptions.append(.schema("https://"))
    requestOptions.append(.hostname(cloudantHost!))
    requestOptions.append(.port(443))
    requestOptions.append(.method("GET"))
    requestOptions.append(.path("/\(cloudantDbName!)/\(cloudantId!)"))
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.headers(headers))
    
    var str = "" 
    let req = HTTP.request(requestOptions) { response in
        do {
            str = try response!.readString()!
        } catch {
            print("Error \(error)")
        }
    }
    req.end();
    
    let result:[String:Any] = [
        "document": str
    ]
    return result
}
