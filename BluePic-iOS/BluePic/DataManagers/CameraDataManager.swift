//
//  CameraDataManager.swift
//  BluePic
//
//  Created by Nathan Hekman on 12/2/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit
import ImageIO

class CameraDataManager: NSObject {

    /// Shared instance of data manager
    static let SharedInstance: CameraDataManager = {
        
        var manager = CameraDataManager()
        
        
        return manager
        
    }()
    
    
    private override init() {} //This prevents others from using the default '()' initializer for this class.
    
    
    /// reference to the tab bar vc
    var tabVC: TabBarViewController!
    
    var picker: UIImagePickerController!
    
    var confirmationView: CameraConfirmationView!
    
    var lastPhotoTaken: UIImage!
    
    var lastPhotoTakenName: String!
    
    var lastPhotoTakenURL: String!
    
    var lastPhotoTakenCaption: String!
    
    
    
    
    
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
    
    
    func openGallery()
    {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.tabVC.presentViewController(picker, animated: true, completion:{ _ in
            self.showCameraConfirmation()
        })
        
    }
    
    
    func showCameraConfirmation() {
        self.confirmationView = CameraConfirmationView.instanceFromNib()
        self.confirmationView.frame = CGRect(x: 0, y: 0, width: self.tabVC.view.frame.width, height: self.tabVC.view.frame.height)
        self.confirmationView.originalFrame = self.confirmationView.frame
        
        //set up button actions
        self.confirmationView.cancelButton.addTarget(self, action: "dismissCameraConfirmation", forControlEvents: .TouchUpInside)
        self.confirmationView.postButton.addTarget(self, action: "postPhoto", forControlEvents: .TouchUpInside)
        
        //show view
        self.tabVC.view.addSubview(self.confirmationView)
    }
    
    
    
    
    func dismissCameraConfirmation() {
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
    
    
    func postPhoto() {
        self.lastPhotoTakenCaption = self.confirmationView.titleTextField.text //save caption text
        self.confirmationView.endEditing(true) //dismiss keyboard first if shown
        self.confirmationView.userInteractionEnabled = false
        self.tabVC.view.userInteractionEnabled = false
        self.confirmationView.loadingIndicator.startAnimating()
        self.confirmationView.cancelButton.hidden = true
        self.confirmationView.postButton.hidden = true
        print("uploading photo to object storage...")
        //push to object storage, then on success push to cloudant sync
        ObjectStorageDataManager.SharedInstance.objectStorageClient.uploadImage(FacebookDataManager.SharedInstance.fbUniqueUserID!, imageName: self.lastPhotoTakenName, image: self.lastPhotoTaken,
            onSuccess: { (imageURL: String) in
                print("upload to object storage succeeded.")
                print("imageURL: \(imageURL)")
                print("creating cloudant picture document...")
                self.lastPhotoTakenURL = imageURL
                CloudantSyncClient.SharedInstance.createPictureDoc(self.lastPhotoTakenCaption, fileName: self.lastPhotoTakenName, url: self.lastPhotoTakenURL, ownerID: FacebookDataManager.SharedInstance.fbUniqueUserID!, width: "400", height: "400") //todo: need to find actual width and height, need parameter for picture title?
                CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
            }, onFailure: { (error) in
                print("upload to object storage failed!")
                print("error: \(error)")
                self.confirmationView.loadingIndicator.stopAnimating()
                self.showObjectStorageErrorAlert()
        })
 
    }
    
    /**
     For test method for pre-populating database with images
     */
    func postPhotoForTests(photo: UIImage!, caption: String!, photoName: String!, FBUserID: String!) {
        print("uploading photo to object storage...")
        //push to object storage, then on success push to cloudant sync
        ObjectStorageDataManager.SharedInstance.objectStorageClient.uploadImage(FBUserID, imageName: photoName, image: photo,
            onSuccess: { (imageURL: String) in
                print("upload to object storage succeeded.")
                print("imageURL: \(imageURL)")
                print("creating cloudant picture document...")
                CloudantSyncClient.SharedInstance.createPictureDoc(caption, fileName: photoName, url: imageURL, ownerID: FBUserID, width: "400", height: "400") //todo: need to find actual width and height, need parameter for picture title?
                CloudantSyncClient.SharedInstance.pushToRemoteDatabase()
            }, onFailure: { (error) in
                print("upload to object storage failed!")
                print("error: \(error)")
        })
        
    }
    
    
    
    
    
    func destroyConfirmationView() {
        self.confirmationView.removeKeyboardObservers()
        self.confirmationView.removeFromSuperview()
        self.confirmationView = nil
        
    }
    
    
    
    /**
     Method to show the error alert and asks user if they would like to retry pushing to cloudant
     */
    func showCloudantErrorAlert() {
        //re-enable UI
        self.confirmationView.userInteractionEnabled = true
        self.tabVC.view.userInteractionEnabled = true
        self.confirmationView.loadingIndicator.stopAnimating()
        self.confirmationView.cancelButton.hidden = false
        self.confirmationView.postButton.hidden = false
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred with Cloudant.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action: UIAlertAction!) in

        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tabVC.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    /**
     Method to show the error alert and asks user if they would like to retry pushing to object storage
     */
    func showObjectStorageErrorAlert() {
        //re-enable UI
        self.confirmationView.userInteractionEnabled = true
        self.tabVC.view.userInteractionEnabled = true
        self.confirmationView.loadingIndicator.stopAnimating()
        self.confirmationView.cancelButton.hidden = false
        self.confirmationView.postButton.hidden = false
        
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Oops! An error occurred with Object Storage.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action: UIAlertAction!) in

        }))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tabVC.presentViewController(alert, animated: true, completion: nil)
        }
    }
    

    
    
    
    
}


extension CameraDataManager: UIAlertViewDelegate {
    
    
    
}


extension CameraDataManager: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        //show image on confirmationView, save a copy
        let takenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.confirmationView.photoImageView.image = takenImage
        let photoNSData = takenImage.lowestQualityJPEGNSData
        self.lastPhotoTaken = UIImage(data: photoNSData)
        
        //save name of image as current date and time
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy_HHmmss"
        let todaysDate = NSDate()
        self.lastPhotoTakenName = dateFormatter.stringFromDate(todaysDate) + ".JPG"
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.destroyConfirmationView()
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        print("picker canceled.")
    }
    
    
}

extension CameraDataManager: UINavigationControllerDelegate {
    
    
    
}
