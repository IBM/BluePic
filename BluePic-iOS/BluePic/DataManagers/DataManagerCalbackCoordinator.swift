/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit


// Use example:
// DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
enum DataManagerNotification {
    
    case CloudantPullDataSuccess
    case CloudantPullDataFailure
    case CloudantPushDataSuccess
    case CloudantPushDataFailure
    case CloudantCreatePictureFailure
    case CloudantCreateProfileFailure
    case ObjectStorageAuthError
    case ObjectStorageUploadError
    case GotPastLoginCheck
    case UserNotAuthenticated
    case UserDecidedToPostPhoto
    case StartLoadingAnimationForAppLaunch
}


class DataManagerCalbackCoordinator: NSObject {

    static let SharedInstance: DataManagerCalbackCoordinator = {
       
        var manager = DataManagerCalbackCoordinator()
        
        return manager
        
    }()
    
    
    private var callbacks : [((dataManagerNotification : DataManagerNotification)->())]! = []
    
    
    /**
     Method adds a callback method to callback array
     
     - parameter callback: ((dataManagerNotification : DataManagerNotification)->())
     */
    func addCallback(callback : ((dataManagerNotification : DataManagerNotification)->())){
        
        callbacks.append(callback)
        
    }
    
    

    /**
     Method sends notifications to the callback methods of the callbacks array
     
     - parameter dataManagerNotification: DatsManagerNotification
     */
    func sendNotification(dataManagerNotification : DataManagerNotification){
        
        for callback in callbacks {
            
            callback(dataManagerNotification: dataManagerNotification)
            
        }
    }
    
    
    
    
    
    

}
