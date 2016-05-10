/**
 * Stub code for requesting weather data from a whisk action
 */

import KituraNet
import Dispatch
import Foundation

func main(args:[String:Any]) -> [String:Any] {

    let latitude: Any? = args["latitude"]
    let longitude: Any? = args["longitude"]
    let language: Any? = args["language"]
    let units: Any? = args["units"]

    let result:[String:Any] = [String:Any]()
    /* []
        "latitude": latitude,
        "longitude": longitude
    ]*/
    
    //here we should add logic to retrieve the weather forecast
    print("inside weather action")

    // return, which should be a dictionary
    return result
}
