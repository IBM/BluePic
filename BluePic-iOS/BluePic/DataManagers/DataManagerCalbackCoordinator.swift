/**
 * Copyright IBM Corporation 2015
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
    
    //called when a picture doc is deleted from cloudant
    case CloudantDeletePictureDocSuccess
    
    case UserCanceledUploadingPhotos

    //called when the cloudant picture doc was successfully updated with the url from object storage
    case CloudantUpdatePictureDocWithURLSuccess
    
    //called when the cloudant picture doc failed to be updated with the url from object storage
    case CloudantUpdatePictureDocWithURLFailure
    
    case ObjectStorageUploadImageAndCloudantCreatePictureDocSuccess
    
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
