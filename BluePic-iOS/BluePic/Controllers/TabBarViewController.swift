//
//  TabBarViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    /// Image view to temporarily cover feed and content so it doesn't appear to flash when showing login screen
    var backgroundImageView: UIImageView!
    
    var feedVC: FeedViewController!
    
    var viewModel : TabBarViewModel!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = TabBarViewModel(passDataNotificationToTabBarVCCallback: handleDataNotification)
        
        self.tabBar.tintColor! = UIColor.whiteColor()
        
        self.addBackgroundImageView()
        
        self.delegate = self
        
        //self.setupFeedViewModel()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        
        self.setupFeedVC()

        self.tryToShowLogin()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func setupFeedVC(){
        self.feedVC = self.viewControllers![0] as! FeedViewController
        feedVC.logoImageView.image = UIImage(named: "shutter")

    }
    
    
    /**
     Add image view so no flickering occurs before showing login. Starts a simple loading animation that is dismissed when PULL from CloudantSyncClient completes
     */
    func addBackgroundImageView() {
        self.backgroundImageView = UIImageView(frame: self.view.frame)
        self.backgroundImageView.image = UIImage(named: "login_background")
        self.view.addSubview(self.backgroundImageView)
        
        
    }
    
    
    func tryToShowLogin() {
    
        viewModel.tryToShowLogin()
        
    }
    
    
    func handleDataNotification(dataManagerNotification : DataManagerNotification){
        
        if(dataManagerNotification == DataManagerNotification.GotPastLoginCheck){
            hideBackgroundImage()
        }
        else if(dataManagerNotification == DataManagerNotification.ObjectStorageAuthError){
            showObjectStorageAuthErrorAlert()
        }
        else if(dataManagerNotification == DataManagerNotification.ObjectStorageUploadError){
            showObjectStorageUploadErrorAlert()
        }
        else if(dataManagerNotification == DataManagerNotification.UserNotAuthenticated){
            presentLoginVC()
        }
        else if(dataManagerNotification == DataManagerNotification.CloudantPushDataFailiure){
            showCloudantPushingErrorAlert()
        }
        else if(dataManagerNotification == DataManagerNotification.CloudantPullDataFailure){
            showCloudantPullingErrorAlert()
        }
        else if(dataManagerNotification == DataManagerNotification.UserNotAuthenticated){
            presentLoginVC()
        }
        
    }
    
    
    func hideBackgroundImage() {
        
        //hide temp background image used to prevent flash animation
        self.backgroundImageView.hidden = true
        self.backgroundImageView.removeFromSuperview()
        
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry cloudant data pushing
     */
    func showCloudantPushingErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred uploading to Cloudant.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.viewModel.retryPushingCloudantData()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry cloudant data pulling
     */
    func showCloudantPullingErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred downloading Cloudant data.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.viewModel.retryPullingCloudantData()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry object storage authentication
     */
    func showObjectStorageAuthErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred authenticating with Object Storage.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.viewModel.retryAuthenticatingObjectStorage()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    /**
     Method to show the error alert and asks user if they would like to retry pushing to object storage
     */
    func showObjectStorageUploadErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred uploading to Object Storage.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            CameraDataManager.SharedInstance.uploadImageToObjectStorage()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func presentLoginVC(){
        
        let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
        self.presentViewController(loginVC, animated: false, completion: { _ in
            self.hideBackgroundImage()
            print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
        })
   
    }
    
    func presentLoginVCAnimated(){
        
        let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: { _ in
            self.hideBackgroundImage()
            print(NSLocalizedString("user needs to log into Facebook, showing login", comment: ""))
        })
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }


}


extension TabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let _ = viewController as? CameraViewController { //if camera tab is selected, show camera picker
            return checkIfUserPressedSignInLater(true)
        }
        else if let _ = viewController as? ProfileViewController {
            return checkIfUserPressedSignInLater(false)
        }
        else { //if feed selected, actually show it everytime
            return true
        }
    }
    
    /**
     Check if user has pressed sign in later button previously, and if he/she has, will show login if user taps camera or profile
     
     - parameter showCameraPicker: whether or not to show the camera picker (camera tab or profile tab tapped)
     
     - returns: Returns a boolean -- true if tab bar with show the selected tab, and false if it will not
     */
    func checkIfUserPressedSignInLater(showCameraPicker: Bool!) -> Bool! {
        if NSUserDefaults.standardUserDefaults().boolForKey("hasPressedLater") == true {
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
