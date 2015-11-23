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

class ViewController: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var signInLaterButton: UIButton!
    
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    var cSync:CloudantSyncClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Test to prove Alamofire is working
        Alamofire.request(.GET, "https://httpbin.org/get")

        //Test code to see if CDTDatastore works
        let key = "heresclyinglownstindbadv"
        let pass = "e22cda58e40afb28d7614e9e57272fcc1d27d946"
        let dbName = "my_db"
        let username = "e1ad23d5-4602-46ff-ad38-6e692ff0c1dd-bluemix"
        cSync = CloudantSyncClient(apiKey: key, apiPassword: pass, dbName: dbName, username: username)
        //First do a pull to make sure datastore is up to date
        cSync.pullFromRemoteDatabase()
        //Check if doc with fb id exists
        if(!cSync.doesExist("1234"))
        {
            //Create profile document locally
            cSync.createProfileDoc("1234", name: "Rolando Asmat")
            //Push new profile document to remote database
            cSync.pushToRemoteDatabase()
        }
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
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
                    let name = userDisplayName.componentsSeparatedByString(" ").first
                    self.welcomeLabel.text = "Welcome to BluePic, \(name!)!"
                    self.sendIDToBluemix()
                    
                    
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

