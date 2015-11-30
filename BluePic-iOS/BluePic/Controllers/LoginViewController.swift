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
   
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    
    @IBAction func signInLaterTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasPressedLater")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func loginTapped(sender: AnyObject) {
        self.startLoading()
        FacebookDataManager.SharedInstance.authenticateUser({(response: FacebookDataManager.NetworkRequest) in
            if (response == FacebookDataManager.NetworkRequest.Success) {
                print("successfully logged into facebook with keys:")
                if let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
                    if let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName {
                        print("\(userID)")
                        print("\(userDisplayName)")
                        //save that user has not pressed login later
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasPressedLater")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        
                        //add container once to object storage, then stop loading once completed
                        self.createObjectStorageContainer(userID)
                        
                    }
                }
            }
            else {
                self.stopLoading()
                print("failure logging into facebook")
                self.welcomeLabel.text = "Oops, an error occurred! Try again."
                self.facebookButton.hidden = false
                self.signInLaterButton.hidden = false
            }
        })
        
    }
    
    
    
    func createObjectStorageContainer(userID: String!) {
        print("Creating object storage container...")
        ObjectStorageDataManager.SharedInstance.objectStorageClient.createContainer(userID, onSuccess: {(name) in
            print("Successfully created object storage container with name \(name)") //success closure
            //stop loading on completion
            self.stopLoading()

            //update labels
            let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName!
            let name = userDisplayName.componentsSeparatedByString(" ").first
            self.welcomeLabel.text = "Welcome to BluePic, \(name!)!"
            
            //dismiss login vc
            self.dismissViewControllerAnimated(true, completion: nil)
            
            }, onFailure: {(error) in //failure closure
                print("Facebook auth successful, but error creating Object Storage container: \(error)")
                self.stopLoading()
                self.welcomeLabel.text = "Oops, an error occurred! Try again."
                self.facebookButton.hidden = false
                self.signInLaterButton.hidden = false
                
        })
        
    }
    
    
    
    func startLoading() {
        self.facebookButton.hidden = true
        self.signInLaterButton.hidden = true
        self.loadingIndicator.startAnimating()
        
    }
    
    
    
    func stopLoading() {
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.hidden = true
        self.welcomeLabel.hidden = false
        
    }

    
    


    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

