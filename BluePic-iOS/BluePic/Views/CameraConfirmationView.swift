//
//  CameraConfirmationView.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/2/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class CameraConfirmationView: UIView, UITextFieldDelegate {

    @IBOutlet weak var photoImageView: UIImageView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var postButton: UIButton!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    var originalFrame: CGRect!
    var originalSize: CGSize!
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
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
    
    
    func setupView() {
        let localizedString = NSLocalizedString("GIVE IT A TITLE", comment: "")
        self.titleTextField.attributedPlaceholder = NSAttributedString(string:localizedString,
            attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        self.translatesAutoresizingMaskIntoConstraints = true
        self.titleTextField.tintColor = UIColor.whiteColor()
        
    }
    
    func keyboardWillShow(notification:NSNotification) {
        adjustingHeight(true, notification: notification)
    }
    
    func keyboardWillHide(notification:NSNotification) {
        adjustingHeight(false, notification: notification)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.endEditing(true)
    }
    
    
    func addKeyboardObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
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
    

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
    
    



}
