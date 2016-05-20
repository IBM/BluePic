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
    dispatch_sync(dispatch_get_global_queue(0, 0)) {

        Http.get("https://\(weatherUsername!):\(weatherPassword!)@twcservice.mybluemix.net/api/weather/v2/observations/current?geocode=\(latitude!),\(longitude!)&language=\(language!)&units=\(units!)") { response in

            do {
                str = try response!.readString()!
            } catch {
                print("Error \(error)")
            }

        }
    }
    
    let result:[String:Any] = [
        "userId":  args["userId"],
        "userDoc": args["userDoc"],
        "imageId":  args["userId"],
        "imageDoc": args["imageDoc"],
        "alchemyResult": args["alchemyResult"],
        "weatherResult": "\(str)",
        "language": args["language"],
        "units":  args["units"],
        "latitude": args["latitude"],
        "longitude": args["longitude"],
        "imageURL": args["imageURL"]
    ]
    
    // return, which should be a dictionary
    return result
}
