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
        
        viewModel = TabBarViewModel()
        
        self.tabBar.tintColor! = UIColor.whiteColor()
        
        self.addBackgroundImageView()
        
        self.delegate = self
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
    
    func setupFeedVC() {
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
        
        let hasTriedToPresentLoginThisAppLaunch = viewModel.getHasTriedToPresentLoginThisAppLaunch()
        
        if (!hasTriedToPresentLoginThisAppLaunch) {
            self.view.userInteractionEnabled = false
            viewModel.setHasTriedToPresentLoginThisAppLaunchToTrue()
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self)
        } 
        
    }
    
    
    
    func hideBackgroundImageAndStartLoading() {
        
        //hide temp background image used to prevent flash animation
        self.backgroundImageView.hidden = true
        self.backgroundImageView.removeFromSuperview()
        self.feedVC.logoImageView.startRotating(1) //animate rotating logo with certain speed
        
    }
    
    
    
    /**
     Stop loading image view in feedVC once pulling is finished
     */
    func stopLoadingImageView() {
        dispatch_async(dispatch_get_main_queue()) {
            print("PULL complete, stopping loading")
            self.view.userInteractionEnabled = true
            self.feedVC.logoImageView.stopRotating()
        }
        
    }
    
    
    
    /**
     Method to show the error alert and asks user if they would like to retry cloudant data pushing
     */
    func showCloudantPushingErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred uploading to Cloudant.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry cloudant data pulling
     */
    func showCloudantPullingErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error downloading Cloudant data.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.retryPullingCloudantData()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry object storage authentication
     */
    func showObjectStorageErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred with Object Storage.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.retryAuthenticatingObjectStorage()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    
    /**
     Retry pulling cloudant data upon error
     */
    func retryPullingCloudantData() {
        //CloudantSyncClient.SharedInstance.pullReplicator.stop()
        CloudantSyncClient.SharedInstance.pullFromRemoteDatabase()
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to pull Cloudant data")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self)
            
        }
        
    }
    
    
    /**
     Retry authenticating with object storage upon error
     */
    func retryAuthenticatingObjectStorage() {
        dispatch_async(dispatch_get_main_queue()) {
            print("Retrying to authenticate with Object Storage")
            
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self)
            
        }
        
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension TabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let _ = viewController as? CameraViewController { //if camera tab is selected, show camera picker
            print("Opening camera picker...")
            CameraDataManager.SharedInstance.showImagePickerActionSheet(self)
            
            return false
        } else { //if not camera tab selected, actually show the selected tab
            return true
        }
    }
    
    
    
}
