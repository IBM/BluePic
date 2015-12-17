/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit


/// Responsible for initiating Facebook login. VC which allows user to either login later or login with Facebook
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
    
    /// ViewModel for this VC, responsible for holding data and any state
    var viewModel: LoginViewModel!
    
    
    /**
     Method called upon view did load. In this case we set up the view model.
     */
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

    
    /**
     Method is called when the app receives a memory warning from the OS
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}
