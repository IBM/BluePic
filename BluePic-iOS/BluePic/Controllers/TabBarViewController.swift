//
//  TabBarViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    
    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false
    
    /// Image view to temporarily cover feed and content so it doesn't appear to flash when showing login screen
    var backgroundImageView: UIImageView!
    
    var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor! = UIColor.whiteColor()
        
        self.addBackgroundImageView()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.userInteractionEnabled = false
        self.tryToShowLogin()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /**
     Add image view so no flickering occurs before showing login. Starts a simple loading animation that is dismissed when PULL from CloudantSyncClient completes
     */
    func addBackgroundImageView() {
        self.backgroundImageView = UIImageView(frame: self.view.frame)
        self.backgroundImageView.image = UIImage(named: "login_background")
        self.view.addSubview(self.backgroundImageView)
        
        self.loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(50, 10, 37, 37))
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.center = self.view.center
        self.loadingIndicator.activityIndicatorViewStyle = .WhiteLarge
        self.loadingIndicator.color = UIColor.colorWithRedValue(51, greenValue: 51, blueValue: 51, alpha: 1.0)
        self.loadingIndicator.hidden = true
        self.view.addSubview(self.loadingIndicator)
        
        
    }
    
    
    func tryToShowLogin() {
        if (!hasTriedToPresentLoginThisAppLaunch) {
            self.hasTriedToPresentLoginThisAppLaunch = true
            FacebookDataManager.SharedInstance.tryToShowLoginScreen(self)
        } 
        
    }
    
    
    
    
    
    /**
     Hide loading image view in tab bar vc once pulling is finished
     */
    func hideLoadingImageView() {
        dispatch_async(dispatch_get_main_queue()) {
            print("PULL complete, hiding loading")
            self.view.userInteractionEnabled = true
            self.loadingIndicator.stopAnimating()
            let feedVC = self.viewControllers![0] as! FeedViewController
            feedVC.puppyImage.hidden = false
        }
        
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry cloudant data pulling
     */
    func showCloudantErrorAlert() {
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred with Cloudant.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
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
