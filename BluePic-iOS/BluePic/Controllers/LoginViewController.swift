/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit

class LoginViewController: UIViewController {

    /// Loading indicator when connecting to Facebook
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    /// Button to allow user to dismiss login
    @IBOutlet weak var signInLaterButton: UIButton!
    
    /// Button to allow user to sign in with Facebook
    @IBOutlet weak var facebookButton: UIButton!
    
    /// Label to show an error if authentication is unsuccessful
    @IBOutlet weak var welcomeLabel: UILabel!
    
    /// Label to tell user that the application is connecting with Facebook while loading
    @IBOutlet weak var connectingLabel: UILabel!
    
    //label that tells the user what bluepic is
    @IBOutlet weak var aboutBluePicLabel: UILabel!
    
    /// ViewModel for this VC, responsible for holding data and any state
    var viewModel: LoginViewModel!
    
    //error message shown to user when there is an error
    private let kLoginErrorMessage = NSLocalizedString("Oops, an error occurred! Try again.", comment: "")
    
    //string shown in the aboutBluePicLabel
    private let kAboutBluePicLabelText = NSLocalizedString("BluePic is an amazing app for taking\n pictures and sharing them to the\n BluePic community. BluePic is\n also built on IBM Bluemix services.", comment: "")
   

    /**
     Method called upon view did load. In this case we set up the view model and the aboutBluePicLabel
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewModel()
        setupAboutBluePicLabel()
   
    }
    
    /**
     Method sets the status bar to white
     
     - parameter animated: Bool
     */
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }

    
    /**
     Method to setup this VC's viewModel and provide it a callback method to all the vc to receive notifications from its view model
     */
    func setupViewModel() {
        viewModel = LoginViewModel(notifyLoginVC: handleLoginViewModelNotifications)
    }
    
    /**
     Method sets up the aboutBluePicLabel's text with the kAboutBluePicLabelText property
     */
    private func setupAboutBluePicLabel(){
    
        aboutBluePicLabel.text = kAboutBluePicLabelText
        aboutBluePicLabel.setLineHeight(1.5)
    
    }
    
    
    /**
     Method to save to user defaults when user has pressed sign in later
     
     - parameter sender: sign in later button
     */
    @IBAction func signInLaterTapped(sender: AnyObject) {
        viewModel.loginLater()
        
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
//    func stopLoading() {
//        loadingIndicator.stopAnimating()
//        loadingIndicator.hidden = true
//        welcomeLabel.hidden = false
//        connectingLabel.hidden = true
//    }

    
    /**
     Method is called when the app receives a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}

// MARK: - ViewModel -> View Controller Communication
extension LoginViewController {
    
    /**
     Method that is called by the view model when the view model wants to notifiy this vc with notifications of events that have occurred
     
     - parameter loginViewModelNotification: LoginViewModelNotification
     */
    func handleLoginViewModelNotifications(loginViewModelNotification : LoginViewModelNotification){
        
        if(loginViewModelNotification == LoginViewModelNotification.LoginSuccess){
            handleLoginSuccess()
        }
        else if(loginViewModelNotification == LoginViewModelNotification.LoginFailure){
            handleLoginFailure()
        }
        else if(loginViewModelNotification == LoginViewModelNotification.UserCanceledLogin){
            handleUserCanceledLogin()
        }
        
    }
    
    /**
     Method handles when there was a login success
     */
    func handleLoginSuccess(){
        dispatch_async(dispatch_get_main_queue()) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    /**
     Method handles when the user canceled login
     */
    func handleUserCanceledLogin(){
        dispatch_async(dispatch_get_main_queue()) {
            self.welcomeLabel.hidden = true
            self.facebookButton.hidden = false
            self.signInLaterButton.hidden = false
            self.connectingLabel.hidden = true
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true

        }
    }
    
    
    /**
     Method handles when there was a login failure
     */
    func handleLoginFailure(){
        
        dispatch_async(dispatch_get_main_queue()) {
            self.welcomeLabel.text = self.kLoginErrorMessage
            self.welcomeLabel.hidden = false
            self.facebookButton.hidden = false
            self.signInLaterButton.hidden = false
            self.connectingLabel.hidden = true
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
        }
        
    }
}
