/**
 * Copyright IBM Corporation 2015
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


/// Responsible for initiating Facebook login. VC which allows user to either login later or login with Facebook
class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    /// Loading indicator when connecting to Facebook
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    /// Button to allow user to dismiss login
    @IBOutlet weak var signInLaterButton: UIButton!
    
    /// Button to allow user to sign in with Facebook
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    /// Label to show an error if authentication is unsuccessful
    @IBOutlet weak var welcomeLabel: UILabel!
    
    /// Label to tell user that the application is connecting with Facebook while loading
    @IBOutlet weak var connectingLabel: UILabel!
    
    var appearingFirstTime = true

    
    /**
     Method called upon view did load. In this case we set up the view model.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Facebook Sign-In
        self.fbLoginButton.delegate = self
        self.fbLoginButton.readPermissions = ["public_profile", "email"]
   
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
    }
    
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        stopLoading()
        
        if error != nil {
            print("Unable to authenticate with Facebook")
        }
        else if result.isCancelled {
        }
        else {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": ""])
            graphRequest.startWithCompletionHandler() { connection, result, error in
                if error != nil {
                    print("Unable to get Facebook user info: \(error)")
                }
                else {
                    let fbId = result.valueForKey("id") as! String
                    let fbName = result.valueForKey("name") as! String
                    print("User Name is: \(fbName)")
                    if(FBSDKAccessToken.currentAccessToken() != nil) {
                        print("Facebook access token string: ", FBSDKAccessToken.currentAccessToken().tokenString)
                        self.signedInAs(fbName, id: fbId, userState: .SignedInWithFacebook)
                    } else {
                        print("Unable to get Facebook access token")
                    }
                }
            }
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    }

    
    func signedInAs(userName: String, id: String, userState: UserManager.UserAuthenticationState) {
        UserManager.SharedInstance.userDisplayName = userName
        UserManager.SharedInstance.uniqueUserID = id
        UserManager.SharedInstance.userAuthenticationState = userState
        NSUserDefaults.standardUserDefaults().setObject(id, forKey: "user_id")
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "user_name")
 
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasPressedLater")
        NSUserDefaults.standardUserDefaults().synchronize()

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /**
     Method to start the loading animation and setup UI for loading
     */
    func startLoading() {
        fbLoginButton.hidden = true
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

    
    /**
     Method is called when the app receives a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}
