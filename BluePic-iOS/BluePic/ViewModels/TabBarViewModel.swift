/**
 * Copyright IBM Corporation 2016
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
    case ShowImageUploadFailureAlert

}


class TabBarViewModel: NSObject {

    //callback that allows the tab bar view model to send event notifications to the tabbar vc
    private var notifyTabBarVC: ((tabBarViewModelNotification: TabBarViewModelNotification)->())!


    /**
     Method called upon init, it sets up the callback method to send notifications ot the tabbar vc

     - parameter passDataNotificationToTabBarVCCallback: ((dataManagerNotification: DataManagerNotification)->())

     - returns:
     */
    init(notifyTabBarVC : ((tabBarViewModelNotification: TabBarViewModelNotification)->())) {
        super.init()

        self.notifyTabBarVC = notifyTabBarVC

        suscribeToBluemixDataManagerNotifications()
    }


    /**
     Method suscribes to event notifications sent from the BluemixDataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabBarViewModel.notifyTabBarVCToSwitchToFeedTab), name: BluemixDataManagerNotification.ImageUploadBegan.rawValue, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TabBarViewModel.notifyTabbarVCToShowImageUploadFailureAlert), name: BluemixDataManagerNotification.ImageUploadFailure.rawValue, object: nil)

    }

    /**
     Method notifies the tab bar vc to swift to the feed tab when image upload begins
     */
    func notifyTabBarVCToSwitchToFeedTab() {
        notifyTabBarVC(tabBarViewModelNotification : TabBarViewModelNotification.SwitchToFeedTab)
    }

    /**
     Method notifies the tab bar vc to show the image upload failure alert when an image fails to upload
     */
    func notifyTabbarVCToShowImageUploadFailureAlert() {
        notifyTabBarVC(tabBarViewModelNotification : TabBarViewModelNotification.ShowImageUploadFailureAlert)
    }

    /**
     Method tries to show the login when the tab bar vc view did appear. It will show the login if the user isn't authenticated or hasn't pressed sign in later
     */
    func tryToShowLogin() {

        if LoginDataManager.SharedInstance.isUserAuthenticatedOrPressedSignInLater() {
            notifyTabBarVC(tabBarViewModelNotification: TabBarViewModelNotification.HideLoginVC)
        } else {
            notifyTabBarVC(tabBarViewModelNotification: TabBarViewModelNotification.ShowLoginVC)
        }

    }

    /**
     Method returns true if the user pressed login later, false if the user didn't

     - returns: Bool
     */
    func didUserPressLoginLater() -> Bool {

       return CurrentUser.willLoginLater

    }

    /**
     Method tells the BluemixDataManager to retry uploading images that failed to upload
     */
    func tellBluemixDataManagerToRetryUploadingImagesThatFailedToUpload() {
        dispatch_async(dispatch_get_main_queue()) {
            BluemixDataManager.SharedInstance.retryUploadingImagesThatFailedToUpload()
        }
    }

    /**
     Method tells BluemisDataManager to cancel uploading images that failed to upload
     */
    func tellBluemixDataManagerToCancelUploadingImagesThatFailedToUpload() {
        dispatch_async(dispatch_get_main_queue()) {
            BluemixDataManager.SharedInstance.cancelUploadingImagesThatFailedToUpload()
        }

    }


}
