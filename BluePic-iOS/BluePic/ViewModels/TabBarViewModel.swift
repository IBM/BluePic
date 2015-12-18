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


class TabBarViewModel: NSObject {

    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false
    
    //callback that allows the tab bar view model to send DataManagerNotifications to the tab bar VC
    var passDataNotificationToTabBarVCCallback : ((dataManagerNotification : DataManagerNotification)->())!
    
    //state variable that keeps track of if we've already presented the default logic vc, used to help make sure we are showing the loading animation at the right time
    var didPresentDefaultLoginVC = false
    
    //state variable that keeps track of if we've successfully pulled data yet, used to help make sure we are showing the loading animation at the right time
    var hasSuccessFullyPulled = false
    
    
    /**
     Method called upon init, it sets up the callback
     
     - parameter passDataNotificationToTabBarVCCallback: ((dataManagerNotification: DataManagerNotification)->())
     
     - returns:
     */
    init(passDataNotificationToTabBarVCCallback : ((dataManagerNotification: DataManagerNotification)->())){
        super.init()
        
        self.passDataNotificationToTabBarVCCallback = passDataNotificationToTabBarVCCallback
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleDataManagerNotifications)
        
    }
    
    
    /**
     Method tells the FacebookDataManager to tryToShowLoginScreen
     */
    func tryToShowLogin(){
        
        if(!hasTriedToPresentLoginThisAppLaunch){
           
            hasTriedToPresentLoginThisAppLaunch = true
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
        }
    }
    
    
    /**
     Method is called when there are new DataManagerNotifications, we mostly pass these notifications the the tabBarVC
     
     - parameter dataManagerNotification: DataManagerNotification
     */
    func handleDataManagerNotifications(dataManagerNotification : DataManagerNotification){
        
        if(dataManagerNotification == DataManagerNotification.CloudantPullDataSuccess){
            hasSuccessFullyPulled = true
        }
        
       passDataNotificationToTabBarVCCallback(dataManagerNotification: dataManagerNotification)
    }
    
    
    /**
     Method tells the feed to start the loading animation
     */
    func tellFeedToStartLoadingAnimation(){
        if(didPresentDefaultLoginVC == true && hasSuccessFullyPulled == false){
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.StartLoadingAnimationForAppLaunch)
            didPresentDefaultLoginVC = false
        }
        
    }
    

    /**
     Method retry pushing cloudant data upon error
     */
    func retryPushingCloudantData(){
        do {
            try CloudantSyncDataManager.SharedInstance!.pushToRemoteDatabase()
        } catch {
            print("retryPushingCloudantData ERROR: \(error)")
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataFailure)
        }
    }
    
    
    /**
     Method retry pulling cloudant data upon error
     */
    func retryPullingCloudantData() {
        //CloudantSyncDataManager.SharedInstance.pullReplicator.stop()
        do {
            try CloudantSyncDataManager.SharedInstance!.pullFromRemoteDatabase()
        } catch {
            print("Retry pulling error: \(error)")
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
        }
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to pull Cloudant data")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
            
        }
    }
    
    
    /**
     Method retry authenticating with object storage upon error
     */
    func retryAuthenticatingObjectStorage() {
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to authenticate with Object Storage")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
            
        }
    }
  
}
