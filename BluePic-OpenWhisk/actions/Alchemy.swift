/**
 * Run alchemy analysis
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import AlchemyVision

func main(args:[String:Any]) -> [String:Any] {
       
    let alchemyKey: String? = args["alchemyKey"] as? String
    let imageURL: String? = args["imageURL"] as? String


    let alchemyVision = AlchemyVision(apiKey: alchemyKey!)
    let failure = { (error: RestError) in print(error) }

    var str = ""
    alchemyVision.getRankedImageKeywords(url: imageURL!, 
                                            forceShowAll: true, 
                                            knowledgeGraph: true, 
                                            failure: failure) { response in 


        response.imageKeywords
        for keyword:ImageKeyword in response.imageKeywords {
            if !NSString(string: keyword.text).contains("NO_TAGS")  {
                if (str.characters.count > 0) {
                    str = str + ","
                }
                str += "{\"text\":\"\(keyword.text)\",\"score\":\(keyword.score)}"
            }
        }
    }

    str = "[\(str)]"
    
    let result:[String:Any] = [
        "alchemy": "\(str)",
    ]
    
    return result
}
