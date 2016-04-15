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

class LoginDummyController: BaseLoginController, UITextFieldDelegate {
    
    private static let SAVED_USER_NAME = "saved_user_name"
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var rememberUserNameSwitch: UISwitch!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var versionLabel: UILabel!
    
    private var userName: String {
        get {
            return userNameField.text!
        }
        set {
            userNameField.text = newValue
            validate()
        }
    }
    
    
    private var password: String {
        get {
            return passwordField.text!
        }
        set {
            passwordField.text = newValue
            validate()
        }
    }
    
    
    private var rememberUserName: Bool {
        get {
            return rememberUserNameSwitch.on
        }
        set {
            rememberUserNameSwitch.on = newValue
        }
    }
    
    
    private var version: String? {
        get {
            return versionLabel.text
        }
        set {
            versionLabel.text = newValue
        }
    }
    
    
    private var errorMessage: String? {
        get {
            if errorLabel.hidden {
                return nil
            }
            else {
                return errorLabel.text
            }
        }
        set {
            if let value = newValue {
                errorLabel.text = value
                errorLabel.hidden = false
            }
            else {
                errorLabel.text = ""
                errorLabel.hidden = true
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let verson = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        //var build = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as String
        //version = "v\(verson) (\(build))"
        version = "v\(verson)"
        
        if let un = NSUserDefaults.standardUserDefaults().stringForKey(LoginDummyController.SAVED_USER_NAME) {
            if !un.isEmpty {
                userName = un
                rememberUserName = true
            }
            else {
                rememberUserName = false
                userNameField.becomeFirstResponder()
            }
        }
        else {
            rememberUserName = true
            userName = "demo"
        }
        
        if userName == "demo" {
            password = "1"
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    @IBAction func userNameChanged(sender: UITextField) {
        validate()
    }
    
    
    @IBAction func passwordChanged(sender: UITextField) {
        validate()
    }
    
    
    func validate() {
        var valid = true
        if userName.isEmpty {
            valid = false
        }
        if password.isEmpty {
            valid = false
        }
        signInButton.enabled = valid
    }
    
    
    @IBAction func signInPressed(sender: UIButton) {
        userNameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        let userNameToSave = rememberUserName ? userName : ""
        NSUserDefaults.standardUserDefaults().setObject(userNameToSave, forKey: LoginDummyController.SAVED_USER_NAME)
        
        signInButton.enabled = false
        errorMessage = ""
        forgotPasswordButton.hidden = true
        spinner.startAnimating()
        signInAs(userName, password: password, withCompletionHandler: { error in
            self.spinner.stopAnimating()
            self.signInButton.enabled = true
            if let e = error {
                self.errorMessage = e
                self.forgotPasswordButton.hidden = false
            }
        })
    }
    
    
    @IBAction func forgotPasswordPressed(sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: "An email has been sent to you, containing your password", preferredStyle: .Alert)
        let closeAction = UIAlertAction(title: "Close", style: .Cancel) { action in
        }
        alertController.addAction(closeAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    func registerForKeyboardNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    func keyboardWillBeShown(sender: NSNotification) {
//        let info = sender.userInfo! as NSDictionary
//        let value = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
//        //let keyboardSize = value.CGRectValue().size
        //animateViewHeight(view.superview!.bounds.size.height - keyboardSize.height)
        animateViewPosition(-80)
    }
    
    
    func keyboardWillBeHidden(sender: NSNotification) {
        //animateViewHeight(view.superview!.bounds.size.height)
        animateViewPosition(0)
    }
    
    
    func signInAs(userName: String, password: String, withCompletionHandler callback: (String?) -> Void) {
        let r = SignInRequest(userName: userName, password: password, callback: callback)
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "signInResponse:", userInfo: r, repeats: false)
    }
    
    
    func signInResponse(timer: NSTimer) {
        if let r = timer.userInfo as? SignInRequest {
            if r.password.characters.count == 1 {
                User.sharedInstance.name = r.userName
                User.sharedInstance.type = User.UserType.Dummy
                r.callback(nil)
                if let d = delegate {
                    d.signedInAs(r.userName)
                }
            }
            else {
                r.callback("Sorry, try again...")
            }
        }
    }

    
    
    /*func animateViewHeight(newHight: CGFloat) {
        if view.frame.size.height == newHight {
            return
        }
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame.size.height = newHight
        },
        completion: nil)
    }*/
    
    
    func animateViewPosition(newY: CGFloat) {
        if view.frame.origin.y == newY {
            return
        }
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame.origin.y = newY
        },
        completion: nil)
    }
    
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview!.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        }
        else {
            if signInButton.enabled {
                signInPressed(signInButton)
            }
        }
        
        return false
    }
    
}


class SignInRequest: NSObject {
    var userName: String
    var password: String
    var callback: (String?) -> Void
    
    init(userName: String, password: String, callback: (String?) -> Void) {
        self.userName = userName
        self.password = password
        self.callback = callback
        super.init()
    }
}
