/**
 * Orchestration/workflow for image processing using OpenWhisk actions
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {
    
    var error:String = "";
    var returnValue:String = "";
    let imageId = args["imageId"] as? String ?? ""
    let targetNamespace = args["targetNamespace"] as? String ?? ""
    
    let cloudantReadInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/cloudantRead", withParameters: ["cloudantId": imageId])
    
    var document: JSON = [:]
    if let documentResponse = cloudantReadInvocation["response"] as? [String:Any],
        let documentPayload = documentResponse["result"] as? [String:Any],
        let documentString = documentPayload["document"] as? String,
        let documentData = documentString.data(using: String.Encoding.utf8, allowLossyConversion: true) {
        
        document = JSON(data: documentData)
    }
    
    // check if document was read from cloudant successfully
    // there *should not* be a value for documnet["error"] because if that key exists,
    // then there is an error message being returned from cloudant
    if (document.exists() && !document["error"].exists()) {
        
        // request data from weather & visual recognition services
        let location = document["location"]
        
        var weatherInvocation:[String:Any] = [:]
        if let latitude = location["latitude"].number,
            let longitude = location["longitude"].number {
            weatherInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/weather", withParameters: [
                "latitude": String(describing: latitude),
                "longitude": String(describing: longitude)
                ])
        }
        var visualInvocation:[String:Any] = [:]
        let imageURL = document["url"].string
        var imageURLUnwrapped:String = ""
        if let imageURLUnwrapped = imageURL {
            visualInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/visualRecognition", withParameters: [
                "imageURL": "\(imageURLUnwrapped)"
                ])
        }
        
        // parse weather data and update cloudant document
        var weather: JSON = [:]
        if let weatherResponse = weatherInvocation["response"] as? [String:Any],
            let weatherPayload = weatherResponse["result"] as? [String:Any],
            let weatherString:String = weatherPayload["weather"] as? String,
            let weatherData = weatherString.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            
            weather = JSON(data: weatherData)
        }
        
        // if the weather data exists without error, add it to the cloudant document, otherwise don't add it
        if (weather.exists() && !weather["error"].exists()) {
            let observation = weather["observation"]
            var newWeather:JSON = [:]
            newWeather["iconId"] = observation["icon_code"]
            newWeather["description"] = observation["sky_cover"]
            newWeather["temperature"] = observation["imperial"]["temp"]
            document["location"]["weather"] = newWeather
        }
        
        // parse visual recognition data and update cloudant document
        var visualRecognition: JSON = [:]
        if let visualResponse = visualInvocation["response"] as? [String:Any],
            let visualPayload = visualResponse["result"] as? [String:Any],
            let visualString:String = visualPayload["visualRecognition"] as? String,
            let visualData = visualString.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            
            visualRecognition = JSON(data: visualData)
        }
        
        document["tags"] = visualRecognition
        
        var writeJSON: JSON = [:]
        if var documentUnwrapped = document.rawString() {

            // write the results back to cloudant
            let cloudantWriteInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/cloudantWrite", withParameters: [
                "cloudantId": imageId,
                "cloudantBody": documentUnwrapped
                ])
            if let writeResponse = cloudantWriteInvocation["response"] as? [String:Any],
                let writePayload = writeResponse["result"] as? [String:Any],
                let writeResultString:String = writePayload["cloudantResult"] as? String,
                let writeData = writeResultString.data(using: String.Encoding.utf8, allowLossyConversion: true) {
                
                writeJSON = JSON(data: writeData)
            }
            
        }
        
        if (writeJSON.exists() && !writeJSON["error"].exists()) {
            if(writeJSON["ok"] != true) {
                error = "Error writing to Cloudant"
            }
            else {
                // obtain auth credentials for callback to kitura
//                let kituraAuthInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/kituraRequestAuth", withParameters: [:])
                
//                if let authResponse: [String:Any] = kituraAuthInvocation["response"] as? [String:Any],
//                    let authPayload: [String:Any] = authResponse["result"] as? [String:Any],
//                    let authHeaderPayload = authPayload["authHeader"],
//                    let authHeader = authHeaderPayload as? String {
//                    if (authHeader.isEmpty) {
//                        error = "Unable to obtain auth header from Kitura"
//                    }
                    let kituraCallbackInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace)/bluepic/kituraCallback", withParameters: [
                        "authHeader": "",
                        "cloudantId": imageId
                        ])
                    
                    if let callbackResponse = kituraCallbackInvocation["response"] as? [String:Any],
                        let callbackPayload = callbackResponse["result"] as? [String:Any],
                        let callbackResponseString = callbackPayload["response"] as? String {
                        
                        returnValue = "Processed request through callback to kitura with server response: \(callbackResponseString)"
                    }
//                }
            }
        }
        
    } else {
        error = "Unable to fetch document from Cloudant"
    }
    
    var result:[String:Any] = [
        "success":(error == ""),
        "response":returnValue
    ]
    if (error != "") {
        result["error"] = error;
    }
    
    return result
}
