//
//  Created by Assaf Akrabi on 3/1/15.
//  Copyright (c) 2015 IBM Corporation. All rights reserved.
//

import UIKit

class LoginController: BaseLoginController, FBSDKLoginButtonDelegate {//, GPPSignInDelegate {
 //   static let googleClientID = "1076497918728-2h4v2one5b7jlo9qcgchgn8qojp6aek1.apps.googleusercontent.com"
    
    @IBOutlet weak var fbLoginView: FBSDKLoginButton!
//    @IBOutlet weak var gppSigninButton: GPPSignInButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Google Sign-In
//        var signIn = GPPSignIn.sharedInstance()
//        signIn.shouldFetchGooglePlusUser = true
//        signIn.shouldFetchGoogleUserEmail = true
//        signIn.clientID = LoginController.googleClientID
//        signIn.scopes = ["profile"]
//        signIn.delegate = self
//        signIn.trySilentAuthentication()
        
        // Facebook Sign-In
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email"]
    }
    
    
    @IBAction func loginStarts(sender: AnyObject) {
        spinner.startAnimating()
        fbLoginView.hidden = true
//      gppSigninButton.hidden = true
    }
    
    
    // MARK: - Google Delegate Methods
//    
//    func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
//        if error == nil { // Success
//            var googleUser = GPPSignIn.sharedInstance().googlePlusUser
//            User.sharedInstance.set(fromGoogle: googleUser)
//            var userName = User.sharedInstance.name
//            userName = googleUser.displayName
//            print("\(userName) logged in using Google+")
//            spinner.stopAnimating()
//            fbLoginView.hidden = false
//            gppSigninButton.hidden = false
//            if let d = self.delegate {
//                d.signedInAs(userName)
//            }
//            
//        }
//        else { // Failure
//            print("Unable to authenticate with Google+")
//            spinner.stopAnimating()
//            fbLoginView.hidden = false
//            gppSigninButton.hidden = false
//        }
//    }
//    
//    
//    func didDisconnectWithError(error: NSError!) {
//        if error != nil {
//            print("Received error \(error.localizedDescription)")
//            spinner.stopAnimating()
//            fbLoginView.hidden = false
//            gppSigninButton.hidden = false
//        } else {
//            print("User Disconnected from Google+")
//            // The user is signed out and disconnected.
//            // Clean up user data as specified by the Google+ terms.
//            spinner.stopAnimating()
//            fbLoginView.hidden = false
//            gppSigninButton.hidden = false
//        }
//    }
//    
    
    // MARK: - Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        spinner.stopAnimating()
        fbLoginView.hidden = false
      //  gppSigninButton.hidden = false
        
        if error != nil {
            print("Unable to authenticate with Facebook")
        }
        else if result.isCancelled {
            print("Facebook authentication cancelled")
        }
        else {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
            graphRequest.startWithCompletionHandler() { connection, result, error in
                if error != nil {
                    print("Unable to get Facebook user info: \(error)")
                }
                else {
                    print("result: \(result)")
                    let fbId = result.valueForKey("id") as! String
                    print("User ID is: \(fbId)")
                    let fbName = result.valueForKey("name") as! String
                    print("User Name is: \(fbName)")
//                    let fbEmail = result.valueForKey("email") as! String
//                    print("User Email is: \(fbEmail)")
                    
                   // User.sharedInstance.set(fromFacebook: result)
      //              var userName = User.sharedInstance.name
//                    print("Fetched \(userName)\'s user info from Facebook")
                    if let d = self.delegate {
                        d.signedInAs(fbName, id: fbId)
                    }
                }
            }
        }
    }
    
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    }
    
}
