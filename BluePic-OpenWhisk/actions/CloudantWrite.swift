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
    requestOptions.append(.Method("POST"))
    requestOptions.append(.Path("/\(cloudantDbName!)/"))
    
    /*requestOptions.append(.Username("58ef911e-4f5c-4e16-b8f7-3c85eafb8bb1-bluemix"))
    requestOptions.append(.Password("10a7cd236fbbe7692eb81fe2f64d0e43384f70239afb9e9ed1b34381e9d75da6"))
    requestOptions.append(.Schema("https://"))
    requestOptions.append(.Hostname("58ef911e-4f5c-4e16-b8f7-3c85eafb8bb1-bluemix.cloudant.com"))
    requestOptions.append(.Port(443))
    requestOptions.append(.Method("POST"))
    requestOptions.append(.Path("/bluepic/"))*/
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    requestOptions.append(.Headers(headers))
    
    //todo get rid of hardcoded data and replace with actual values for insert
    //cloduant document JSON as string
    let requestBody:String = "{\"_id\":\"0ccd7c2b94e126d8f6d06016c449dc72\", \"_rev\": \"3-d0bf831fb4e2a7d9e539fa90ff3237e2\",\"foo\": \"bar2\"}"
    let requestData:NSData = requestBody.dataUsingEncoding(NSUTF8StringEncoding)!
    
    var str = "" 
    dispatch_sync(dispatch_get_global_queue(0, 0)) {
        let req = Http.request(requestOptions) { response in
            do {
                str = try response!.readString()!
            } catch {
                print("Error \(error)")
            }
        }
        req.end(requestData);
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
