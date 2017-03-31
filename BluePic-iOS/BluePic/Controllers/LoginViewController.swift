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
    fileprivate let kLoginErrorMessage = NSLocalizedString("Oops, an error occurred! Try again.", comment: "")

    //string shown in the aboutBluePicLabel
    fileprivate let kAboutBluePicLabelText = NSLocalizedString("BluePic's back-end component is written entirely in the Swift programming language and runs on a Kitura-based server that leverages several IBM Bluemix services and OpenWhisk actions.", comment: "")

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
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
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
    fileprivate func setupAboutBluePicLabel() {

        aboutBluePicLabel.text = kAboutBluePicLabelText
        aboutBluePicLabel.setLineHeight(1.5)

    }

    /**
     Method to save to user defaults when user has pressed sign in later

     - parameter sender: sign in later button
     */
    @IBAction func signInLaterTapped(_ sender: Any) {
        viewModel.loginLater()

        dismiss(animated: true, completion: nil)
    }

    /**
     Method to authenticate with facebook when login is tapped

     - parameter sender: button tapped
     */
    @IBAction func loginTapped(_ sender: Any) {
        startLoading()
        viewModel.authenticateWithFacebook()

    }

    /**
     Method to start the loading animation and setup UI for loading
     */
    func startLoading() {
        facebookButton.isHidden = true
        signInLaterButton.isHidden = true
        welcomeLabel.isHidden = true
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        connectingLabel.isHidden = false
    }

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
    func handleLoginViewModelNotifications(_ loginViewModelNotification: LoginViewModelNotification) {

        if loginViewModelNotification == LoginViewModelNotification.loginSuccess {
            handleLoginSuccess()
        } else if loginViewModelNotification == LoginViewModelNotification.loginFailure {
            handleLoginFailure()
        } else if loginViewModelNotification == LoginViewModelNotification.userCanceledLogin {
            handleUserCanceledLogin()
        }

    }

    /**
     Method handles when there was a login success
     */
    func handleLoginSuccess() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    /**
     Method handles when the user canceled login
     */
    func handleUserCanceledLogin() {
        DispatchQueue.main.async {
            self.welcomeLabel.isHidden = true
            self.facebookButton.isHidden = false
            self.signInLaterButton.isHidden = false
            self.connectingLabel.isHidden = true
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true

        }
    }

    /**
     Method handles when there was a login failure
     */
    func handleLoginFailure() {

        DispatchQueue.main.async {
            self.welcomeLabel.text = self.kLoginErrorMessage
            self.welcomeLabel.isHidden = false
            self.facebookButton.isHidden = false
            self.signInLaterButton.isHidden = false
            self.connectingLabel.isHidden = true
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true
        }

    }
}
