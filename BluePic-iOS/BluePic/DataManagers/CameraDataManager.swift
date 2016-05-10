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
import ImageIO

/// Singleton to hold any state with showing the camera picker. Allows user to upload a photo to BluePic
class CameraDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: CameraDataManager = {
        
        var manager = CameraDataManager()
        
        
        return manager
        
    }()
    
    
    private override init() {} //This prevents others from using the default '()' initializer for this class.
    
    
    /// reference to the tab bar vc
    var tabVC: TabBarViewController!
    
    /// Image picker
    var picker: UIImagePickerController!
    
    /// ConfirmationView to be shown after selecting or taking a photo (add a caption here)
    var confirmationView: CameraConfirmationView!
    
    var lastImageTaken: Image!
    
    /// Constant for how wide all images should be constrained to when compressing for upload (600 results in ~1.2 MB photos)
    let kResizeAllImagesToThisWidth = CGFloat(600)
    
    /// photos that were taken during this app session
    var imagesTakenDuringAppSessionById = [String : UIImage]()
    
    // An array of photos that need to be uploaded to object storage and cloudant sync
    var imageUploadQueue : [Image] = []
    
    
    /**
     Method to show the image picker action sheet so user can choose from Photo Library or Camera
     
     - parameter presentingVC: tab VC to present over top of
     */
    func showImagePickerActionSheet(presentingVC: TabBarViewController!) {
        self.tabVC = presentingVC
        self.picker = UIImagePickerController()
        let alert:UIAlertController=UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cameraAction = UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                self.openGallery()
        }
        let galleryAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                self.openCamera()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel)
            {
                UIAlertAction in
        }
        
        // Add the actions
        picker?.delegate = self
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        
        // on iPad, this will be a Popover
        // on iPhone, this will be an action sheet
        alert.modalPresentationStyle = .Popover
        
        
        // Present the controller
        self.tabVC.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    
    /**
     Method called when user wants to take a photo with the camera
     */
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            picker!.sourceType = UIImagePickerControllerSourceType.Camera
            self.tabVC.presentViewController(picker, animated: true, completion: { _ in
                self.showCameraConfirmation()
            })
        }
        else
        {
            openGallery()
        }
    }
    
    
    /**
     Method called when user wants to choose a photo from Photo Album for posting
     */
    func openGallery()
    {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.tabVC.presentViewController(picker, animated: true, completion:{ _ in
            self.showCameraConfirmation()
        })
        
    }
    
    
    /**
     Method to show the camera confirmation view for adding a caption and posting
     */
    func showCameraConfirmation() {
        self.confirmationView = CameraConfirmationView.instanceFromNib()
        self.confirmationView.frame = CGRect(x: 0, y: 0, width: self.tabVC.view.frame.width, height: self.tabVC.view.frame.height)
        self.confirmationView.originalFrame = self.confirmationView.frame
        
        //set up button actions
        self.confirmationView.cancelButton.addTarget(self, action: #selector(CameraDataManager.dismissCameraConfirmation), forControlEvents: .TouchUpInside)
        self.confirmationView.postButton.addTarget(self, action: #selector(CameraDataManager.postPhoto), forControlEvents: .TouchUpInside)
        
        //show view
        self.tabVC.view.addSubview(self.confirmationView)
    }
    
    
    /**
     Method called when user presses "post Photo" on confirmation view
     */
    func postPhoto() {
        self.lastImageTaken.caption = self.confirmationView.titleTextField.text //save caption text
        self.confirmationView.endEditing(true) //dismiss keyboard first if shown
        self.confirmationView.userInteractionEnabled = false
        self.tabVC.view.userInteractionEnabled = false
        self.confirmationView.loadingIndicator.startAnimating()
        self.confirmationView.cancelButton.hidden = true
        self.confirmationView.postButton.hidden = true
        
        //Dismiss Camera Confirmation View when user presses post photo to bring user back to image feed
        dismissCameraConfirmation()
        
        BluemixDataManager.SharedInstance.uploadImage(lastImageTaken)
    }
    
    /**
     Method to hide the confirmation view when cancelling or done uploading
     */
    func dismissCameraConfirmation() {
        UIApplication.sharedApplication().statusBarHidden = false
        self.confirmationView.loadingIndicator.stopAnimating()
        self.confirmationView.endEditing(true) //dismiss keyboard first if shown
        UIView.animateWithDuration(0.4, animations: { _ in
            self.confirmationView.frame = CGRect(x: 0, y: self.tabVC.view.frame.height, width: self.tabVC.view.frame.width, height: self.tabVC.view.frame.height)
            }, completion: { _ in
                self.destroyConfirmationView()
                self.tabVC.view.userInteractionEnabled = true
                print("picker dismissed from confirmation view.")
        })
        
    }
    
    
    /**
     Method to remove the confirmation view from memory when finished with it
     */
    func destroyConfirmationView() {
        self.confirmationView.removeKeyboardObservers()
        self.confirmationView.removeFromSuperview()
        self.confirmationView = nil
    }
    

    /**
     Alert to be shown if photo couldn't be loaded from disk (iCloud photo stream photo not loaded, for example)
     */
    func showPhotoCouldntBeChosenAlert() {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("This photo couldn't be loaded. Please use a different one!", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action: UIAlertAction!) in
            self.openGallery()
        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tabVC.presentViewController(alert, animated: true, completion: nil)
        }
        
    }

    
    /**
     Method to rotate image taken if necessary
     
     - parameter imageToRotate: UIImage!
     
     - returns: UIImage1
     */
    func rotateImageIfNecessary(imageToRotate: UIImage!) -> UIImage! {
        let imageOrientation = imageToRotate.imageOrientation.rawValue
        switch imageOrientation {
        case 0: //Up
            return imageToRotate.imageRotatedByDegrees(0, flip: false)
        case 1: //Down
            return imageToRotate.imageRotatedByDegrees(180, flip: false)
        case 2: //Left
            return imageToRotate.imageRotatedByDegrees(270, flip: false)
        case 3: //Right
            return imageToRotate.imageRotatedByDegrees(90, flip: false)
        default:
            return imageToRotate.imageRotatedByDegrees(0, flip: false)
        }
    }

}


