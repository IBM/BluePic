/**
 * Setup parameters for CloudantWrite action, for writing annotated image document (with alchemy and weather) back to Cloudant
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
    
    let imageId: String? = args["imageId"] as? String
    let imageDocString: String? = args["imageDoc"] as? String
    let alchemyResult: String? = args["alchemyResult"] as? String
    let weatherResult: String? = args["weatherResult"] as? String
    
    // Convert Strings to NSData
    let documentResultData = imageDocString!.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
    let alchemyResultData = alchemyResult!.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!
    let weatherResultData = weatherResult!.data(using: NSUTF8StringEncoding, allowLossyConversion: true)!

    var tags: [JSON] = [JSON]()
    
    // convert to JSON
    var documentResultJson = JSON(data: documentResultData)
    let alchemyResultJson = JSON(data: alchemyResultData)
    let weatherResultJson = JSON(data: weatherResultData)
    
    
    if let keywords:[JSON] = alchemyResultJson["imageKeywords"].arrayValue {

        for keyword in keywords {
            
            //this is weird syntax, but swift doesn't like me trying to cast directly (protocol errors)
            var strScore = keyword["score"].string!
            if strScore.characters.count <= 0 {
                strScore = "0"
            }
            var score:Double? = Double(strScore)
            score = score! * 100
            let iScore = Int(round(score!))
            
            var tag : JSON = [:]
            tag["label"] = keyword["text"]
            tag["confidence"].object = iScore
            
            tags.append(tag)
        }
        
    } else {
        print("JSON DID NOT PARSE")
    }
    
    let observation = weatherResultJson["observation"]
    
    var weather:JSON = [:]
    weather["iconId"] = observation["icon_code"]
    weather["description"] = observation["sky_cover"]
    weather["temperature"] = observation["imperial"]["temp"]
    
    documentResultJson["location"]["weather"] = weather
    
    documentResultJson["tags"] = JSON(tags)
    
    let result:[String:Any] = [
        "cloudantId": imageId,
        "cloudantBody": documentResultJson.rawString()
    ]
    
    return result
}