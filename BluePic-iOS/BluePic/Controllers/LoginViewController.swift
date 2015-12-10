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
    
    @IBOutlet weak var connectingLabel: UILabel!
    
    var viewModel: LoginViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewModel()
   
    }

    
    /**
     Method to setup this VC's viewModel and provide it a callback method to execute
     */
    func setupViewModel() {
        
        viewModel = LoginViewModel(fbAuthCallback: fbAuthReturned)
        
    }
    
    
    /**
     Method to save to user defaults when user has pressed sign in later
     
     - parameter sender: sign in later button
     */
    @IBAction func signInLaterTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasPressedLater")
        NSUserDefaults.standardUserDefaults().synchronize()
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    
    /**
     Method to authenticate with facebook when login is tapped
     
     - parameter sender: button tapped
     */
    @IBAction func loginTapped(sender: AnyObject) {
        startLoading()
        viewModel.authenticateWithFacebook()
        
    }
    
    
    
    /**
     Callback method called when facebook authentication + creating object storage container returns
     
     - parameter successful: value returned, either successful or not
     */
    func fbAuthReturned(successful: Bool!) {
        stopLoading()
        
        if !successful {
            //show error message
            welcomeLabel.text = "Oops, an error occurred! Try again."
            facebookButton.hidden = false
            signInLaterButton.hidden = false
            
        }
        else {
            //dismiss login vc
            dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    
    /**
     Method to start the loading animation and setup UI for loading
     */
    func startLoading() {
        facebookButton.hidden = true
        signInLaterButton.hidden = true
        welcomeLabel.hidden = true
        loadingIndicator.startAnimating()
        loadingIndicator.hidden = false
        connectingLabel.hidden = false
    }
    
    
    /**
     Method to stop the loading animation and setup UI for done loading state
     */
    func stopLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.hidden = true
        welcomeLabel.hidden = false
        connectingLabel.hidden = true
    }

    
    


    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

