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

//used to inform the Feed View Controller of notifications
enum FeedViewModelNotification {
    
    //called when there is new data in the pictureDataArray, used to tell the Feed VC to refresh it's data in the collection view
    case ReloadCollectionView
    
    //called when a photo is uploading to object storage
    case UploadingPhotoStarted
    
    //called when a photo is finished uploading to object storage
    case UploadingPhotoFinished
}

class FeedViewModel: NSObject {
    
    //array that holds all the image data objects we used to populate the Feed VC's collection view
    var imageDataArray = [Image]()
    
    //callback used to inform the Feed VC of notifications from its view model
    var notifyFeedVC : ((feedViewModelNotification : FeedViewModelNotification)->())!
    
    //string that holds the search query if it is present, meaning we are looking at search results
    var searchQuery: String?
    
    //constant that represents the height of the info view in the collection view cell that shows the photos caption and photographer name
    let kCollectionViewCellInfoViewHeight : CGFloat = 76
    
    //constant that represents the height of the picture upload queue image feed collection view cell
    let kPictureUploadCollectionViewCellHeight : CGFloat = 60
    
    //constant that represents the limit of how tall a collection view cell's height can be
    let kCollectionViewCellHeightLimit : CGFloat = 480
    
    //constant that represents a value added to the height of the EmptyFeedCollectionViewCell when its given a size in the sizeForItemAtIndexPath method, this value allows the collection view to scroll
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling : CGFloat = 1
    
    //constant that defines the number of cells there is when the user has no photos
    let kNumberOfCellsWhenUserHasNoPhotos = 1
    
    //constant that defines the number of sections there are in the collection view
    let kNumberOfSectionsInCollectionView = 2
    
    
    /**
     Method called upon init. It sets a callback to inform the VC of new notification
     
     - parameter passFeedViewModelNotificationToTabBarVCCallback: ((feedViewModelNotification : FeedViewModelNotification)->())
     
     - returns:
     */
    init(notifyFeedVC : ((feedViewModelNotification : FeedViewModelNotification)->()), searchQuery: String?){
        super.init()

        //save callback to notify Feed View Controller of events
        self.notifyFeedVC = notifyFeedVC
        self.searchQuery = searchQuery
     
        //suscribe to events that happen in the BluemixDataManager
        suscribeToBluemixDataManagerNotifications()
        
        if let query = searchQuery {
            BluemixDataManager.SharedInstance.getImagesByTags([query])
        } else {
            //Grab any data from BluemixDataManager if it has any and then tell view controller to reload its collection view
            updateImageDataArrayAndNotifyViewControllerToReloadCollectionView()
        }
        
    }
    
    
    func suscribeToBluemixDataManagerNotifications(){
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedViewModel.updateImageDataArrayAndNotifyViewControllerToReloadCollectionView), name: BluemixDataManagerNotification.ImagesRefreshed.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedViewModel.repullForNewData), name: BluemixDataManagerNotification.ImageUploadSuccess.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedViewModel.notifyViewControllerToTriggerLoadingAnimation), name: CameraDataManagerNotification.UserPressedPostPhoto.rawValue, object: nil)
        
    }

    
    func updateImageDataArrayAndNotifyViewControllerToReloadCollectionView(){
        
        self.imageDataArray = searchQuery == nil ? BluemixDataManager.SharedInstance.images : BluemixDataManager.SharedInstance.searchResultImages
        
        self.notifyViewControllerToTriggerReloadCollectionView()
    }
    
}




//ViewController -> ViewModel Communication
extension FeedViewModel {
    
    func shouldBeginLoading() -> Bool {
        return !BluemixDataManager.SharedInstance.hasReceievedInitialImages
    }
    
    
    func repullForNewData() {
        if let query = self.searchQuery {
            BluemixDataManager.SharedInstance.getImagesByTags([query])
        } else {
            BluemixDataManager.SharedInstance.getImages()
        }
    }
    
    /**
     Method returns the number of sections in the collection view
     
     - returns: Int
     */
    func numberOfSectionsInCollectionView() -> Int {
        return kNumberOfSectionsInCollectionView
    }
    
    
    /**
     Method returns the number of items in a section
     
     - parameter section: Int
     
     - returns: Int
     */
    func numberOfItemsInSection(section : Int) -> Int {
        //if the section is 0, then it depends on how many items are in the picture upload queue
        if(section == 0){
            return BluemixDataManager.SharedInstance.imageUploadQueue.count
        }
            // if the section is 1, then it depends how many items are in the pictureDataArray
        else{
            
            if(imageDataArray.count == 0) && BluemixDataManager.SharedInstance.hasReceievedInitialImages{
                return kNumberOfCellsWhenUserHasNoPhotos
            }
            else{
                return imageDataArray.count
            }
        }
    }
    
    
    
