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
    
    var lastPhotoTakenWidth : CGFloat!
    
    var lastPhotoTakenHeight : CGFloat!
    
    var lastPictureObjectTaken : Picture!
    
    let kResizeAllImagesToThisWidth = CGFloat(600)
    
    var pictureUploadQueue : [Picture] = [Picture]()
    
    var picturesTakenDuringAppSessionById = [String : UIImage]()
    

    
    
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
        self.createLastPictureObjectTakenAndAddToPictureUploadQueue()
        dismissCameraConfirmation()
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.UserDecidedToPostPhoto)
        self.uploadImageToObjectStorage()
 
    }
    
    
    func uploadImageToObjectStorage() {
        print("uploading photo to object storage...")
        //push to object storage, then on success push to cloudant sync
        ObjectStorageDataManager.SharedInstance.objectStorageClient.uploadImage(FacebookDataManager.SharedInstance.fbUniqueUserID!, imageName: self.lastPhotoTakenName, image: self.lastPhotoTaken,
            onSuccess: { (imageURL: String) in
                print("upload to object storage succeeded.")
                print("imageURL: \(imageURL)")
                print("creating cloudant picture document...")
                self.lastPhotoTakenURL = imageURL
                print("image orientation is: \(self.lastPhotoTaken.imageOrientation.rawValue), width: \(self.lastPhotoTaken.size.width) height: \(self.lastPhotoTaken.size.height)")
                do {
                    try CloudantSyncClient.SharedInstance!.createPictureDoc(self.lastPhotoTakenCaption, fileName: self.lastPhotoTakenName, url: self.lastPhotoTakenURL, ownerID: FacebookDataManager.SharedInstance.fbUniqueUserID!, width: "\(self.lastPhotoTaken.size.width)", height: "\(self.lastPhotoTaken.size.height)", orientation: "\(self.lastPhotoTaken.imageOrientation.rawValue)")
                } catch {
                    print("uploadImageToObjectStorage ERROR: \(error)")
                    DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantCreatePictureFailure)
                }
                
                do {
                    try CloudantSyncClient.SharedInstance!.pushToRemoteDatabase()
                } catch {
                    print("uploadImageToObjectStorage ERROR: \(error)")
                    DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataFailure)
                }
                
            }, onFailure: { (error) in
                print("upload to object storage failed!")
                print("error: \(error)")
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.ObjectStorageUploadError)
        })
        
        
    }
    
    
    func createLastPictureObjectTakenAndAddToPictureUploadQueue(){
        
        
        lastPictureObjectTaken = Picture()
        //lastPictureObjectTaken.image = lastPhotoTaken
        lastPictureObjectTaken.displayName = lastPhotoTakenCaption
        lastPictureObjectTaken.ownerName = FacebookDataManager.SharedInstance.fbUserDisplayName
        lastPictureObjectTaken.width = lastPhotoTakenWidth
        lastPictureObjectTaken.height = lastPhotoTakenHeight
        lastPictureObjectTaken.timeStamp = NSDate.timeIntervalSinceReferenceDate()
        lastPictureObjectTaken.fileName = lastPhotoTakenName
        
        pictureUploadQueue.append(lastPictureObjectTaken)
        
        if let fileName = lastPictureObjectTaken.fileName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
            
            let id = fileName + userID
            
            print("setting is as \(id)")
            picturesTakenDuringAppSessionById[id] = lastPhotoTaken

        }
        
    
    }
    
    func clearPictureUploadQueue(){
        pictureUploadQueue = []
    }
    
    
    
    
    func destroyConfirmationView() {
        self.confirmationView.removeKeyboardObservers()
        self.confirmationView.removeFromSuperview()
        self.confirmationView = nil
        
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
        print("original image width: \(takenImage.size.width) height: \(takenImage.size.height)")
        if (takenImage.size.width > kResizeAllImagesToThisWidth) { //if image too big, shrink it down
            self.lastPhotoTaken = UIImage.resizeImage(takenImage, newWidth: kResizeAllImagesToThisWidth)
        }
        
        self.lastPhotoTakenWidth = self.lastPhotoTaken.size.width
        self.lastPhotoTakenHeight = self.lastPhotoTaken.size.height
        print("resized image width: \(self.lastPhotoTaken.size.width) height: \(self.lastPhotoTaken.size.height)")
        self.confirmationView.photoImageView.image = self.lastPhotoTaken

        
        
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
