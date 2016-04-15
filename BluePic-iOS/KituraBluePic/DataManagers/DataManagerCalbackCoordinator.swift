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
//DataManagerCalbackCoordinator.SharedInstance.sendNotification(.PhotosUploadSuccess)
enum DataManagerNotification {
    
    //called when the user chooses to cancel uploading picture to object storage/cloudant when there is a failure uploading to object storage
    case UserCanceledUploadingPhotos
    
    //called when the app gets past the login check
    case GotPastLoginCheck
    
    //capped when the app checks user defaults to see if a user is already logged in, if its not , this notificaiton is sent
    case UserNotAuthenticated

    //called when the user decides to post a photo
    case UserDecidedToPostPhoto
    
    //called when the app starts up 
    case StartLoadingAnimationForAppLaunch

    // called when photos are pulled successfuly
    case PhotosListSuccess([Picture])
    
    // called when there is an error in pulling of photos
    case PhotosListFailure(String)
    
    // called when photos are uploaded successfuly
    case PhotosUploadSuccess
    
    // called when there is an error in photo uploading
    case PhotosUploadFailure
    
    // called in the case of successfull attempt to connect to the server after its location in settings was changed
    case ServerConnectionSuccess
    
    // called in the case of successfull check of connection to the server
    case ServerConnectionChecked
    
    // called when an attempt to connect to the server fails
    case ServerConnectionFailure(String)
    
    case UserSignedOut
    
    case UserSignedIn
    
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
