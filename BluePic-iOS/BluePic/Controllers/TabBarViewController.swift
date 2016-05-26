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

class TabBarViewController: UITabBarController {
    
    /// Image view to temporarily cover feed and content so it doesn't appear to flash when showing login screen
    var backgroundImageView: UIImageView!
    
    // A view model that will keep state and do all the data handling for the TabBarViewController
    var viewModel : TabBarViewModel!
    
    /**
     Method called upon view did load. It creates an instance of the TabBarViewModel, sets the tabBar tint color, adds a background image view, and sets its delegate
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = TabBarViewModel(notifyTabBarVC: handleTabBarViewModelNotifications)
        
        self.tabBar.tintColor = UIColor.whiteColor()
        
        self.addBackgroundImageView()
        
        self.delegate = self
        
    }
    
    /**
     Method called upon view did appear, it trys to show the login vc
     
     - parameter animated: Bool
     */
    override func viewDidAppear(animated: Bool) {
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
        self.backgroundImageView.hidden = true
        self.backgroundImageView.removeFromSuperview()
        
    }
    
    
    /**
     Method to show the login VC without animation
     */
    func presentLoginVC(){
        
        if let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as? LoginViewController {
        
            self.presentViewController(loginVC, animated: false, completion: { _ in
                
                self.hideBackgroundImage()
                print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
            })
        }
   
    }
    
    
    /**
     Method to show the login VC with animation
     */
    func presentLoginVCAnimated(){
        
        if let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as? LoginViewController {
            self.presentViewController(loginVC, animated: true, completion: { _ in
                self.hideBackgroundImage()
                print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
            })
        }
        
    }
    
    /**
     Method switches to the feed tab and pops the view controller stack to the first vc
     */
    func switchToFeedTabAndPopToRootViewController(){
        
        self.selectedIndex = 0
        
        if let feedNavigationVC = self.viewControllers?[0] as? FeedNavigationController {
            feedNavigationVC.popToRootViewControllerAnimated(false)
        }
        
    }

    override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
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
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let _ = viewController as? CameraViewController { //if camera tab is selected, show camera picker
            handleCameraTabBeingSelected()
            return false
        }
        else if let _ = viewController as? ProfileNavigationController {
            return shouldShowProfileViewControllerAndHandleIfShouldnt()
        }
        else { //if feed selected, actually show it everytime
            return true
        }
    }
    
    /**
     Method is called when the profile tab is selected. If the user pressed login later, then we return false because we dont want to show the the user the profile vc and instead we want to present the login vc to the user. If the user didn't press login later, then we return true so the user is presented with the profile vc
     
     - returns: Bool
     */
    func shouldShowProfileViewControllerAndHandleIfShouldnt() -> Bool {
        if(viewModel.didUserPressLoginLater() == true){
            presentLoginVCAnimated()
            return false
        }
        else{
            return true
        }
    }
    
    /**
     Method handles the camera tab being selected. If the user pressed login later, then we present to the user the login vc. If the user didn't press login later, then we check if location services had been enabled or not. If it has been enabled, we show them the image picker action sheet. Else we show the user the location services required alert
     */
    func handleCameraTabBeingSelected(){
        if(viewModel.didUserPressLoginLater() == true){
            presentLoginVCAnimated()
        }
        else{
            LocationDataManager.SharedInstance.isLocationServicesEnabledAndIfNotHandleIt({ isEnabled in
                
                if(isEnabled){
                    CameraDataManager.SharedInstance.showImagePickerActionSheet(self)
                }
                else{
                    self.showLocationServiceRequiredAlert()
                }
            })
        }
    }
    
    
    /**
     Method shows the location services required alert
     */
    func showLocationServiceRequiredAlert(){
        
        let alertController = UIAlertController(title: NSLocalizedString("Location Services Required", comment: ""), message: NSLocalizedString("Please go to Settings to enable Location Services for BluePic", comment: ""), preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .Default) { (action) in
            
            if let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(settingsUrl)
            }

        }
        alertController.addAction(OKAction)

        self.presentViewController(alertController, animated: true, completion: nil)

    }

    /**
     Method to show the image upload failure alert
     */
    func showImageUploadFailureAlert(){
        
        let alert = UIAlertController(title: NSLocalizedString("Failed To Upload Image", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
            
            self.viewModel.tellBluemixDataManagerToCancelUploadingImagesThatFailedToUpload()
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
            
            self.viewModel.tellBluemixDataManagerToRetryUploadingImagesThatFailedToUpload()
            
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
 
}

//ViewModel -> View Controller Communication
extension TabBarViewController {
    
    /**
     Method that handles tab bar view model notifications from the tab bar view model
     
     - parameter tabBarNotification: TabBarViewModelNotification
     */
    func handleTabBarViewModelNotifications(tabBarNotification : TabBarViewModelNotification){
        
        if(tabBarNotification == TabBarViewModelNotification.ShowLoginVC) {
            presentLoginVC()
        }
        else if(tabBarNotification == TabBarViewModelNotification.HideLoginVC){
            hideBackgroundImage()
        }
        else if(tabBarNotification == TabBarViewModelNotification.SwitchToFeedTab){
            switchToFeedTabAndPopToRootViewController()
        }
        else if(tabBarNotification == TabBarViewModelNotification.ShowImageUploadFailureAlert){
            showImageUploadFailureAlert()
        }
    }
 
}

