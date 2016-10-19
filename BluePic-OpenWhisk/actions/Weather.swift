/**
 * fetch current weather observation from weather service
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import WeatherCompanyData

func main(args: [String:Any]) -> [String:Any] {
    
    let weatherUsername = args["weatherUsername"] as? String ?? ""
    let weatherPassword = args["weatherPassword"] as? String ?? ""
    
    var latitude = args["latitude"] as? String ?? "0.0"
    var longitude = args["longitude"] as? String ?? "0.0"
    var language = args["language"] as? String ?? "en-US"
    var units = args["units"] as? String ?? "e"
    
    var str = ""
    
    let weatherCompanyData = WeatherCompanyData(username: "\(weatherUsername)", password: "\(weatherPassword)")
    let failure = { (error: RestError) in
        print(error)
    }
    
    weatherCompanyData.getCurrentForecast(
        units: "\(units)",
        latitude:"\(latitude)",
        longitude: "\(longitude)",
        language: "\(language)",
        failure: failure) { response in
        
        let icon_code = response.observation.icon_code
        let sky_cover = response.observation.sky_cover
        
        var temp: Int = 0
        if let measurement = response.observation.measurement {
            temp = measurement.temp
        }
        
        str = "{ \"observation\":{" +
            "\"icon_code\":\(icon_code)," +
            "\"sky_cover\":\"\(sky_cover)\"," +
            "\"imperial\":{\"temp\":\(temp)}" +
        "}}"
    }
    
    //workaround for JSON parsing defect in container
    str = str.replacingOccurrences(of: "\"", with: "\\\"")
    let result:[String:Any] = [
        "weather": "\(str)"
    ]
    
    return result
}
