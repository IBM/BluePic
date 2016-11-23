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

import UIKit
import SVProgressHUD

class TabBarViewController: UITabBarController {

    /// Image view to temporarily cover feed and content so it doesn't appear to flash when showing login screen
    var backgroundImageView: UIImageView!

    // A view model that will keep state and do all the data handling for the TabBarViewController
    var viewModel: TabBarViewModel!

    /**
     Method called upon view did load. It creates an instance of the TabBarViewModel, sets the tabBar tint color, adds a background image view, and sets its delegate
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setBackgroundColor(UIColor.white)

        viewModel = TabBarViewModel(notifyTabBarVC: handleTabBarViewModelNotifications)

        self.tabBar.tintColor = UIColor.white

        self.addBackgroundImageView()

        self.delegate = self

    }

    /**
     Method called upon view did appear, it trys to show the login vc

     - parameter animated: Bool
     */
    override func viewDidAppear(_ animated: Bool) {
        self.tryToShowLogin()
    }

    /**
     Method called as a callback from the OS when the app recieves a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
     Method adds image view so no flickering occurs before showing login.
     */
    func addBackgroundImageView() {

        self.backgroundImageView = UIImageView(frame: self.view.frame)
        self.backgroundImageView.image = UIImage(named: "login_background")
        self.view.addSubview(self.backgroundImageView)

    }

    /**
     Method trys to show the login by asking the viewModel to try to show login
     */
    func tryToShowLogin() {
        viewModel.tryToShowLogin()
    }

    /**
     Method hides the background image
     */
    func hideBackgroundImage() {

        //hide temp background image used to prevent flash animation
        self.backgroundImageView.isHidden = true
        self.backgroundImageView.removeFromSuperview()

    }

    /**
     Method to show the login VC with or without animation

     - parameter animated: Bool to determine if VC should be animated on presentation
     - parameter callback: callback for actions once presentation is done
     */
    func presentLoginVC(_ animated: Bool, callback: (()->())?) {

        if let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as? LoginViewController {

            self.present(loginVC, animated: animated, completion: { _ in

                self.hideBackgroundImage()
                print(NSLocalizedString("If MCA is configured, user needs to sign in with Facebook.", comment: ""))
                if let callback = callback {
                    callback()
                }
            })
        }
    }

    /**
     Method switches to the feed tab and pops the view controller stack to the first vc
     */
    func switchToFeedTabAndPopToRootViewController() {

        self.selectedIndex = 0
        if let feedNavigationVC = self.viewControllers?[0] as? FeedNavigationController {
            feedNavigationVC.popToRootViewController(animated: false)
        }
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }

}

extension TabBarViewController: UITabBarControllerDelegate {

