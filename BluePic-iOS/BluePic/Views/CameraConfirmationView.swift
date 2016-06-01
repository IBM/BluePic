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

/// Confirmation view to allow user to add a caption to a photo and upload or cancel photo upload
class CameraConfirmationView: UIView, UITextFieldDelegate {

    /// Image view to show the chosen photo in
    @IBOutlet weak var photoImageView: UIImageView!

    /// Cancel button to cancel uploading a photo
    @IBOutlet weak var cancelButton: UIButton!

    /// Post button to post a photo
    @IBOutlet weak var postButton: UIButton!

    /// Caption text field to specify a photo caption
    @IBOutlet weak var titleTextField: UITextField!

    /// Loading indicator while uploading
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    /// Reference to the original frame
    var originalFrame: CGRect!

    /// Placeholder text for the titleTextField
    private let kTextFieldPlaceholderText = NSLocalizedString("GIVE IT A TITLE", comment: "")


    /**
     Return an instance of this view

     - returns: an instance of this view
     */
    static func instanceFromNib() -> CameraConfirmationView? {
        guard let cameraConfirmationView = UINib(nibName: "CameraConfirmationView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? CameraConfirmationView else {
            print(NSLocalizedString("Unable to load camera confirmation view from nib", comment: ""))
            return nil
        }
        return cameraConfirmationView
    }

    /**
     Method called when the view wakes from nib and then sets up the view
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupView()
        self.addKeyboardObservers()
    }

    /**
     Method to setup the view and its outlets
     */
    func setupView() {

        let localizedString = kTextFieldPlaceholderText
        self.titleTextField.attributedPlaceholder = NSAttributedString(string:localizedString,
            attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        self.translatesAutoresizingMaskIntoConstraints = true
        self.titleTextField.tintColor = UIColor.whiteColor()

    }

    /**
     Method called when keyboard will show

     - parameter notification: show notification
     */
    func keyboardWillShow(notification: NSNotification) {
        UIApplication.sharedApplication().statusBarHidden = true
        adjustingHeight(true, notification: notification)
    }

    /**
     Method called when keyboard will hide

     - parameter notification: hide notification
     */
    func keyboardWillHide(notification: NSNotification) {
        adjustingHeight(false, notification: notification)
    }

    /**
     Method called when touches began to hide keyboard

     - parameter touches: touches that began
     - parameter event:   event when touches began
     */
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.endEditing(true)
    }

    /**
     Method to add show and hide keyboard observers
     */
    func addKeyboardObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CameraConfirmationView.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CameraConfirmationView.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }

    /**
     Method to remove show and hide keyboard observers
     */
    func removeKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    /**
     Method to move the whole view up/down when user pulls the keyboard up/down

     - parameter show:         whether or raise or lower view
     - parameter notification: hide or show notification called
     */
    func adjustingHeight(show: Bool, notification: NSNotification) {
        // 1
        if let userInfo = notification.userInfo,
            keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval {
        // 2
        let keyboardFrame  = keyboardFrameValue.CGRectValue()
        // 3
        let changeInHeight = (keyboardFrame.height) * (show ? -1 : 1)
        //4
        if show {
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.frame = CGRect(x: 0, y: 0 + changeInHeight, width: self.frame.width, height: self.frame.height)
            })
        } else {
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.frame = self.originalFrame

            })
        }
        }
    }

    /**
     Method called when text field should return (return tapped) to hide the keyboard

     - parameter textField: textfield in question

     - returns: end editing- true or false
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }

    /**
     Method enables the UI to be interacted with
     */
    func enableUI() {

        self.cancelButton.enabled = true
        self.postButton.enabled = true
        self.titleTextField.enabled = true

    }

    /**
     Method disables the UI to be interacted with
     */
    func disableUI() {

        self.cancelButton.enabled = false
        self.postButton.enabled = false
        self.titleTextField.enabled = false

    }

}
