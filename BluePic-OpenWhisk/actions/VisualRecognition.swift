/**
 * Run Watson Visual Recognition image analysis
 */

import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var result:[String:Any] = [
        "visualRecognition": str
    ]

    guard let visualRecognitionKey = args["visualRecognitionKey"] as? String,
        let imageURL = args["imageURL"] as? String else {
            return result
    }

    var requestOptions: [ClientRequest.Options] = [ .method("GET"),
                                                    .schema("https://"),
                                                    .hostname("gateway-a.watsonplatform.net"),
                                                    .port(443),
                                                    .path("/visual-recognition/api/v3/classify?api_key=\(visualRecognitionKey)&url=\(imageURL)&version=2016-05-20")
    ]

    let req = HTTP.request(requestOptions) { response in
        do {
            if let response = response, let responseStr = try response.readString() {
                print("resp: \(responseStr)")
                str = responseStr
            }
        } catch {
            print("Error: \(error)")
        }
    }
    req.end();

	str = "[\(str)]"
    result = [
        "visualRecognition": str
    ]

    return result
}