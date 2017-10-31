/**
 * Run Watson Visual Recognition image analysis
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

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
            if let response = response, let responseStr = try response.readString(),
            let dataResponse = responseStr.data(using: String.Encoding.utf8, allowLossyConversion: true) {

                let jsonObj = JSON(data: dataResponse)

                if let imageClasses = jsonObj["images"][0]["classifiers"][0]["classes"].array {
                	for imageClass in imageClasses {
                		
                		if let label = imageClass["class"].string, let confidence = imageClass["score"].double {
                			if (str.characters.count > 0) {
   		                    	str = str + ","
                            }
                			str += "{\"label\":\"\(label)\",\"confidence\":\(confidence)}"
                		}
                	}
                }
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