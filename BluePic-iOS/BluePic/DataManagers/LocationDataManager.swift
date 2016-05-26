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
    
    case GetCurrentLatLongCityAndStateFailure
    
}

let kImperialUnitOfMeasurement = "e"
let kMetricUnitOfMeasurement = "m"

class LocationDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: LocationDataManager = {
        
        var manager = LocationDataManager()
        
        return manager
        
    }()
    
    override init() {
        super.init()
        self.setupLocationManager()
    }
    
    private var locationManager : CLLocationManager!
    
    private var isLocationServicesEnabledAndIfNotHandleItCallback : ((isEnabled : Bool)->())!
    private var getUsersCurrentLocationCallback : ((location : CLLocation?)->())!
    
    func getUnitsOfMeasurement() -> String{
        let locale = NSLocale.currentLocale()
        
        if let isMetricString = locale.objectForKey(NSLocaleUsesMetricSystem),
            let isMetricBool = isMetricString.boolValue {
        
            if(isMetricBool){
                return kMetricUnitOfMeasurement
            }
            else{
                return kImperialUnitOfMeasurement
            }
 
        }
        else{
            return kImperialUnitOfMeasurement
        }
    }
    
    
    private func setupLocationManager(){
         dispatch_async(dispatch_get_main_queue()) {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer//kCLLocationAccuracyNearestTenMeters
        }
    }
    
    
    func getLanguageLocale() -> String {
        return NSLocale.preferredLanguages()[0]
    }
    
    
    func requestWhenInUseAuthorization(){
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(){
        self.locationManager.startUpdatingLocation()
    }
    

    func requestLocation(){
        locationManager.requestLocation()
    }
    

    
    func isLocationServicesEnabledAndIfNotHandleIt(callback : ((isEnabled : Bool) -> ())){
        
        isLocationServicesEnabledAndIfNotHandleItCallback = callback
        
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways){
      
            //self.locationManager.requestLocation()
            isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: true)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        }
        else if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied){
            isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: false)
            isLocationServicesEnabledAndIfNotHandleItCallback = nil
        }
        else if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined){
            dispatch_async(dispatch_get_main_queue()) {
            self.requestWhenInUseAuthorization()
            }
        }

    }
    
    
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    
    private func getUsersCurrentLocation(callback : (location : CLLocation?)-> ()){
        
        getUsersCurrentLocationCallback = callback
        locationManager.requestLocation()
        
    }
    
    private func getPlaceMarkFromLocation(location : CLLocation, callback : ((placemark : CLPlacemark?)->())){
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            print(location)
            
            //failure
            if let error = error {
                print("Reverse geocoder failed with error" + error.localizedDescription)
                callback(placemark: nil)
            
            }
            else if let placemarks = placemarks {
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
            else{
                callback(placemark: nil)
            }
            
            
        })

    }
    
    
    
    func getCurrentLatLongCityAndState(callback : ((latitude : CLLocationDegrees?, longitude : CLLocationDegrees?, city : String?, state : String?, error : LocationDataManagerError?)->())){
        
        getUsersCurrentLocation(){ location in
            
            if let location = location {
                
                self.getPlaceMarkFromLocation(location, callback: { placemark in
                    
                        //success
                        if let placemark = placemark, let city = placemark.locality, let state = placemark.administrativeArea {
                            callback(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, city: city, state: state, error: nil)
                        }
                        //failure
                        else{
                            callback(latitude: nil, longitude: nil, city: nil, state: nil, error: LocationDataManagerError.GetCurrentLatLongCityAndStateFailure)
                        }

                })
            }
            //failure
            else{
                callback(latitude: nil, longitude: nil, city: nil, state: nil, error: LocationDataManagerError.GetCurrentLatLongCityAndStateFailure)
            }
        }
    
    }

}


extension LocationDataManager : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        print("did update location")
        if(getUsersCurrentLocationCallback != nil){
            //success
            if(locations.count > 0){
                let location = locations[0]
                getUsersCurrentLocationCallback(location : location)
                getUsersCurrentLocationCallback = nil
            }
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print(error)
        
        if(getUsersCurrentLocationCallback != nil){
            getUsersCurrentLocationCallback(location : nil)
            getUsersCurrentLocationCallback = nil
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    
        if(status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways){
            if(isLocationServicesEnabledAndIfNotHandleItCallback != nil){
                isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: true)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        }
        else if(status == CLAuthorizationStatus.Denied){
            if(isLocationServicesEnabledAndIfNotHandleItCallback != nil){
                isLocationServicesEnabledAndIfNotHandleItCallback(isEnabled: false)
                isLocationServicesEnabledAndIfNotHandleItCallback = nil
            }
        }
 
    }
  
}
