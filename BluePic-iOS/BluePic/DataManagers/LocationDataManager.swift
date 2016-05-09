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
    
    private let locationManager = CLLocationManager()
    
    private let kImperialUnitOfMeasurement = "e"
    private let kMetricUnitOfMeasurement = "m"
    
    private var locationCallback : ((location : CLLocation?)->())!
    
    
    func getUnitOfMeasurement() -> String{
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
        
        locationManager.requestWhenInUseAuthorization()
        
    }
    
    func getUsersLocation(callback : ((location : CLLocation?)->())){
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationCallback = callback
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }

    }

   
}


extension LocationDataManager : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0]
        
        locationCallback(location: userLocation)
        
        locationManager.stopUpdatingLocation()
  
    }
    
    
    
}
