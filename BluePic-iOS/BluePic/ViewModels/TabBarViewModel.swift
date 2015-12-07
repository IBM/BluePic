//
//  TabBarViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/7/15.
//  Copyright © 2015 MIL. All rights reserved.
//


enum AppStartUpResult {
    case showObjectStorageErrorAlert
    case hideBackgroundImageAndStartLoading
    case stopLoadingImageView
    case showCloudantPushingErrorAlert
    case showCloudantPullingErrorAlert
    case presentLoginVC
}



class TabBarViewModel: NSObject {

    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false
    
    var handleErrorStatesUponAppStartUpCallback : ((appStartUpResult : AppStartUpResult)->())!
    
    
    init(handleErrorStatesUponAppStartUpCallback : ((appStartUpResult : AppStartUpResult)->())){
        super.init()
        
        self.handleErrorStatesUponAppStartUpCallback = handleErrorStatesUponAppStartUpCallback
        
    }
    
    
    
    func tryToShowLogin(callback : ((userInteractionEnabled : Bool)->())){
        
        if(!hasTriedToPresentLoginThisAppLaunch){
            callback(userInteractionEnabled: false)
            
            hasTriedToPresentLoginThisAppLaunch = true
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(handleAppStartUpResult)
            
            
        }
    }
    
    
    
    
    
    func handleAppStartUpResult(appStartUpResult : AppStartUpResult){
        
       handleErrorStatesUponAppStartUpCallback(appStartUpResult: appStartUpResult)
  
    }
    
    
    
    
    
    /**
     Retry pushing cloudant data upon error
     */
    func retryPushingCloudantData(){
         CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
    }
    
    
    /**
     Retry pulling cloudant data upon error
     */
    func retryPullingCloudantData() {
        //CloudantSyncClient.SharedInstance.pullReplicator.stop()
        CloudantSyncClient.SharedInstance.pullFromRemoteDatabase()
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to pull Cloudant data")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self.handleAppStartUpResult)
            
        }
    }
    
    
    /**
     Retry authenticating with object storage upon error
     */
    func retryAuthenticatingObjectStorage() {
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to authenticate with Object Storage")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self.handleAppStartUpResult)
            
        }
        
    }
    
    
    
    func getHasTriedToPresentLoginThisAppLaunch() -> Bool{
        
        return hasTriedToPresentLoginThisAppLaunch
        
    }
    
    
    func setHasTriedToPresentLoginThisAppLaunchToTrue(){
        
        hasTriedToPresentLoginThisAppLaunch = true
        
    }

    
 
    
}
