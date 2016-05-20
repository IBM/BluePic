/**
 * Setup parameters for CloudantWrite action, for writing annotated image document (with alchemy and weather) back to Cloudant
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {
    
    var imageId: String? = args["imageId"] as? String
    var imageDocString: String? = args["imageDoc"] as? String
    var alchemyResult: String? = args["alchemyResult"] as? String
    var weatherResult: String? = args["weatherResult"] as? String
    
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
    return result
}

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
