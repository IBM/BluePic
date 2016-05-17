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
        
        self.tabBar.tintColor! = UIColor.whiteColor()
        
        self.addBackgroundImageView()
        
        self.delegate = self
        
    }
    
   
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
     Method adds image view so no flickering occurs before showing login. Starts a simple loading animation that is dismissed when PULL from CloudantSyncClient completes
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
        
        let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
        
        self.presentViewController(loginVC, animated: false, completion: { _ in
            
            self.hideBackgroundImage()
            print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
        })
   
    }
    
    
    /**
     Method to show the login VC with animation
     */
    func presentLoginVCAnimated(){
        
        let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: { _ in
            self.hideBackgroundImage()
            print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
        })
        
    }
    
    func switchToFeedTabAndPopToRootViewController(){
        
        self.selectedIndex = 0
        
        if let feedNavigationVC = self.viewControllers![0] as? FeedNavigationController {
            feedNavigationVC.popToRootViewControllerAnimated(false)
        }
        
    }

    override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return true
    }
    
}


extension TabBarViewController: UITabBarControllerDelegate {
    
    /**
     Method is called right when the user selects a tab. It expects a return value that tells the TabBarViewController whether it should select that tab or not. In this case we check if the user has pressed the sign in later option in on the login VC. If the user has pressed the sign in later option, then we present the Login View Controller when the user presses the profile or camera tab. Else we show those tabs as normal.
     
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
    
    func shouldShowProfileViewControllerAndHandleIfShouldnt() -> Bool {
        if(viewModel.didUserPressLoginLater() == true){
            presentLoginVCAnimated()
            return false
        }
        else{
            return true
        }
    }
    
    
    
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
    
    
    func showLocationServiceRequiredAlert(){
        
        let alertController = UIAlertController(title: "Location Services Required", message: "Please go to Settings to enable Location Services for BluePic", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "Settings", style: .Default) { (action) in
            
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            
            UIApplication.sharedApplication().openURL(settingsUrl!)

        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }

    }
    



    /**
     Check if user has pressed sign in later button previously, and if he/she has, will show login if user taps camera or profile
     
     - parameter showCameraPicker: whether or not to show the camera picker (camera tab or profile tab tapped)
     
     - returns: Returns a boolean -- true if tab bar with show the selected tab, and false if it will not
     */
    func checkIfUserPressedSignInLater(showCameraPicker: Bool!) -> Bool! {
        if viewModel.didUserPressLoginLater() {
            print("user not logged in, prompt login now!")
            presentLoginVCAnimated()
            return false
        }
        else { //only show camera picker if user has not pressed "sign in later"
            if (showCameraPicker == true) { //only show camera picker if tapped the camera tab
                print("Opening camera picker...")
                CameraDataManager.SharedInstance.showImagePickerActionSheet(self)
                return false
            }
            else { //if tapping profile page and logged in, show that tab
                return true
            }
        }
    
    }
    
    
    
}

//ViewModel -> View Controller Communication
extension TabBarViewController {
    
    
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
        
    }
 
}

