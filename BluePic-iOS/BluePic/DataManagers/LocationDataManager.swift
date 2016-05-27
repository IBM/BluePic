/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import CoreLocation

enum LocationDataManagerError {

    //Error when there is a failure getting the latitude, logitude, city and state
    case GetCurrentLatLongCityAndStateFailure

}

//string that represents imperial unit of measurement
let kImperialUnitOfMeasurement = "e"

//string that represents metric unit of measurement
let kMetricUnitOfMeasurement = "m"


class LocationDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: LocationDataManager = {

        var manager = LocationDataManager()

        return manager

    }()

    //instance of the CLLocationManager class
    private var locationManager: CLLocationManager!

    //callback to inform that location services has been enabled or denied
    private var isLocationServicesEnabledAndIfNotHandleItCallback : ((isEnabled: Bool)->())!

    //callback to return the user's current location
    private var getUsersCurrentLocationCallback : ((location: CLLocation?)->())!


    /**
     Upon init, we call the setupLocationManager method

     - returns: LocationDataManager
     */
    override init() {
        super.init()
        self.setupLocationManager()
    }


    /**
     Method returns the user's unit of measurement

     - returns: String
     */
    func getUnitsOfMeasurement() -> String {
        let locale = NSLocale.currentLocale()

        if let isMetricString = locale.objectForKey(NSLocaleUsesMetricSystem),
            let isMetricBool = isMetricString.boolValue {

            if isMetricBool {
                return kMetricUnitOfMeasurement
            } else {
                return kImperialUnitOfMeasurement
            }

        } else {
            return kImperialUnitOfMeasurement
        }
    }

    /**
     Method setups up the locationManager property
     */
    private func setupLocationManager() {
         dispatch_async(dispatch_get_main_queue()) {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer//kCLLocationAccuracyNearestTenMeters
        }
    }

    /**
     Method returns the user's language locale

     - returns: String
     */
    func getLanguageLocale() -> String {
        return NSLocale.preferredLanguages()[0]
    }

    /**
     Method requests when in use location services (this will display an alert to the user to authorize location services)
     */
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /**
     Method triggers the locationManager to requestLocation
     */
    func requestLocation() {
        locationManager.requestLocation()
    }

    /**
     Method checks if location services is enabled. If it is then it returns true in the callback parameter. If location services isn't enabled then it calls the requestWhenInUseAuthorization. When the CLLocationManagerDelegate methods didUpdateLocations or didFailWithError methods are called, the isLocationServicesEnabledAndIfNotHandleItCallback will be called with the result

     - parameter callback: ((isEnabled : Bool) -> ())
     */
    func isLocationServicesEnabledAndIfNotHandleIt(callback : ((isEnabled: Bool) -> ())) {

        isLocationServicesEnabledAndIfNotHandleItCallback = callback

        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways {

            isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: true)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: false)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            dispatch_async(dispatch_get_main_queue()) {
            self.requestWhenInUseAuthorization()
            }
        }
    }

    /**
     Method gets the user's current location by calling the locationManager's requestLocation method. When the CLLocationManagerDelegate methods didUpdateLocations or didFailWithError methods are called, the isLocationServicesEnabledAndIfNotHandleItCallback will be called with the result


     - parameter callback: (location : CLLocation?)-> ()
     */
    private func getUsersCurrentLocation(callback : (location: CLLocation?)-> ()) {

        getUsersCurrentLocationCallback = callback
        locationManager.requestLocation()

    }

    /**
     Method gets the location placemark from the location parameter. It will return the result in the callback parameter

     - parameter location: CLLocation
     - parameter callback: ((placemark : CLPlacemark?)->())
     */
    private func getPlaceMarkFromLocation(location: CLLocation, callback : ((placemark: CLPlacemark?)->())) {

        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            print(location)

            //failure
            if let error = error {
                print("Reverse geocoder failed with error" + error.localizedDescription)
                callback(placemark: nil)

            } else if let placemarks = placemarks {
                //success
                if placemarks.count > 0 {
                    let placemark = placemarks[0]
                    callback(placemark: placemark)
                }
                //failure
                else {
                    callback(placemark: nil)
                    print("Problem with the data received from geocoder")
                }
            }
            //failure
            else {
                callback(placemark: nil)
            }


        })

    }


    /**
     Method gets the latitude, longitude, city and state from the user's current location. It will return the result in the callback parameter

     - parameter callback: ((latitude : CLLocationDegrees?, longitude : CLLocationDegrees?, city : String?, state : String?, error : LocationDataManagerError?)->())
     */
    func getCurrentLatLongCityAndState(callback : ((latitude: CLLocationDegrees?, longitude: CLLocationDegrees?, city: String?, state: String?, error: LocationDataManagerError?)->())) {

        getUsersCurrentLocation() { location in

            if let location = location {

                self.getPlaceMarkFromLocation(location, callback: { placemark in

                        //success
                        if let placemark = placemark, let city = placemark.locality, let state = placemark.administrativeArea {
                            callback(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, city: city, state: state, error: nil)
                        }
                        //failure
                        else {
                            callback(latitude: nil, longitude: nil, city: nil, state: nil, error: LocationDataManagerError.GetCurrentLatLongCityAndStateFailure)
                        }
                })
            }
            //failure
            else {
                callback(latitude: nil, longitude: nil, city: nil, state: nil, error: LocationDataManagerError.GetCurrentLatLongCityAndStateFailure)
            }
        }
    }
}

extension LocationDataManager : CLLocationManagerDelegate {

    /**
     Method is called after the locationManager requests location and the locationManager was successful at getting the user's location. It will return the user's location by calling the getUsersCurrentLocationCallback

     - parameter manager:   CLLocationManager
     - parameter locations: [CLLocation]
     */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        print("did update location")
        if getUsersCurrentLocationCallback != nil {
            //success
            if locations.count > 0 {
                let location = locations[0]
                getUsersCurrentLocationCallback(location : location)
                getUsersCurrentLocationCallback = nil
            }
        }
    }

    /**
     Method is called after the locationManager requests location and the locationManager failed at getting the user's location. It will return that there was an error by calling the getUsersCurrentLocationCallback

     - parameter manager: CLLocationManager
     - parameter error:   NSError
     */
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        if(getUsersCurrentLocationCallback != nil) {
            getUsersCurrentLocationCallback(location : nil)
            getUsersCurrentLocationCallback = nil
        }

    }

    /**
     Method is called after the user has either authorized or denied location services. It will return the result of this authorization change by calling the isLocationServicedEnabledAndIfNotHandleItCallback.

     - parameter manager: CLLocationManager
     - parameter status:  CLAuthorizationStatus
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        if status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways {
            if isLocationServicesEnabledAndIfNotHandleItCallback != nil {
                isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: true)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        } else if status == CLAuthorizationStatus.Denied {
            if isLocationServicesEnabledAndIfNotHandleItCallback != nil {
                isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: false)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        }
    }
}
