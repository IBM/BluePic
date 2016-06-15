/**
 * fetch current weather observation from weather service
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import InsightsForWeather

func main(args: [String:Any]) -> [String:Any] {

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

    let insightsForWeather = InsightsForWeather(username: "\(weatherUsername!)", password: "\(weatherPassword!)")
    let failure = { (error: RestError) in 
        print(error) 
    }
    insightsForWeather.getCurrentForecast(
            units: "\(units!)",
            geocode: "\(latitude!),\(longitude!)",
            language: "\(language!)",
            failure: failure) { response in

        let icon_code = response.observation.icon_code 
        let sky_cover = response.observation.sky_cover!
        let temp = response.observation.measurement!.temp

        str = "{ \"observation\":{" + 
            "\"icon_code\":\(icon_code)," + 
            "\"sky_cover\":\"\(sky_cover)\"," + 
            "\"imperial\":{\"temp\":\(temp)}" + 
        "}}"
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
