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
    let imageId: String? = String(args["imageId"]!)
    let targetNamespace: String? = args["targetNamespace"] as? String

    let cloudantReadInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/cloudantRead", withParameters: ["cloudantId": imageId!])
    let response = cloudantReadInvocation["response"] as! [String:Any]
    let payload = response["result"] as! [String:Any]
    let documentString:String = payload["document"] as! String

    let documentData = documentString.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
    var document = JSON(data: documentData)

    // check if document was read from cloudant successfully
    // there *should not* be a value for documnet["error"] because if that key exists, 
    // then there is an error message being returned from cloudant
    if (document.exists() && !document["error"].exists()) {

        let location = document["location"]
        let imageUrl = document["url"].string

        // request data from weather & alchemy services
        let weatherInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/weather", withParameters: [
            "latitude": "\(location["latitude"].number!)",
            "longitude": "\(location["longitude"].number!)"
        ])

        let alchemyInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/alchemy", withParameters: [
            "imageURL": "\(imageUrl!)"
        ])

        // parse weather data and update cloudant document
        let weatherResponse = weatherInvocation["response"] as! [String:Any]
        let weatherPayload = weatherResponse["result"] as! [String:Any]
        let weatherString:String = weatherPayload["weather"] as! String
        let weatherData = weatherString.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
        let weather = JSON(data: weatherData)

        // if the weather data exists without error, add it to the cloudant document, otherwise don't add it
        if (weather.exists() && !weather["error"].exists()) {
            let observation = weather["observation"]
            var newWeather:JSON = [:]
            newWeather["iconId"] = observation["icon_code"]
            newWeather["description"] = observation["sky_cover"]
            newWeather["temperature"] = observation["imperial"]["temp"]
            document["location"]["weather"] = newWeather
        }

        // parse alchemy data and update cloudant document
        let alchemyResponse = alchemyInvocation["response"] as! [String:Any]
        let alchemyPayload = alchemyResponse["result"] as! [String:Any]
        let alchemyString:String = alchemyPayload["alchemy"] as! String
        let alchemyData = alchemyString.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
        let alchemy = JSON(data: alchemyData)
        document["tags"] = alchemy
        
        // write the results back to cloudant
        let cloudantWriteInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/cloudantWrite", withParameters: [
            "cloudantId": imageId!,
            "cloudantBody": document.rawString()
        ])
        let writeResponse = cloudantWriteInvocation["response"] as! [String:Any]
        let writePayload = writeResponse["result"] as! [String:Any]
        let writeResultString:String = writePayload["cloudantResult"] as! String
        let writeData = writeResultString.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
        let writeJSON = JSON(data: writeData)

        if (writeJSON.exists() && !writeJSON["error"].exists()) {
            if(writeJSON["ok"] != true) {
                error = "Error writing to Cloudant: \(writeResultString)"
            }
            else {
                // obtain auth credentials for callback to kitura
                let kituraAuthInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/kituraRequestAuth", withParameters: [:])
                let authResponse = kituraAuthInvocation["response"] as! [String:Any]
                let authPayload = authResponse["result"] as! [String:Any]
                let authHeader:String = authPayload["authHeader"] as! String
                
                if (authHeader.isEmpty) {
                    error = "Unable to obtain auth header from Kitura"
                }
                else {
                    let kituraCallbackInvocation = Whisk.invoke(actionNamed: "/\(targetNamespace!)/bluepic/kituraCallback", withParameters: [
                        "authHeader": authHeader,
                        "cloudantId": imageId!   
                    ])
                    let callbackResponse = kituraCallbackInvocation["response"] as! [String:Any]
                    let callbackPayload = callbackResponse["result"] as! [String:Any]
                    let callbackResponseString:String = callbackPayload["response"] as! String

                    returnValue = "Processed request through callback to kitura with server response: \(callbackResponseString)"
                }
            }
        }

    } else {
        error = "Unable to fetch document from Cloudant"
        if (document["error"].exists()) {
            error = "\(error): \(documentString)"
        }
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
