/**
 * Get auth credentials from MCA service for calling to Kitura
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
       
    let mcaClientId: String? = args["mcaClientId"] as? String
    let mcaSecret: String? = args["mcaSecret"] as? String
   
    var str = ""
    var headerValue = ""
    
    //first get MCA auth token
    let baseStr = "\(mcaClientId!):\(mcaSecret!)"
   
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
    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp where resp.statusCode == HTTPStatusCode.OK {
            do {
                str = try resp.readString()!
                
                let authData = str.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
                let authJson = JSON(data: authData)
                
                headerValue = "Bearer \(authJson["access_token"].string!)"
                
            
            } catch {
                str = "Error \(error)"
            }
        } else {
            str = "Status error code or nil reponse received from MCA server."
        }
    }
    req.end(requestBody)
   
    
    let result:[String:Any] = [
        "cloudantId":  args["cloudantId"],
        "authResponse": "\(str)",
        "authHeader": "\(headerValue)"
    ]
    
    return result
}
