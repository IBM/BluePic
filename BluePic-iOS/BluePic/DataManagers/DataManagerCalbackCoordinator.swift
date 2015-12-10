//
//  DataManagerCalbackCoordinator.swift
//  BluePic
//
//  Created by Alex Buck on 12/8/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit


// Use example:
// DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
enum DataManagerNotification {
    case CloudantPullDataSuccess
    case CloudantPullDataFailure
    case CloudantPushDataFailure
    case CloudantCreatePictureFailure
    case CloudantCreateProfileFailure
    case ObjectStorageAuthError
    case ObjectStorageUploadError
    case GotPastLoginCheck
    case UserNotAuthenticated
    case UserDecidedToPostPhoto
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
