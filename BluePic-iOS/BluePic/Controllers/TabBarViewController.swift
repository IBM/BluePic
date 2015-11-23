//
//  TabBarViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    var user_id: String!
    var user_name: String!
    
    /// Boolean if showLoginScreen() has been called yet this app launch (should only try to show login once)
    var hasTriedToPresentLoginThisAppLaunch = false

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if (!hasTriedToPresentLoginThisAppLaunch) {
            self.tryToShowLoginScreen()
            self.hasTriedToPresentLoginThisAppLaunch = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tryToShowLoginScreen() {
        //check if user is already authenticated
        if let userID = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? String {
            self.user_id = userID
            self.checkIfUserExistsOnCloudantAndPushIfNeeded() //push copy of user id if it somehow got deleted from database
            print("Welcome back, user \(userID)!")
        }
        else { //user not authenticated
        
            //show login if user hasn't pressed "sign in later"
            if !NSUserDefaults.standardUserDefaults().boolForKey("hasPressedLater") {
                let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
                self.presentViewController(loginVC, animated: false, completion: nil)
                
            }
        }
    
        
    }
    
    func checkIfUserExistsOnCloudantAndPushIfNeeded() {
        
        if let userName = NSUserDefaults.standardUserDefaults().objectForKey("user_name") as? String {
            self.user_name = userName
            
                //Check if doc with fb id exists, add it if not
            if(!CloudantSyncClient.SharedInstance.doesExist(self.user_id))
                {
                        //Create profile document locally
                    CloudantSyncClient.SharedInstance.createProfileDoc(self.user_id, name: self.user_name)
                    //Push new profile document to remote database
                    CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
            
            }
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
