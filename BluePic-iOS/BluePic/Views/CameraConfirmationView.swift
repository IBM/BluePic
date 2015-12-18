//
//  CameraConfirmationView.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/2/15.
//  Copyright © 2015 MIL. All rights reserved.
//

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

    
    /**
     Return an instance of this view
     
     - returns: an instance of this view
     */
    static func instanceFromNib() -> CameraConfirmationView {
        return UINib(nibName: "CameraConfirmationView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CameraConfirmationView
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
        let localizedString = NSLocalizedString("GIVE IT A TITLE", comment: "")
        self.titleTextField.attributedPlaceholder = NSAttributedString(string:localizedString,
            attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        self.translatesAutoresizingMaskIntoConstraints = true
        self.titleTextField.tintColor = UIColor.whiteColor()
        
    }
    
    /**
     Method called when keyboard will show
     
     - parameter notification: show notification
     */
    func keyboardWillShow(notification:NSNotification) {
        UIApplication.sharedApplication().statusBarHidden = true
        adjustingHeight(true, notification: notification)
    }
    
    /**
     Method called when keyboard will hide
     
     - parameter notification: hide notification
     */
    func keyboardWillHide(notification:NSNotification) {
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    /**
     Method to removed show and hide keyboard observers
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
    func adjustingHeight(show:Bool, notification:NSNotification) {
        // 1
        var userInfo = notification.userInfo!
        // 2
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        // 3
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        // 4
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) * (show ? -1 : 1)
        //5
        if (show){
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.frame = CGRect(x: 0, y: 0 + changeInHeight, width: self.frame.width, height: self.frame.height)
        })
        }
        else {
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.frame = self.originalFrame

            })
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
    
    



}
