//
//  TabBarViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/7/15.
//  Copyright © 2015 MIL. All rights reserved.
//


//enum AppStartUpResult {
//    case showObjectStorageErrorAlert
//    case hideBackgroundImageAndStartLoading
//    case stopLoadingImageView
//    case showCloudantPushingErrorAlert
//    case showCloudantPullingErrorAlert
//    case presentLoginVC
//}



class TabBarViewModel: NSObject {

    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false
    var handleErrorStatesUponAppStartUpCallback : ((dataManagerNotification : DataManagerNotification)->())!
    
    var feedViewModel : FeedViewModel!
    
    
    init(handleErrorStatesUponAppStartUpCallback : ((dataManagerNotification: DataManagerNotification)->())){
        super.init()
        
        self.handleErrorStatesUponAppStartUpCallback = handleErrorStatesUponAppStartUpCallback
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleAppStartUpResult)
        
    }
    
    
    
    func tryToShowLogin(){
        
        if(!hasTriedToPresentLoginThisAppLaunch){
           
            hasTriedToPresentLoginThisAppLaunch = true
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
            
        }
    }
    
    
    
    
    
    func handleAppStartUpResult(dataManagerNotification : DataManagerNotification){
        
       handleErrorStatesUponAppStartUpCallback(dataManagerNotification: dataManagerNotification)
  
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
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
            
        }
    }
    
    
    /**
     Retry authenticating with object storage upon error
     */
    func retryAuthenticatingObjectStorage() {
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to authenticate with Object Storage")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen()
            
        }
        
    }
    
    
    
    func getHasTriedToPresentLoginThisAppLaunch() -> Bool{
        
        return hasTriedToPresentLoginThisAppLaunch
        
    }
    
    
    func setHasTriedToPresentLoginThisAppLaunchToTrue(){
        
        hasTriedToPresentLoginThisAppLaunch = true
        
    }
    
    
    
//    func getFeedViewModel() -> FeedViewModel {
//        
//        if(feedViewModel == nil){
//            feedViewModel = FeedViewModel()
//            return feedViewModel
//        }
//        else{
//            
//            return feedViewModel
//        }
//    }
  
}
