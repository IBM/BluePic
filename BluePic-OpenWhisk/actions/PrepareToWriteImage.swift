/**
 * Setup parameters for CloudantWrite action, for writing annotated image document (with alchemy and weather) back to Cloudant
 */

import KituraNet
import Dispatch
import Foundation
import SwiftyJSON

func main(args:[String:Any]) -> [String:Any] {
    
    var imageId: String? = args["imageId"] as? String
    var imageDocString: String? = args["imageDoc"] as? String
    var alchemyResult: String? = args["alchemyResult"] as? String
    var weatherResult: String? = args["weatherResult"] as? String
    
    
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
            
            //print( keyword["score"].string )
            //print( keyword["text"].string )
            
            //this is weird syntax, but swift doesn't like me trying to cast directly (protocol errors)
            var strScore = keyword["score"].string!
            if strScore.characters.count <= 0 {
                strScore = "0"
            }
            var score:Double? = Double(strScore)
            score = score! * 100
            var iScore = Int(round(score!))
            
            var tag : JSON = [:]
            tag["label"] = keyword["text"]
             tag["confidence"].object = iScore
            
            tags.append(tag)
           /* [
                "label":keyword["text"].string!,
                "confidence":iScore
            ])*/
        }
        
        print(tags)
        
    } else {
        print("JSON DID NOT PARSE")
    }
    
    
        let observation = weatherResultJson["observation"]
        /*let skyCover = weatherResultJson["observation"]["sky_cover"].string
        
        //let temp = weatherResultJson["observation"]["imperial"]["temp"].string
        
        print(iconCode)
        print(skyCover)
        //print(temp)
        */
        print(weatherResultJson.rawString())
        
        /*return [
            "iconCode": observation["icon_code"].rawString()!,
            "skyCover": observation["sky_cover"].rawString()!,
            "temp": observation["imperial"]["temp"].rawString()!
        ]*/
        
        
    var location = documentResultJson["location"]
    
    location["iconId"] = observation["icon_code"]
    location["description"] = observation["sky_cover"]
    location["temperature"] = observation["imperial"]["temp"]
    
        documentResultJson["tags"] = JSON(tags)
    
    
    
    
    let result:[String:Any] = [
        "imageId":  imageId,
        "cloudantId": imageId,
        "cloudantBody": documentResultJson.rawString()
    ]
    
    
    return result
    
    
    /*
    var imageDoc:[String:Any]? = convert(input:imageDocString!) 
    var alchemyDoc:[String: Any]? = convert(input:alchemyResult!)
    var weather:[String: Any]? = convert(input:weatherResult!)
    
    var imageKeywords = alchemyDoc!["imageKeywords"]
    
    if let keywords = imageKeywords {
    
        var tags:[[String:Any]] = [[String:Any]]()
        
        for keyword in keywords as! [Any] {
            
            var kw = keyword as? [String:Any]
            //this is weird syntax, but swift doesn't like me trying to cast directly (protocol errors)
            var strScore = "\(kw!["score"]!)"
            if strScore.characters.count <= 0 {
                strScore = "0"
            }
            var score:Double? = Double(strScore)
            score = score! * 100
            var iScore = round(score!)
            
            //Swift won't let me put an Int here, so casting to Double
            tags.append([
                "label":kw!["text"],
                "confidence":Double(iScore)
            ])
        }
        
        imageDoc!["tags"] = tags
    }
    
    var observation:[String:Any]? = weather!["observation"] as? [String:Any]
    if let observed = observation {
        
        let iconCode = observed["icon_code"]
        let skyCover = observed["sky_cover"]
        
        let imperial:[String:Any]? = observed["imperial"] as? [String:Any] 
        let temp = imperial!["temp"]   
        
        var location:[String:Any]? = imageDoc!["location"] as? [String:Any] 
        location!["weather"] = [
            "iconId":iconCode,
            "description":skyCover,
            "tetemperaturemp":temp
        ]
    }
    
    let result:[String:Any] = [
        "userId":  args["userId"],
        "imageId":  args["userId"],
        "cloudantId":imageId,
        "cloudantBody": imageDoc!
    ]

    // return, which should be a dictionary
    return result*/
}
/*
func convert(input:String) -> [String: Any]? {
    
    var result:[String:Any]?
    let data = input.bridge().dataUsingEncoding(NSUTF8StringEncoding)
     do {
        result = try NSJSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
    } catch {
        print("Error \(error)")
    }
    
    return result;
}
*/