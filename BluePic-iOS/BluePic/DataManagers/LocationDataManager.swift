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
    
    
    func requestWhenInUseAuthorizationAndStartUpdatingLocation(){
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    func getUsersCurrentLocation() -> CLLocation? {
        
        if CLLocationManager.locationServicesEnabled() {
          return locationManager.location
        }
        else{
           return nil
        }

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
    
    
    
}
