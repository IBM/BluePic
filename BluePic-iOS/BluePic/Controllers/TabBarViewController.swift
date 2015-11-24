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
        self.loadingIndicator.startAnimating()
        self.backgroundImageView.addSubview(self.loadingIndicator)
        
    }
    
    
    func tryToShowLogin() {
        if (!hasTriedToPresentLoginThisAppLaunch) {
            //self.tryToShowLoginScreen()
            self.hasTriedToPresentLoginThisAppLaunch = true
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