extension CameraDataManager: UIImagePickerControllerDelegate {
    
    
    /**
     Method is called after the user takes a photo or chooses a photo from their photo library. This method will save information about the photo taken which will help us handle errors if the photo fails to save and upload to cloudant and object storage
     
     - parameter picker: UIImagePickerController
     - parameter info:   [String : AnyObject]
     */
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        self.lastImageTaken = Image()
        
        lastImageTaken.usersId = CurrentUser.facebookUserId
        lastImageTaken.usersName = CurrentUser.fullName
        
        //show image on confirmationView, save a copy
        if let takenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print("original image width: \(takenImage.size.width) height: \(takenImage.size.height)")
            if (takenImage.size.width > kResizeAllImagesToThisWidth) { //if image too big, shrink it down
                self.lastImageTaken.image = UIImage.resizeImage(takenImage, newWidth: kResizeAllImagesToThisWidth)
            }
            else {
                self.lastImageTaken.image = takenImage
            }
            
            //rotate image if necessary and then save photo
            self.lastImageTaken.image = self.rotateImageIfNecessary(self.lastImageTaken.image)
            
            //save width and height of photo
            self.lastImageTaken.width = self.lastImageTaken.image?.size.width
            self.lastImageTaken.height = self.lastImageTaken.image?.size.height
            
            //set the confirmation view's photoImageView with the photo just chosen/taken
            self.confirmationView.photoImageView.image = self.lastImageTaken.image
        
            //save name of image as current date and time
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy_HHmmss"
            let todaysDate = NSDate()
            self.lastImageTaken.fileName = dateFormatter.stringFromDate(todaysDate) + ".png"

            }
            //if image isn't available (iCloud photo in Photo stream not loaded yet)
            else { 
                self.destroyConfirmationView()
                picker.dismissViewControllerAnimated(true, completion: { _ in
                
                    })
                self.showPhotoCouldntBeChosenAlert()
                print("picker canceled - photo not available!")
            
            }
    }
    
    
//    func prepareImageObjectFromPickerInfoDictionary(){
//        
//        picker.dismissViewControllerAnimated(true, completion: nil)
//        
//        self.lastImageTaken = Image()
//        
//        lastImageTaken.usersId = CurrentUser.facebookUserId
//        lastImageTaken.usersName = CurrentUser.fullName
//        
//        //show image on confirmationView, save a copy
//        if let takenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            print("original image width: \(takenImage.size.width) height: \(takenImage.size.height)")
//            if (takenImage.size.width > kResizeAllImagesToThisWidth) { //if image too big, shrink it down
//                self.lastImageTaken.image = UIImage.resizeImage(takenImage, newWidth: kResizeAllImagesToThisWidth)
//            }
//            else {
//                self.lastImageTaken.image = takenImage
//            }
//            
//            //rotate image if necessary and then save photo
//            self.lastImageTaken.image = self.rotateImageIfNecessary(self.lastImageTaken.image)
//            
//            //save width and height of photo
//            self.lastImageTaken.width = self.lastImageTaken.image?.size.width
//            self.lastImageTaken.height = self.lastImageTaken.image?.size.height
//            
//            //set the confirmation view's photoImageView with the photo just chosen/taken
//            self.confirmationView.photoImageView.image = self.lastImageTaken.image
//            
//            //save name of image as current date and time
//            let dateFormatter = NSDateFormatter()
//            dateFormatter.dateFormat = "MM-dd-yyyy_HHmmss"
//            let todaysDate = NSDate()
//            self.lastImageTaken.fileName = dateFormatter.stringFromDate(todaysDate) + ".png"
//            
//        }
//            //if image isn't available (iCloud photo in Photo stream not loaded yet)
//        else {
//            self.destroyConfirmationView()
//            picker.dismissViewControllerAnimated(true, completion: { _ in
//                
//            })
//            self.showPhotoCouldntBeChosenAlert()
//            print("picker canceled - photo not available!")
//            
//        }
//        
//    
//    }
    
    
    
    
    /**
     Method is called when the user decides to cancel taking a photo or choosing a photo from their photo library.
     
     - parameter picker: UIImagePickerController
     */
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.destroyConfirmationView()
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        print("picker canceled.")
    }
    
    
}

extension CameraDataManager: UINavigationControllerDelegate {
    
}
