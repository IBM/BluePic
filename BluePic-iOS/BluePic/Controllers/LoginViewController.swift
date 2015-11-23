//
//  ViewController.swift
//  BluePic
//
//  Created by Nathan Hekman on 11/16/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

class LoginViewController: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var signInLaterButton: UIButton!
    
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.pullLatestCloudantData()
        
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    
    @IBAction func signInLaterTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasPressedLater")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func loginTapped(sender: AnyObject) {
        self.facebookButton.hidden = true
        self.signInLaterButton.hidden = true
        self.loadingIndicator.startAnimating()
        FacebookDataManager.SharedInstance.authenticateUser({(response: FacebookDataManager.NetworkRequest) in
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.welcomeLabel.hidden = false
            if (response == FacebookDataManager.NetworkRequest.Success) {
                print("success")
                if let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
                    print("\(userID)")
                    
                }
                if let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName {
                    print("\(userDisplayName)")
                    //save that user has not pressed login later
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasPressedLater")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    //update labels
                    let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName!
                    let name = userDisplayName.componentsSeparatedByString(" ").first
                    self.welcomeLabel.text = "Welcome to BluePic, \(name!)!"
                    
                    //dismiss login vc
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
                    //self.checkIfUserExistsOnCloudantAndPushIfNeeded()
                    
                }
            }
            else {
                print("failure")
                self.welcomeLabel.text = "Oops, an error occurred! Try again."
                self.facebookButton.hidden = false
                self.signInLaterButton.hidden = false
            }
        })
        
    }
    
    
//    func pullLatestCloudantData() {
//        
//        //First do a pull to make sure datastore is up to date
//        CloudantSyncClient.SharedInstance.pullFromRemoteDatabase()
//        
//    }
    
    


    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

