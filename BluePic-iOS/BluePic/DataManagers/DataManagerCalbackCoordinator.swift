/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit


//Used for notifiying view models when there are state updates from data managers
//Use example:
//DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
enum DataManagerNotification {
    
    //called when cloudant successfully pulls data
    case CloudantPullDataSuccess
    
    //called when cloudant fails at pulling data
    case CloudantPullDataFailure
    
    //called when cloudant successfully pushes data
    case CloudantPushDataSuccess
    
    //called when cloudant fails at pushing data
    case CloudantPushDataFailure
    
    //called when cloudant fails to create a picture
    case CloudantCreatePictureFailure
    
    //called when cloudant fails to create a profile
    case CloudantCreateProfileFailure
    
    //called when there was an object storage auth error
    case ObjectStorageAuthError
    
    //called when there was an object storage upload error
    case ObjectStorageUploadError
    
    //called when the app gets past the login check
    case GotPastLoginCheck
    
    //capped when the app checks user defaults to see if a user is already logged in, if its not , this notificaiton is sent
    case UserNotAuthenticated

    //called when the user decides to post a photo
    case UserDecidedToPostPhoto
    
    //called when the app stargts up 
    case StartLoadingAnimationForAppLaunch
}


class DataManagerCalbackCoordinator: NSObject {

    //make DataManagerCallbackCoordinator a singleton
    static let SharedInstance: DataManagerCalbackCoordinator = {
       
        var manager = DataManagerCalbackCoordinator()
        
        return manager
        
    }()
    
    
    //an array of all the view models that have "suscribed" to notifications
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
