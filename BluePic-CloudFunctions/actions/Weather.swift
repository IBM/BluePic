/**
 * fetch current weather observation from weather service
 */

import KituraNet
import Dispatch
import Foundation
import RestKit
import SwiftyJSON

func main(args: [String:Any]) -> [String:Any] {

    var str = ""
    var result: [String:Any] = [
        "weather": str
    ]

    guard   let username = args["weatherUsername"] as? String,
            let password = args["weatherPassword"] as? String,
            let latitude = args["latitude"] as? String,
            let longitude = args["longitude"] as? String else {

            str = "Error: missing a required parameter for retrieving weather data."
            return result
    }

    let language = args["language"] as? String ?? "en-US"
    let units = args["units"] as? String ?? "e"

    let requestOptions: [ClientRequest.Options] = [ .method("GET"),
                                                    .schema("https://"),
                                                    .hostname("twcservice.mybluemix.net"),
                                                    .username(username),
                                                    .password(password),
                                                    .path("/api/weather/v1/geocode/\(latitude)/\(longitude)/observations.json?language=\(language)")
    ]

    let req = HTTP.request(requestOptions) { response  in
        do {
            guard let response = response else {
                str = "No response was received from Weather Insights"
                return
            }

            var data = Data()
            _ = try response.read(into: &data)
            let json = SwiftyJSON.JSON(data: data)

            guard   let icon_code = json["observation"]["wx_icon"].int,
                    let sky_cover = json["observation"]["wx_phrase"].string else {

                str = "Unable to resolve sky cover and icon code weather response data"
                return
            }

            let temp = json["observation"]["temp"].int ?? 0


            str = "{ \"observation\":{" +
                    "\"icon_code\":\(icon_code)," +
                    "\"sky_cover\":\"\(sky_cover)\"," +
                    "\"imperial\":{\"temp\":\(temp)}" +
                    "}}"
        } catch {
            str = "Error \(error)"
        }
    }
    req.end()

    result = [
        "weather": "\(str)"
    ]

    return result
}
