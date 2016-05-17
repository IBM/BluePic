//
//  LocationDataManager.swift
//  BluePic
//
//  Created by Alex Buck on 5/9/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit
import CoreLocation

class LocationDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: LocationDataManager = {
        
        var manager = LocationDataManager()
        
        return manager
        
    }()
    
    private var locationManager : CLLocationManager!
    
    private let kImperialUnitOfMeasurement = "e"
    private let kMetricUnitOfMeasurement = "m"
    
    private var isLocationServicesEnabledAndIfNotHandleItCallback : ((isEnabled : Bool)->())!
    
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
    
    
    func getLanguageLocale() -> String {
        return NSLocale.preferredLanguages()[0]
    }
    
    
    func requestWhenInUseAuthorization(){
        initLocationManagerIfNil()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(){
        initLocationManagerIfNil()
        self.locationManager.startUpdatingLocation()
    }
    
    func initLocationManagerIfNil(){
        if(locationManager == nil){
            locationManager = CLLocationManager()
            self.locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }
    
    
    func getUsersCurrentLocation() -> CLLocation? {
        if CLLocationManager.locationServicesEnabled() {
            if(locationManager != nil){
                return locationManager.location
            }
            else{
                return nil
            }
        }
        else{
           return nil
        }
    }
    
    func isLocationServicesEnabledAndIfNotHandleIt(callback : ((isEnabled : Bool) -> ())){
        
        isLocationServicesEnabledAndIfNotHandleItCallback = callback
        
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways){
            self.startUpdatingLocation()
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
    
    
    func getPlaceMarkFromLocation(location : CLLocation, callback : ((placemark : CLPlacemark?)->())){
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                callback(placemark: nil)
            }
            
            if placemarks!.count > 0 {
                let placemark = placemarks![0]
                callback(placemark: placemark)
            }
            else {
                callback(placemark: nil)
                print("Problem with the data received from geocoder")
            }
        })

    }

}


extension LocationDataManager : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("did update")
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    
        if(status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways){
            if(isLocationServicesEnabledAndIfNotHandleItCallback != nil){
                self.startUpdatingLocation()
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
