//
//  TabBarViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/23/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    var hasShownLogin = false

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if (!hasShownLogin) {
            self.showLoginScreen()
            self.hasShownLogin = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showLoginScreen() {
        let loginVC = Utils.vcWithNameFromStoryboardWithName("loginVC", storyboardName: "Main") as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: nil)
        
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
