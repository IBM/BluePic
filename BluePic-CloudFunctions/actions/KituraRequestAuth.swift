/**
 * Get auth credentials from App ID service for calling to Kitura
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var headerValue = ""
    var result: [String:Any] = [
        "authResponse": str,
        "authHeader": headerValue
    ]

    guard let appIdClientId: String = args["appIdClientId"] as? String,
        let appIdSecret: String = args["appIdSecret"] as? String else {

            print("Error: missing a required parameter for the KituraRequestAuth action.")
            return result
    }

    //first get App ID auth token
    let baseStr = "\(appIdClientId):\(appIdSecret)"

    let utf8BaseStr = baseStr.data(using: String.Encoding.utf8)
    guard let authHeader = utf8BaseStr?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) else {
        print("Error: Could not generate authHeader")
        return result
    }

    let appGuid = appIdClientId

    var requestOptions: [ClientRequest.Options] = [ .method("POST"),
                                                    .schema("http://"),
                                                    .hostname("imf-authserver.ng.bluemix.net"),
                                                    .port(80),
                                                    .path("/imf-authserver/authorization/v1/apps/\(appGuid)/token")
    ]

    var headers = [String: String]()
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    headers["Authorization"] = "Basic \(authHeader)"
    requestOptions.append(.headers(headers))

    // Body required for getting App ID token
    let requestBody = "grant_type=client_credentials"

    // Make REST call
    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp, resp.statusCode == HTTPStatusCode.OK {
            do {
                if let responseStr = try resp.readString() {
                    str = responseStr

                    let authData = str.data(using: String.Encoding.utf8, allowLossyConversion: true)

                    if let authDataUnwrapped = authData {
                        let authJson = JSON(data: authDataUnwrapped)
                        if let token = authJson["access_token"].string {
                            headerValue = "Bearer \(token)"
                        }
                    }
                }
            } catch {
                str = "Error \(error)"
            }
        } else {
            str = "Status error code or nil reponse received from App ID server."
        }
    }
    req.end(requestBody)

    result = [
        "authResponse": "\(str)",
        "authHeader": "\(headerValue)"
    ]

    return result
}
