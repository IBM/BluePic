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
        
        self.pullLatestCloudantData()
        
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    
    @IBAction func signInLaterTapped(sender: AnyObject) {
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
                    self.checkIfUserExistsOnCloudantAndPushIfNeeded()
                    
                }
            }
            else {
                print("failure")
                self.welcomeLabel.text = "Uh oh, an error occurred!"
                self.facebookButton.hidden = false
                self.signInLaterButton.hidden = false
            }
        })
        
    }
    
    
    func pullLatestCloudantData() {
        
        //First do a pull to make sure datastore is up to date
        CloudantSyncClient.SharedInstance.pullFromRemoteDatabase()
        
    }
    
    
    func checkIfUserExistsOnCloudantAndPushIfNeeded() {
        
        //Check if doc with fb id exists
        if(!CloudantSyncClient.SharedInstance.doesExist(FacebookDataManager.SharedInstance.fbUniqueUserID!))
        {
            //Create profile document locally
            CloudantSyncClient.SharedInstance.createProfileDoc(FacebookDataManager.SharedInstance.fbUniqueUserID!, name: FacebookDataManager.SharedInstance.fbUserDisplayName!)
            //Push new profile document to remote database
            CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
            
                
            
        }
        let userDisplayName = FacebookDataManager.SharedInstance.fbUserDisplayName!
        let name = userDisplayName.componentsSeparatedByString(" ").first
        self.welcomeLabel.text = "Welcome to BluePic, \(name!)!"
    }
    
    
    func sendIDToBluemix() {
        
        let parameters = [
            "fb_id": FacebookDataManager.SharedInstance.fbUniqueUserID!,
            "profile_name": FacebookDataManager.SharedInstance.fbUserDisplayName!
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let url = "http://BluePic-II.mybluemix.net/cloudantapi"
        
                Alamofire.request(.POST, url, parameters: parameters, headers: headers, encoding: .JSON)
                    .responseJSON { response in
        
                    print(response)
                }
        
//        Alamofire.request(.POST, url, parameters: parameters, headers: headers, encoding: .JSON)
//            .responseObject() { (response: Response<OAuth, NSError>) in
//                debugPrint(response)
//                
//                let oAuth = response.result.value
//                
//                
//                
//        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

