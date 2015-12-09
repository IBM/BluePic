//
//  DataManagerCalbackCoordinator.swift
//  BluePic
//
//  Created by Alex Buck on 12/8/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit



enum DataManagerNotification {
    case CloudantPullDataSuccess
    case CloudantPullDataFailure
    case CloudantPushDataFailiure
    case ObjectStorageAuthError
    case GotPastLoginCheck
    case UserNotAuthenticated
    case UserUploadedNewPhoto
}


class DataManagerCalbackCoordinator: NSObject {

    static let SharedInstance: DataManagerCalbackCoordinator = {
       
        var manager = DataManagerCalbackCoordinator()
        
        return manager
        
    }()
    
    
    private var callbacks : [((dataManagerNotification : DataManagerNotification)->())]! = []
    
    func addCallback(callback : ((dataManagerNotification : DataManagerNotification)->())){
        
        callbacks.append(callback)
        
    }
    
    

    
    
    func sendNotification(dataManagerNotification : DataManagerNotification){
        
        for callback in callbacks {
            
            callback(dataManagerNotification: dataManagerNotification)
            
        }
    }
    
    
    
    
    
    

}