    /**
     Method returns the size for item at index path
     
     - parameter indexPath: NSIndexPath
     - parameter collectionView: UICollectionViewcell
     
     - returns: CGSize
     */
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView) -> CGSize {
        
        //Section 0 corresponds to showing picture upload queue image feed collection view cells. These cells show when there are pictures in the picture upload queue of the camera data manager
        if(indexPath.section == 0){
            return CGSize(width: collectionView.frame.width, height: kPictureUploadCollectionViewCellHeight)
        }
            
            //section 1 corresponds to either the empty feed collection view cell or the standard image feed collection view cell depending on how many images are in the picture data array
        else{
            
            //return size for empty feed collection view cell
            if(imageDataArray.count == 0){
                
                return CGSize(width: collectionView.frame.width, height: collectionView.frame.height + kEmptyFeedCollectionViewCellBufferToAllowForScrolling)
                
            }
                //return size for image feed collection view cell
            else{
                
                let image = imageDataArray[indexPath.row]
                
                if let width = image.width, let height = image.height {
                    
                    let ratio = height / width
                    
                    var height = collectionView.frame.width * ratio
                    
                    if(height > kCollectionViewCellHeightLimit){
                        height = kCollectionViewCellHeightLimit
                    }
                    
                    return CGSize(width: collectionView.frame.width, height: height + kCollectionViewCellInfoViewHeight)
                    
                }
                else{
                    return CGSize(width: collectionView.frame.width, height: collectionView.frame.width + kCollectionViewCellInfoViewHeight)
                }
            }
        }
    }
    
    
    /**
     Method sets up the collection view for indexPath. If the the pictureDataArray is 0, then it shows the EmptyFeedCollectionViewCell
     
     - parameter indexPath:      indexPath
     - parameter collectionView: UICollectionView
     
     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        //Section 0 corresponds to showing picture upload queue image feed collection view cells. These cells show when there are pictures in the picture upload queue of the camera data manager
        if(indexPath.section == 0){
            
            let cell : PictureUploadQueueImageFeedCollectionViewCell
            
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureUploadQueueImageFeedCollectionViewCell", forIndexPath: indexPath) as! PictureUploadQueueImageFeedCollectionViewCell
            
            
            let image = BluemixDataManager.SharedInstance.imageUploadQueue[indexPath.row]
            
            cell.setupData(image.image, caption: image.caption)
            
            return cell
            
        }
            //section 1 corresponds to either the empty feed collection view cell or the standard image feed collection view cell depending on how many images are in the picture data array
        else{
            
            //return EmptyFeedCollectionViewCell
            if(imageDataArray.count == 0){
                
                let cell : EmptyFeedCollectionViewCell
                
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyFeedCollectionViewCell", forIndexPath: indexPath) as! EmptyFeedCollectionViewCell
                
                return cell
                
            }
                //return ImageFeedCollectionViewCell
            else{
                
                let cell: ImageFeedCollectionViewCell
                
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageFeedCollectionViewCell", forIndexPath: indexPath) as! ImageFeedCollectionViewCell
                
                let image = imageDataArray[indexPath.row]
                
                cell.setupData(
                    image.url,
                    image: nil, //MIGHT NEED TO FIX
                    caption: image.caption,
                    usersName: image.user?.name,
                    timeStamp: image.timeStamp,
                    fileName: image.fileName
                )
                
                cell.layer.shouldRasterize = true
                cell.layer.rasterizationScale = UIScreen.mainScreen().scale
                
                return cell
            }
        }
    }
    
    
    func prepareImageDetailViewControllerSelectedCellAtIndexPath(indexPath : NSIndexPath) -> ImageDetailViewController {
        
         let imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as! ImageDetailViewController
        
        imageDetailVC.image = imageDataArray[indexPath.row]
        
        
        return imageDetailVC
        
    }
    
    
    
  
 
}




//View Model -> ViewController Communication
extension FeedViewModel {
    
    func notifyViewControllerToTriggerLoadingAnimation(){
        
        dispatch_async(dispatch_get_main_queue()) {
            self.notifyFeedVC(feedViewModelNotification: FeedViewModelNotification.UploadingPhotoStarted)
        }
    }
    
    func notifyViewControllerToTriggerReloadCollectionView(){
        dispatch_async(dispatch_get_main_queue()) {
            self.notifyFeedVC(feedViewModelNotification : FeedViewModelNotification.ReloadCollectionView)
        }
    }
    
    
    
    
}
