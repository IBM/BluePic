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
    
    /// Copy of last photo taken
    var lastPhotoTaken: UIImage!
    
    /// Copy of name of last photo taken
    var lastPhotoTakenName: String!
    
    /// Copy of last photo taken url
    var lastPhotoTakenURL: String!
    
    /// Copy of last photo taken caption
    var lastPhotoTakenCaption: String!
    
    /// Copy of width of last photo
    var lastPhotoTakenWidth : CGFloat!
    
    /// Copy of height of last photo
    var lastPhotoTakenHeight : CGFloat!
    
    /// Copy of last photo taken Picture Model Object
    var lastPictureObjectTaken : Picture!
    
    var lastPictureTakenCDTDocumentRevision : CDTDocumentRevision?
    
    /// Constant for how wide all images should be constrained to when compressing for upload (600 results in ~1.2 MB photos)
    let kResizeAllImagesToThisWidth = CGFloat(600)
    
    /// photos that were taken during this app session
    var picturesTakenDuringAppSessionById = [String : UIImage]()
    
    
    var pictureUploadQueue : [Picture] = []
    
    
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
        self.confirmationView.cancelButton.addTarget(self, action: "dismissCameraConfirmation", forControlEvents: .TouchUpInside)
        self.confirmationView.postButton.addTarget(self, action: "postPhoto", forControlEvents: .TouchUpInside)
        
        //show view
        self.tabVC.view.addSubview(self.confirmationView)
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
    
    
    func addPhotoToPictureUploadQueue() -> Picture{
        
        let newPicture = Picture()
        //lastPictureObjectTaken.image = lastPhotoTaken
        newPicture.image = lastPhotoTaken
        newPicture.displayName = lastPhotoTakenCaption
        newPicture.ownerName = FacebookDataManager.SharedInstance.fbUserDisplayName
        newPicture.width = lastPhotoTakenWidth
        newPicture.height = lastPhotoTakenHeight
        newPicture.timeStamp = NSDate.timeIntervalSinceReferenceDate()
        newPicture.fileName = lastPhotoTakenName
        newPicture.displayName = lastPhotoTakenCaption
        pictureUploadQueue.append(newPicture)
        
        return newPicture
    }
    
    
    func removePictureFromPictureUploadQueue(picture : Picture){
        
        pictureUploadQueue = pictureUploadQueue.filter({ $0 !== picture})
        
    }
    
    
//    func createLastPictureObjectTakenAndAddToPictureUploadQueue(){
//        
//        
//        lastPictureObjectTaken = Picture()
//        //lastPictureObjectTaken.image = lastPhotoTaken
//        lastPictureObjectTaken.displayName = lastPhotoTakenCaption
//        lastPictureObjectTaken.ownerName = FacebookDataManager.SharedInstance.fbUserDisplayName
//        lastPictureObjectTaken.width = lastPhotoTakenWidth
//        lastPictureObjectTaken.height = lastPhotoTakenHeight
//        lastPictureObjectTaken.timeStamp = NSDate.timeIntervalSinceReferenceDate()
//        lastPictureObjectTaken.fileName = lastPhotoTakenName
//        
//        pictureUploadQueue.append(lastPictureObjectTaken)
//        
//        if let fileName = lastPictureObjectTaken.fileName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
//            
//            let id = fileName + userID
//            
//            print("setting is as \(id)")
//            picturesTakenDuringAppSessionById[id] = lastPhotoTaken
//            
//        }
//        
//        
//    }
    
    
    /**
     Method called when user presses "post Photo" on confirmation view
     */
    func postPhoto() {
        self.lastPhotoTakenCaption = self.confirmationView.titleTextField.text //save caption text
        self.confirmationView.endEditing(true) //dismiss keyboard first if shown
        self.confirmationView.userInteractionEnabled = false
        self.tabVC.view.userInteractionEnabled = false
        self.confirmationView.loadingIndicator.startAnimating()
        self.confirmationView.cancelButton.hidden = true
        self.confirmationView.postButton.hidden = true
        self.addPhotoToPictureTakenDuringAppSessionByIdDictionary()
        let picture = self.addPhotoToPictureUploadQueue()
        dismissCameraConfirmation()
        
    
        //let pictureDoc = createPictureDocBeforeWeUploadToObjectStorage()
        
        //lastPictureTakenCDTDocumentRevision = pictureDoc
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.UserDecidedToPostPhoto)

       tryToUploadImageToObjectStorage(picture)
    }
    
    
    func uploadPhotosIfThereAreAnyLeftInTheQueue(){
        
        if(pictureUploadQueue.count > 0){
            uploadImageToObjectStorage(pictureUploadQueue[0])
        }
    }
    
    func tryToUploadImageToObjectStorage(picture : Picture){
        
        
        if(pictureUploadQueue.count == 1){
            uploadImageToObjectStorage(picture)
        }
  
    }
    
    
    func tryToPushToCloudantSync(){
        if(pictureUploadQueue.count == 0){
            do {
                try CloudantSyncDataManager.SharedInstance!.pushToRemoteDatabase()
            } catch {
                print("uploadImageToObjectStorage ERROR: \(error)")
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPushDataFailure)
            }
        }
    }
    
    
    
     /**
     Method called to push image to object storage, on sucuess create picture document with url from object storage and push to cloudant sync if there are no more picture in the queue, else try uploading the rest of the photos in the queue
     */
    func uploadImageToObjectStorage(picture : Picture) {
        print("uploading photo to object storage...")

        ObjectStorageDataManager.SharedInstance.objectStorageClient.uploadImage(FacebookDataManager.SharedInstance.fbUniqueUserID!, imageName: picture.fileName!, image: picture.image!,
            onSuccess: { (imageURL: String) in
                print("upload to object storage succeeded.")
                print("imageURL: \(imageURL)")
                
                //update picture object with new image url received from on success from Object Storage
                picture.url = imageURL
                
                //create the picture document with Cloudant Sync
                print("creating cloudant picture document...")
                self.createPictureDoc(picture)
                
                //Once picture has been added to Cloudant Sync, remove this picture from our picture upload queue
                self.removePictureFromPictureUploadQueue(picture)
                
                //tell view models that we have successfully uploading the picture to object storage and added the picture to cloudant sync
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.ObjectStorageUploadImageAndCloudantCreatePictureDocSuccess)
                
                //try to push new changes to cloudant sync if there are no more picture in the picture upload queue
                self.tryToPushToCloudantSync()
                
                //if there are more pictures in the picture upload queue, continue on to upload those pictures following the same process.
                self.uploadPhotosIfThereAreAnyLeftInTheQueue()

                
            }, onFailure: { (error) in
                print("upload to object storage failed!")
                print("error: \(error)")
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.ObjectStorageUploadError)
        })
    }
    
    

    
    
    
    
    /**
     Method cancels uploading a picture to object storage by deleting the picture doc created before trying to upload to object storage
     */
    func cancelUploadingPictureToObjectStorage(){
        
        pictureUploadQueue = []
        
        DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.UserCanceledUploadingPhotos)
        
