/**
 * Copyright IBM Corporation 2016, 2017
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
    fileprivate let kTextFieldPlaceholderText = NSLocalizedString("GIVE IT A TITLE", comment: "")

    /**
     Return an instance of this view

     - returns: an instance of this view
     */
    static func instanceFromNibWithFrame(_ frame: CGRect) -> CameraConfirmationView? {
        guard let cameraConfirmationView = UINib(nibName: "CameraConfirmationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? CameraConfirmationView else {
            print(NSLocalizedString("Unable to load camera confirmation view from nib", comment: ""))
            return nil
        }

        cameraConfirmationView.frame = frame
        cameraConfirmationView.originalFrame = frame

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
            attributes:[NSAttributedStringKey.foregroundColor: UIColor.gray])
        self.translatesAutoresizingMaskIntoConstraints = true
        self.titleTextField.tintColor = UIColor.white

    }

    /**
     Method called when keyboard will show

     - parameter notification: show notification
     */
    @objc func keyboardWillShow(_ notification: Notification) {
        UIApplication.shared.isStatusBarHidden = true
        adjustingHeight(true, notification: notification)
    }

    /**
     Method called when keyboard will hide

     - parameter notification: hide notification
     */
    @objc func keyboardWillHide(_ notification: Notification) {
        adjustingHeight(false, notification: notification)
    }

    /**
     Method called when touches began to hide keyboard

     - parameter touches: touches that began
     - parameter event:   event when touches began
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }

    /**
     Method to add show and hide keyboard observers
     */
    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(CameraConfirmationView.keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CameraConfirmationView.keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    /**
     Method to remove show and hide keyboard observers
     */
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    /**
     Method to move the whole view up/down when user pulls the keyboard up/down

     - parameter show:         whether or raise or lower view
     - parameter notification: hide or show notification called
     */
    func adjustingHeight(_ show: Bool, notification: Notification) {
        // 1
        if let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
        // 2
        let keyboardFrame  = keyboardFrameValue.cgRectValue
        // 3
        let changeInHeight = (keyboardFrame.height) * (show ? -1 : 1)
        //4
        if show {
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                self.frame = CGRect(x: 0, y: 0 + changeInHeight, width: self.frame.width, height: self.frame.height)
            })
        } else {
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }

    /**
     Method enables the UI to be interacted with
     */
    func enableUI() {

        self.postButton.isEnabled = true
        self.titleTextField.isEnabled = true

    }

    /**
     Method disables the UI to be interacted with
     */
    func disableUI() {

        self.postButton.isEnabled = false
        self.titleTextField.isEnabled = false

    }

}
