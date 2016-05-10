/**
 * Stub code for requesting weather data from a whisk action
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {

    print("inside weather action")

    var latitude: Any? = args["latitude"]
    var longitude: Any? = args["longitude"]
    var language: Any? = args["language"]
    var units: Any? = args["units"]
    
    if latitude == nil {
        latitude = 0.0
    }
    if longitude == nil {
        longitude = 0.0
    }
    if language == nil {
        language = "en-US"
    }
    if units == nil {
        units = "e"
    }
    
    
    var weatherUsername: Any? = args["weatherUsername"]
    var weatherPassword: Any? = args["weatherPassword"]

    let url = "https://\(weatherUsername!):\(weatherPassword!)@twcservice.mybluemix.net/api/weather/v2/observations/current?geocode=\(latitude!),\(longitude!)&language=\(language!)&units=\(units!)"
    
    var str = ""
    var weather:[String:Any]?
    dispatch_sync(dispatch_get_global_queue(0, 0)) {
        Http.get(url) { response in
            do {
                str = try response!.readString()!
            } catch {
                print("Error \(error)")
            }
        }
    }
    
    /*
    // Convert to NSData
    let data = str.bridge().dataUsingEncoding(NSUTF8StringEncoding)!
    do {
        weather = try NSJSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    } catch {
        print("Error \(error)")
    }*/
    
    let result:[String:Any] = [
        "latitude": latitude,
        "longitude": longitude,
        "language": language,
        "units": units,
        "weather" : str
    ]
    
    // return, which should be a dictionary
    return result
}
