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
    case getCurrentLatLongCityAndStateFailure

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
    fileprivate var locationManager: CLLocationManager!

    //callback to inform that location services has been enabled or denied
    fileprivate var isLocationServicesEnabledAndIfNotHandleItCallback : ((_ isEnabled: Bool)->())?

    //callback to return the user's current location
    fileprivate var getUsersCurrentLocationCallback : ((_ location: CLLocation?)->())?


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
        let locale = Locale.current

        if locale.usesMetricSystem {
            return kMetricUnitOfMeasurement
        } else {
            return kImperialUnitOfMeasurement
        }
    }

    /**
     Method setups up the locationManager property
     */
    fileprivate func setupLocationManager() {
         DispatchQueue.main.async {
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
        return Locale.preferredLanguages[0]
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
    func isLocationServicesEnabledAndIfNotHandleIt(_ callback : @escaping ((_ isEnabled: Bool) -> ())) {

        isLocationServicesEnabledAndIfNotHandleItCallback = callback

        guard let cb = isLocationServicesEnabledAndIfNotHandleItCallback else {
            print(NSLocalizedString("Something went wrong, isLocationServicesEnabledAndIfNotHandleItCallback shouldn't be nil in the isLocationServicesEnabledAndIfNotHandleIt method", comment: ""))

            return
        }

        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {

            cb(true)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            cb(false)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            DispatchQueue.main.async {
            self.requestWhenInUseAuthorization()
            }
        }
    }

    /**
     Method gets the user's current location by calling the locationManager's requestLocation method. When the CLLocationManagerDelegate methods didUpdateLocations or didFailWithError methods are called, the isLocationServicesEnabledAndIfNotHandleItCallback will be called with the result


     - parameter callback: (location : CLLocation?)-> ()
     */
    fileprivate func getUsersCurrentLocation(_ callback : @escaping (_ location: CLLocation?)-> ()) {

        getUsersCurrentLocationCallback = callback
        locationManager.requestLocation()

    }

    /**
     Method gets the location placemark from the location parameter. It will return the result in the callback parameter

     - parameter location: CLLocation
     - parameter callback: ((placemark : CLPlacemark?)->())
     */
    fileprivate func getPlaceMarkFromLocation(_ location: CLLocation, callback : @escaping ((_ placemark: CLPlacemark?)->())) {

        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            print(location)
            //failure
            if let error = error {
                print(NSLocalizedString("Get Placemark From Location Error: Reverse Geocode failed", comment: "") + " \(error.localizedDescription)")
                callback(nil)

            } else if let placemarks = placemarks {
                //success
                if placemarks.count > 0 {
                    let placemark = placemarks[0]
                    callback(placemark)
                }
                //failure
                else {
                    print(NSLocalizedString("Get Placemark From Location Error: Problem with the data received from geocoder", comment: ""))
                    callback(nil)
                }
            }
            //failure
            else {
                 print(NSLocalizedString("Get Placemark From Location Error", comment: ""))
                callback(nil)
            }


        })

    }


    /**
     Method gets the latitude, longitude, city and state from the user's current location. It will return the result in the callback parameter

     - parameter callback: ((latitude : CLLocationDegrees?, longitude : CLLocationDegrees?, city : String?, state : String?, error : LocationDataManagerError?)->())
     */
    func getCurrentLatLongCityAndState(_ callback : @escaping ((_ latitude: CLLocationDegrees?, _ longitude: CLLocationDegrees?, _ city: String?, _ state: String?, _ error: LocationDataManagerError?)->())) {

        getUsersCurrentLocation() { location in

            if let location = location {

                self.getPlaceMarkFromLocation(location, callback: { placemark in

                        //success
                        if let placemark = placemark, let city = placemark.locality, let state = placemark.administrativeArea {
                            callback(location.coordinate.latitude, location.coordinate.longitude, city, state, nil)
                        }
                        //failure
                        else {
                            print(NSLocalizedString("Get Current Lat Long City And State Error: Invalid Placemark", comment: ""))
                            callback(nil, nil, nil, nil, LocationDataManagerError.getCurrentLatLongCityAndStateFailure)
                        }
                })
            }
            //failure
            else {
                print(NSLocalizedString("Get Current Lat Long City And State Error: Invalid Location", comment: ""))

                callback(nil, nil, nil, nil, LocationDataManagerError.getCurrentLatLongCityAndStateFailure)
            }
        }
    }


    func invalidateGetUsersCurrentLocationCallback() {

        getUsersCurrentLocationCallback = nil

    }
}

extension LocationDataManager : CLLocationManagerDelegate {

    /**
     Method is called after the locationManager requests location and the locationManager was successful at getting the user's location. It will return the user's location by calling the getUsersCurrentLocationCallback

     - parameter manager:   CLLocationManager
     - parameter locations: [CLLocation]
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let callback = getUsersCurrentLocationCallback {
            //success
            if locations.count > 0 {
                let location = locations[0]
                callback(location)
                getUsersCurrentLocationCallback = nil
            }
        }
    }

    /**
     Method is called after the locationManager requests location and the locationManager failed at getting the user's location. It will return that there was an error by calling the getUsersCurrentLocationCallback

     - parameter manager: CLLocationManager
     - parameter error:   Error
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(NSLocalizedString("Get User's Current Location Error:", comment: "") + " \(error.localizedDescription)")
        if let callback = getUsersCurrentLocationCallback {
            callback(nil)
            getUsersCurrentLocationCallback = nil
        }

    }

    /**
     Method is called after the user has either authorized or denied location services. It will return the result of this authorization change by calling the isLocationServicedEnabledAndIfNotHandleItCallback.

     - parameter manager: CLLocationManager
     - parameter status:  CLAuthorizationStatus
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        if status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways {
            if let callback = isLocationServicesEnabledAndIfNotHandleItCallback {
                callback(true)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        } else if status == CLAuthorizationStatus.denied {
            if let callback = isLocationServicesEnabledAndIfNotHandleItCallback {
                callback(false)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        }
    }
}
