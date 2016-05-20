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


enum TabBarViewModelNotification {
    
    case ShowLoginVC
    case HideLoginVC
    case SwitchToFeedTab
    
}


class TabBarViewModel: NSObject {
    
    //callback that allows the tab bar view model to send DataManagerNotifications to the tab bar VC
    var notifyTabBarVC: ((tabBarViewModelNotification: TabBarViewModelNotification)->())!
    
    
    /**
     Method called upon init, it sets up the callback
     
     - parameter passDataNotificationToTabBarVCCallback: ((dataManagerNotification: DataManagerNotification)->())
     
     - returns:
     */
    init(notifyTabBarVC : ((tabBarViewModelNotification: TabBarViewModelNotification)->())){
        super.init()
        
        self.notifyTabBarVC = notifyTabBarVC
        
        suscribeToBluemixDataManagerNotifications()
    }
    
    
    func suscribeToBluemixDataManagerNotifications(){
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabBarViewModel.notifyTabBarVCToSwitchToFeedTab), name: CameraDataManagerNotification.UserPressedPostPhoto.rawValue, object: nil)

    }
    
    
    func notifyTabBarVCToSwitchToFeedTab(){
        
        notifyTabBarVC(tabBarViewModelNotification : TabBarViewModelNotification.SwitchToFeedTab)
        
    }
    

    func tryToShowLogin(){

        if(LoginDataManager.SharedInstance.isUserAuthenticatedOrPressedSignInLater()){
            
            notifyTabBarVC(tabBarViewModelNotification: TabBarViewModelNotification.HideLoginVC)
        
        }
        else{
            notifyTabBarVC(tabBarViewModelNotification: TabBarViewModelNotification.ShowLoginVC)
        }
        
    }
    
    
    func didUserPressLoginLater() -> Bool {
        
       return CurrentUser.willLoginLater

    }
    
 
}
