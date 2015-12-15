/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit


// Use example:
// DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
enum DataManagerNotification {
    
    case CloudantPullDidChangeState
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
    
    func addCallback(callback : ((dataManagerNotification : DataManagerNotification)->())){
        
        callbacks.append(callback)
        
    }
    
    

    
    func sendNotification(dataManagerNotification : DataManagerNotification){
        
        for callback in callbacks {
            
            callback(dataManagerNotification: dataManagerNotification)
            
        }
    }
    
    
    
    
    
    

}
