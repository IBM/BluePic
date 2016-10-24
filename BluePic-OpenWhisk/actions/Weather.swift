/**
 * fetch current weather observation from weather service
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import WeatherCompanyData

func main(args: [String:Any]) -> [String:Any] {
    
    var str = ""
    var result:[String:Any] = [
        "weather": str
    ]
    
    guard let weatherUsername = args["weatherUsername"] as? String,
        let weatherPassword = args["weatherPassword"] as? String,
        let latitude = args["latitude"] as? String,
        let longitude = args["longitude"] as? String else {
            
            print("Error: missing a required parameter for retrieving weather data.")
            return result
    }
    
    let language = args["language"] as? String ?? "en-US"
    let units = args["units"] as? String ?? "e"
    
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
    
    result = [
        "weather": "\(str)"
    ]
    
    return result
}
