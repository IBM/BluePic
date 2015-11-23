//
//  TabBarViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
            self.showLoginScreen()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showLoginScreen() {
        //check if user is already authenticated
        if let userID = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? String {
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