    /**
     Method is called right when the user selects a tab. It expects a return value that tells the TabBarViewController whether it should select that tab or not. If the camera tab is selected, then we always return false and then call the handleCameraTabBeingSelected method. If the profile tab is selected, we return whatever the shouldShowProfileViewControllerAndHandleIfShouldnt method returns

     - parameter tabBarController: UITabBarController
     - parameter viewController:   UIViewController

     - returns: Bool
     */
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let _ = viewController as? CameraViewController { //if camera tab is selected, show camera picker
            handleCameraTabBeingSelected()
            return false
        } else if let _ = viewController as? ProfileNavigationController {
            return shouldShowProfileViewControllerAndHandleIfShouldnt()
        } else { //if feed selected, actually show it everytime
            return true
        }
    }

    /**
     Method is called when the profile tab is selected. If the user pressed login later, then we return false because we dont want to show the the user the profile vc and instead we want to present the login vc to the user. If the user didn't press login later, then we return true so the user is presented with the profile vc

     - returns: Bool
     */
    func shouldShowProfileViewControllerAndHandleIfShouldnt() -> Bool {
        if !viewModel.isUserAuthenticated() {
            presentLoginVC(true, callback: nil)
            return false
        } else {
            return true
        }
    }

    /**
     Method handles the camera tab being selected. If the user pressed login later, then we present to the user the login vc. If the user didn't press login later, then we check if location services had been enabled or not. If it has been enabled, we show them the image picker action sheet. Else we show the user the location services required alert
     */
    func handleCameraTabBeingSelected() {
            LocationDataManager.SharedInstance.isLocationServicesEnabledAndIfNotHandleIt({ isEnabled in

                if isEnabled {
                    CameraDataManager.SharedInstance.showImagePickerActionSheet(self)
                } else {
                    self.showLocationServiceRequiredAlert()
                }
            })
    }

    /**
     Method shows the location services required alert
     */
    func showLocationServiceRequiredAlert() {

        let alertController = UIAlertController(title: NSLocalizedString("Location Services Required", comment: ""), message: NSLocalizedString("Please go to Settings to enable Location Services for BluePic", comment: ""), preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let OKAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { (action) in

            if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsUrl)
            }

        }
        alertController.addAction(OKAction)

        self.present(alertController, animated: true, completion: nil)

    }

    /**
     Method to show the image upload failure alert
     */
    func showImageUploadFailureAlert() {

        let alert = UIAlertController(title: NSLocalizedString("Failed To Upload Image", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in

            self.viewModel.tellBluemixDataManagerToCancelUploadingImagesThatFailedToUpload()

        }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .default, handler: { (action: UIAlertAction) in

            self.viewModel.tellBluemixDataManagerToRetryUploadingImagesThatFailedToUpload()

        }))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }

    }


}

//ViewModel -> View Controller Communication
extension TabBarViewController {

    /**
     Method that handles tab bar view model notifications from the tab bar view model

     - parameter tabBarNotification: TabBarViewModelNotification
     */
    func handleTabBarViewModelNotifications(_ tabBarNotification: TabBarViewModelNotification) {

        if tabBarNotification == TabBarViewModelNotification.showLoginVC {
            presentLoginVC(false, callback: nil)
        } else if tabBarNotification == TabBarViewModelNotification.hideLoginVC {
            hideBackgroundImage()
        } else if tabBarNotification == TabBarViewModelNotification.switchToFeedTab {
            switchToFeedTabAndPopToRootViewController()
        } else if tabBarNotification == TabBarViewModelNotification.showImageUploadFailureAlert {
            showImageUploadFailureAlert()
        } else if tabBarNotification == TabBarViewModelNotification.showSettingsActionSheet {
            showSettingsActionSheet()
        } else if tabBarNotification == TabBarViewModelNotification.logOutSuccess {
            handleLogOutSuccess()
        } else if tabBarNotification == TabBarViewModelNotification.logOutFailure {
            handleLogOutFailure()
        }
    }

    /**
     Method shows the settings action sheet.
     */
    func showSettingsActionSheet() {

        let alert: UIAlertController=UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let cameraAction = UIAlertAction(title: NSLocalizedString("Log Out", comment: ""), style: UIAlertActionStyle.default) {
            UIAlertAction in

            SVProgressHUD.show()
            self.viewModel.logOutUser()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel) {
            UIAlertAction in
        }

        // Add the actions
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)

        // on iPad, this will be a Popover
        // on iPhone, this will be an action sheet
        alert.modalPresentationStyle = .popover


        // Present the controller
        self.present(alert, animated: true, completion: nil)
    }

    /**
     Method handles when logout was a success. It dismisses the SVProgressHUD, presents the login vc and then sets the tab bar selected index 0 (feed vc)
     */
    func handleLogOutSuccess() {
        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            self.presentLoginVC(true, callback: {
                self.selectedIndex = 0
            })
        }
    }

    /**
     Method hanldes when logout was a failure. It presents an alert, alerting the user that there was a log out failure
     */
    func handleLogOutFailure() {
        let alert = UIAlertController(title: NSLocalizedString("Log Out Failure", comment: ""), message: NSLocalizedString("Please Try Again", comment: ""), preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action: UIAlertAction) in

        }))

        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }

    }

}
