/**
 * Callback to Kitura to invoke push notification
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
       
    let cloudantId: String? = String(args["cloudantId"]!)
    let mcaClientId: String? = args["mcaClientId"] as? String
    let mcaSecret: String? = args["mcaSecret"] as? String
    let kituraHost: String? = args["kituraHost"] as? String
    let kituraPortInt:Int? = args["kituraPort"] as? Int
    let kituraPort:Int16 = Int16(kituraPortInt!)
    let kituraSchema: String? = args["kituraSchema"] as? String
    
    
    var pushStr = "" 
    var authStr = ""
    
    //first get MCA auth token
    let baseStr = "\(mcaClientId!):\(mcaSecret!)"
    //print("baseStr: '\(baseStr)'")
    
    let utf8BaseStr = baseStr.data(using: NSUTF8StringEncoding)
    guard let authHeader = utf8BaseStr?.base64EncodedString(NSDataBase64EncodingOptions(rawValue: 0)) else {
        print("Could not generate authHeader...")
        return [
            "imageId":  args["cloudantId"],
            "response": "Could not generate authHeader..."
        ]
    }
    
    let appGuid = mcaClientId!
    //print("authHeader: '\(authHeader)'")
    //print("appGuid: '\(appGuid)'")

    // Request options
    var requestOptions = [ClientRequestOptions]()
    requestOptions.append(.method("POST"))
    requestOptions.append(.schema("http://"))
    requestOptions.append(.hostname("imf-authserver.ng.bluemix.net"))
    requestOptions.append(.port(80))
    requestOptions.append(.path("/imf-authserver/authorization/v1/apps/\(appGuid)/token"))
    
    var headers = [String:String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    headers["Authorization"] = "Basic \(authHeader)"
    requestOptions.append(.headers(headers))

    // Body required for getting MCA token
    let requestBody = "grant_type=client_credentials"

    // Make REST call
    let req = HTTP.request(requestOptions) { response in
    
        do {
            authStr = try response!.readString()!
            
            let authData = authStr.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
            let authJson = JSON(data: authData)
            
            var pushRequestOptions = [ClientRequestOptions]()
            pushRequestOptions.append(.schema(kituraSchema!))
            pushRequestOptions.append(.hostname(kituraHost!))
            pushRequestOptions.append(.port(kituraPort))
            pushRequestOptions.append(.method("POST"))
            pushRequestOptions.append(.path("/push/images/\(cloudantId!)"))
            
            var pushRequestHeaders = [String:String]()
            pushRequestHeaders["Authorization"] = authJson["access_token"].string!
            pushRequestOptions.append(.headers(headers))
            
            pushStr = authJson["access_token"].string!
            
            let pushReq = HTTP.request(pushRequestOptions) { pushResponse in
                do {
                    pushStr = "OK" // try pushResponse!.readString()!
                } catch {
                    pushStr = "Error \(error)"
                }
            }
            pushReq.end();
            
        } catch {
            authStr = "Error \(error)"
        }
    }
    req.end(requestBody)
   
    
    let result:[String:Any] = [
        "imageId":  args["cloudantId"],
        "pushResponse": "\(pushStr)",
        "authResponse": "\(authStr)"
    ]
    
    return result
}