//        if let pictureDoc = lastPictureTakenCDTDocumentRevision {
//            do {
//                let success = try CloudantSyncDataManager.SharedInstance!.deletePictureDoc(pictureDoc)
//                
//                if(success == true){
//                    DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantDeletePictureDocSuccess)
//                }
//            }
//            catch {
//                print("uploadImageToObjectStorage ERROR: \(error)")
//            }
//        }
        
    }
    
    
    
    /**
     Method creates a picture doc before trying to upload to object storage
     
     - returns: CDTDocumentRevision?
     */
    func createPictureDoc(picture : Picture) {
        do {
            try CloudantSyncDataManager.SharedInstance!.createPictureDoc(picture.displayName!, fileName: picture.fileName!, url: picture.url!, ownerID: FacebookDataManager.SharedInstance.fbUniqueUserID!, width: "\(picture.width!)", height: "\(picture.height!)")
            
        } catch {
            print("cloudantCreatePictureFailure ERROR: \(error)")
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantCreatePictureFailure)
        }
    
    }
    
    
    /**
     Method adds the photo to the picturesTakenDuringAppSessionById cache to display the photo in the image feed while we wait for the photo to upload to.
     */
    func addPhotoToPictureTakenDuringAppSessionByIdDictionary(){
        
        if let fileName = lastPhotoTakenName, let userID = FacebookDataManager.SharedInstance.fbUniqueUserID {
            
            let id = fileName + userID
            
            print("setting is as \(id)")
            picturesTakenDuringAppSessionById[id] = lastPhotoTaken
            
        }
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
        
        //show image on confirmationView, save a copy
        if let takenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
        print("original image width: \(takenImage.size.width) height: \(takenImage.size.height)")
        if (takenImage.size.width > kResizeAllImagesToThisWidth) { //if image too big, shrink it down
            self.lastPhotoTaken = UIImage.resizeImage(takenImage, newWidth: kResizeAllImagesToThisWidth)
        }
        else {
            self.lastPhotoTaken = takenImage
        }
            
        //rotate image if necessary
        self.lastPhotoTaken = self.rotateImageIfNecessary(self.lastPhotoTaken)
        
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
        else { //if image isn't available (iCloud photo in Photo stream not loaded yet)
            self.destroyConfirmationView()
            picker.dismissViewControllerAnimated(true, completion: { _ in
                
                
                })
            self.showPhotoCouldntBeChosenAlert()
            print("picker canceled - photo not available!")
            
        }
    }
    
    
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
