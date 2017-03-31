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

    case showLoginVC
    case hideLoginVC
    case switchToFeedTab
    case showImageUploadFailureAlert
    case logOutSuccess
    case logOutFailure
    case showSettingsActionSheet

}

class TabBarViewModel: NSObject {

    //callback that allows the tab bar view model to send event notifications to the tabbar vc
    fileprivate var notifyTabBarVC: ((_ tabBarViewModelNotification: TabBarViewModelNotification) -> Void)!

    /**
     Method called upon init, it sets up the callback method to send notifications ot the tabbar vc

     - parameter passDataNotificationToTabBarVCCallback: ((dataManagerNotification: DataManagerNotification)->())

     - returns:
     */
    init(notifyTabBarVC : @escaping (_ tabBarViewModelNotification: TabBarViewModelNotification) -> Void) {
        super.init()

        self.notifyTabBarVC = notifyTabBarVC

        suscribeToBluemixDataManagerNotifications()
    }

    /**
     Method suscribes to event notifications sent from the BluemixDataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(TabBarViewModel.notifyTabBarVCToSwitchToFeedTab), name: .imageUploadBegan, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(TabBarViewModel.notifyTabbarVCToShowImageUploadFailureAlert), name: .imageUploadFailure, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(TabBarViewModel.notifyTabBarVcToShowSettingsActionSheet), name: .showSettingsActionSheet, object: nil)

    }

    /**
     Method notifies the tab bar vc to swift to the feed tab when image upload begins
     */
    func notifyTabBarVCToSwitchToFeedTab() {
        notifyTabBarVC(TabBarViewModelNotification.switchToFeedTab)
    }

    /**
     Method notifies the tab bar vc to show the image upload failure alert when an image fails to upload
     */
    func notifyTabbarVCToShowImageUploadFailureAlert() {
        notifyTabBarVC(TabBarViewModelNotification.showImageUploadFailureAlert)
    }

    /**
     Method notifies the tab bar vc to show the settings action sheet
     */
    func notifyTabBarVcToShowSettingsActionSheet() {
        notifyTabBarVC(TabBarViewModelNotification.showSettingsActionSheet)
    }

    /**
     Method notifies the tab bar vc that log out was a success
     */
    func notifyTabBarVCLogOutSuccess() {
        notifyTabBarVC(TabBarViewModelNotification.logOutSuccess)
    }

    /**
     Method notifies the tab bar vc that log in was a failure
     */
    func notifyTabBarVCLogOutFailure() {
        notifyTabBarVC(TabBarViewModelNotification.logOutFailure)
    }

    /**
     Method tries to show the login when the tab bar vc view did appear. It will show the login if the user isn't authenticated or hasn't pressed sign in later
     */
    func tryToShowLogin() {

        if LoginDataManager.SharedInstance.isUserAuthenticatedOrPressedSignInLater() {
            notifyTabBarVC(TabBarViewModelNotification.hideLoginVC)
        } else {
            notifyTabBarVC(TabBarViewModelNotification.showLoginVC)
        }

    }

    /**
     Method returns true if the user pressed login later, false if the user didn't

     - returns: Bool
     */
    func isUserAuthenticated() -> Bool {

        return LoginDataManager.SharedInstance.isUserAlreadyAuthenticated()

    }

    /**
     Method tells the BluemixDataManager to retry uploading images that failed to upload
     */
    func tellBluemixDataManagerToRetryUploadingImagesThatFailedToUpload() {
        DispatchQueue.main.async {
            BluemixDataManager.SharedInstance.retryUploadingImagesThatFailedToUpload()
        }
    }

    /**
     Method tells BluemisDataManager to cancel uploading images that failed to upload
     */
    func tellBluemixDataManagerToCancelUploadingImagesThatFailedToUpload() {
        DispatchQueue.main.async {
            BluemixDataManager.SharedInstance.cancelUploadingImagesThatFailedToUpload()
        }

    }

    /**
     Method logs out the user by calling the LoginDataManager's LogOut method
     */
    func logOutUser() {

        LoginDataManager.SharedInstance.logOut({ success in

            if success {
                self.notifyTabBarVCLogOutSuccess()
            } else {
                self.notifyTabBarVCLogOutFailure()
            }
        })

    }

}
