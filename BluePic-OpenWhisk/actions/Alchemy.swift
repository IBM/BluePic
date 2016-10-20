/**
 * Run alchemy analysis
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import AlchemyVision

func main(args:[String:Any]) -> [String:Any] {
    
    var str = ""
    var result:[String:Any] = [
        "alchemy": str
    ]
    
    guard let alchemyKey = args["alchemyKey"] as? String,
        let imageURL = args["imageURL"] as? String else {
            return result
    }
    
    let alchemyVision = AlchemyVision(apiKey: alchemyKey)
    let failure = { (error: RestError) in print(error) }
    
    alchemyVision.getRankedImageKeywords(url: imageURL,
                                         forceShowAll: true,
                                         knowledgeGraph: true,
                                         failure: failure) { response in
                                            
                                            
                                            response.imageKeywords
                                            for keyword:ImageKeyword in response.imageKeywords {
                                                if !NSString(string: keyword.text).contains("NO_TAGS")  {
                                                    if (str.characters.count > 0) {
                                                        str = str + ","
                                                    }
                                                    str += "{\"label\":\"\(keyword.text)\",\"confidence\":\(keyword.score)}"
                                                }
                                            }
    }
    
    str = "[\(str)]"
    
    //workaround for JSON parsing defect in container
    str = str.replacingOccurrences(of: "\"", with: "\\\"")
    
    result = [
        "alchemy": "\(str)"
    ]
    
    return result
}
