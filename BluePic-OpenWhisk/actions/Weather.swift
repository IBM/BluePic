/**
 * fetch current weather observation from weather service
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {

    let weatherUsername: Any? = args["weatherUsername"]
    let weatherPassword: Any? = args["weatherPassword"]
    
    var latitude: Any? = args["latitude"]
    var longitude: Any? = args["longitude"]
    var language: Any? = args["language"]
    var units: Any? = args["units"]
    
    if latitude == nil {
        latitude = "0.0"
    }
    if longitude == nil {
        longitude = "0.0"
    }
    if language == nil {
        language = "en-US"
    }
    if units == nil {
        units = "e"
    }
    
    var str = ""

    HTTP.get("https://\(weatherUsername!):\(weatherPassword!)@twcservice.mybluemix.net/api/weather/v2/observations/current?geocode=\(latitude!),\(longitude!)&language=\(language!)&units=\(units!)") { response in

        do {
            str = try response!.readString()!
        } catch {
            print("Error \(error)")
            str = "Error \(error)"
        }
    }
    
    let result:[String:Any] = [
        "imageId":  args["imageId"],
        "imageDoc": args["imageDoc"],
        "alchemyResult": args["alchemyResult"],
        "weatherResult": "\(str)",
        "latitude": args["latitude"],
        "longitude": args["longitude"],
        "imageURL": args["imageURL"]
    ]
    
    return result
}
