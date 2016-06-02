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
   
    let mcaAuthToken = "Bearer eyJhbGciOiJSUzI1NiIsImpwayI6eyJhbGciOiJSU0EiLCJleHAiOiJBUUFCIiwibW9kIjoiQUkzT2YyZFd5VnVwY183OHY3WVl6WXRpZ05mZ083ZHdxYmtscHZQaE5MYWpOR1ROdWRfc1Nqb2x0QWJCVnFCZFRpYmMybDNXUmlWUzJSWUxkbnhidG9jRkNka0cyLWJLdC0xNWNVM1VFTW5QeGw5TW9Rc2U1cXlJMEVzcFVkelh4RjY1dVNEeUR2VnhvekFXZkdocXNMSUE0THlOV1phU1dOUERWUzhxelc4Zi1HUjlfb3ZIaGhXVEZWRzlCQ3JwV0VqTGZDaTFSWEREWWY3MXkzQ0tQUXY4RzYxSGZBQVMwRC1zMndEbC1mUGZJTDlHQUdnS29LSnQ5T0V6VlRwakt0cW5YNHNxeWUyVXZhWm5FYkRtUDdVTGtpSGtCdlUwSEhwNmM1cnF6QlFxUGxyNGhiYVhPM3JDZW5DNl80Ml9lZDEyNEYxWjVCS21WVmo3NUYzckpROCJ9fQ.eyJleHAiOjE5NjAzMTE2ODgsImF1ZCI6IjJmZTM1NDc3LTUxYjAtNGM4Ny04MDNkLWFjYTU5NTExNDMzYiIsImlzcyI6Imh0dHA6XC9cL2FibXMubXlibHVlbWl4Lm5ldDo4MFwvaW1mLWF1dGhzZXJ2ZXJcL2F1dGhvcml6YXRpb25cLyIsInBybiI6IjYzODA4MDJkZjZkZjlhNzAzODA2MzVjMDA4MmJmOTEzMjA1MTc2ZTAifQ.UDLdkoCDcM9i3k1QR4NGVbJr2O7vic2v1PRKxetNF-ToOink-zQFfMLtHOIgfxxrI65hbo4b_jYYr4LHaryZNis3bb5YUbtfmH3EFkrp_UHQZVZ_X9OTQnA3zAu_VjDyB0ta8zMPHS3nXZfjqHg_WlPy2WpkfUh94Jwpj5l39mVKFOA3FyD6KPOv_DJQ3STiMBP62kJ9jYGyrURZJPFlAJ48ktiPPWQ9zms0x_lQLjGVkoIt8-SDy1n1pT3mfKhvie7unQbZUDdSSgoJnLEaFTO4LzBwn6b4TtQhSmEV_OjFqinOuTeqwYOZIpaqjGRD8h_0PeChcWCnXXwwuXyC5g eyJhbGciOiJSUzI1NiIsImpwayI6eyJhbGciOiJSU0EiLCJleHAiOiJBUUFCIiwibW9kIjoiQUkzT2YyZFd5VnVwY183OHY3WVl6WXRpZ05mZ083ZHdxYmtscHZQaE5MYWpOR1ROdWRfc1Nqb2x0QWJCVnFCZFRpYmMybDNXUmlWUzJSWUxkbnhidG9jRkNka0cyLWJLdC0xNWNVM1VFTW5QeGw5TW9Rc2U1cXlJMEVzcFVkelh4RjY1dVNEeUR2VnhvekFXZkdocXNMSUE0THlOV1phU1dOUERWUzhxelc4Zi1HUjlfb3ZIaGhXVEZWRzlCQ3JwV0VqTGZDaTFSWEREWWY3MXkzQ0tQUXY4RzYxSGZBQVMwRC1zMndEbC1mUGZJTDlHQUdnS29LSnQ5T0V6VlRwakt0cW5YNHNxeWUyVXZhWm5FYkRtUDdVTGtpSGtCdlUwSEhwNmM1cnF6QlFxUGxyNGhiYVhPM3JDZW5DNl80Ml9lZDEyNEYxWjVCS21WVmo3NUYzckpROCJ9fQ.eyJleHAiOjE0NjAzMTE2ODgsInN1YiI6Ijo6NjM4MDgwMmRmNmRmOWE3MDM4MDYzNWMwMDgyYmY5MTMyMDUxNzZlMCIsImltZi5hcHBsaWNhdGlvbiI6eyJpZCI6ImNvbS5teS5hcHAiLCJ2ZXJzaW9uIjoiMS4wIn0sImltZi51c2VyIjp7ImlkIjoiMTAwMyIsImF1dGhCeSI6ImltZi1hdXRoc2VydmVyIiwiZGlzcGxheU5hbWUiOiJ0ZXN0VXNlciBkaXNwbGF5IiwiYXR0cmlidXRlcyI6eyJmb28iOiJiYXIifX0sImF1ZCI6IjJmZTM1NDc3LTUxYjAtNGM4Ny04MDNkLWFjYTU5NTExNDMzYiIsImlzcyI6Imh0dHA6XC9cL2FibXMubXlibHVlbWl4Lm5ldDo4MFwvaW1mLWF1dGhzZXJ2ZXJcL2F1dGhvcml6YXRpb25cLyIsImlhdCI6MTQ2MDMwODA4OCwiaW1mLmRldmljZSI6eyJpZCI6IjMwMDMiLCJwbGF0Zm9ybSI6IkFuZHJvaWQiLCJtb2RlbCI6IkFuZHJvaWQgU0RLIGJ1aWx0IGZvciB4ODZfNjQiLCJvc1ZlcnNpb24iOiI2LjAifX0.aNSzQB16G9WPv8z1Q5nFyyQAvX5P-llkqmfOJiyO51krzFTiBZCx3WeqqnRA4Hd_ltQAReAq5JYp0ZHo0bN0qtdEeJBGXsR9PGj4uWWCFV1AQrZBBdZfn_Y_6MqkQng4k3VJh3896y3FBAB5qiubAuNt2-7WP-NOAAq-k_3myvyqOwkIcgqnlyCZ_TnayigSwBuiGnfMQ8AUl6vO05UuqGWhuaZNzduW826wI6P8_sjGZLv8f_ZTf5v2WHiK1RhEN-VnbQMV6nMDRtMS9n4M7KiFcGXkQn3KRsfYCTxtia0yXpaReACHm3mJt5xTNmunQ0tr62d49Quqhd0aoTqvHA"
    
    
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
            //pushRequestHeaders["Authorization"] = "Bearer \(authJson["access_token"].string!)"
            pushRequestHeaders["Authorization"] = mcaAuthToken
            pushRequestHeaders["Content-Length"] = "0"
            pushRequestOptions.append(.headers(pushRequestHeaders))
            
            let pushReq = HTTP.request(pushRequestOptions) { pushResponse in
                do {
                    try pushStr = "\(pushResponse!.status)"
                } catch {
                    pushStr = "Error \(error)"
                }
            }
            pushReq.end("--request body (ignore this value)--");
            
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
