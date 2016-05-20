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

class ProfileViewModel: NSObject {
    
    //array that holds all that pictures that are displayed in the collection view
    //var pictureDataArray = [Picture]()
    var imageDataArray = [Image]()
    
    //callback used to tell the ProfileViewController when to refresh its collection view
    var refreshVCCallback : (()->())!
    
    //constant that represents the number of sections in the collection view
    let kNumberOfSectionsInCollectionView = 1
    
    //constant that represents the height of the info view in the collection view cell that shows the photos caption and photographer name
    let kCollectionViewCellInfoViewHeight : CGFloat = 60
    
    //constant that represents the limit of how big the colection view cell height can be
    let kCollectionViewCellHeightLimit : CGFloat = 480
    
    //constant that represents a value added to the height of the EmptyFeedCollectionViewCell when its given a size in the sizeForItemAtIndexPath method, this value allows the collection view to scroll
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling : CGFloat = 1
    
    //constant that represents the number of cells in the collection view when there is no photos
    let kNumberOfCellsWhenUserHasNoPhotos = 1
    
    
    /**
     Method called upon init, it sets up the callback to refresh the profile collection view
     
     - parameter refreshVCCallback: (()->())
     
     - returns:
     */
    init(refreshVCCallback : (()->())){
       super.init()
        
        self.refreshVCCallback  = refreshVCCallback
        
        suscribeToBluemixDataManagerNotifications()
        
        updateImageArrayAndNotifyViewControllerToReloadCollectionView()
        
    }
    
    func suscribeToBluemixDataManagerNotifications(){
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewModel.updateImageArrayAndNotifyViewControllerToReloadCollectionView), name: BluemixDataManagerNotification.ImagesRefreshed.rawValue, object: nil)
        
    }
    
    
    func updateImageArrayAndNotifyViewControllerToReloadCollectionView(){
        
        self.imageDataArray = BluemixDataManager.SharedInstance.currentUserImages
        
        dispatch_async(dispatch_get_main_queue()) {
            self.callRefreshCallBack()
        }
        
    }

    
    /**
     Method tells the profile view controller to reload its collectionView
     */
    func callRefreshCallBack(){
        if let callback = refreshVCCallback {
            callback()
        }
    }
 
    
}


//View Controller -> View Model Communication
extension ProfileViewModel {
    
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
        
        if(imageDataArray.count == 0) {
            return kNumberOfCellsWhenUserHasNoPhotos
        }
        else {
            return imageDataArray.count
        }
    }
    
    
    /**
     Method returns the size for item at indexPath
     
     - parameter indexPath:                               NSIndexPath
     - parameter collectionView:                          UICollectionView
     - parameter heightForEmptyProfileCollectionViewCell: CGFloat
     
     - returns: CGSize
     */
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView, heightForEmptyProfileCollectionViewCell : CGFloat) -> CGSize {
        
        if(imageDataArray.count == 0) {
            
            return CGSize(width: collectionView.frame.width, height: heightForEmptyProfileCollectionViewCell + kEmptyFeedCollectionViewCellBufferToAllowForScrolling)
        }
        else{
            
            let picture = imageDataArray[indexPath.row]
            
            
            if let width = picture.width, let height = picture.height {
                
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
    
    
    /**
     Method sets up the collection view cell for indexPath. If the pictureDataArray.count is equal to 0 then we return an instance EmptyfeedCollectionviewCell
     
     - parameter indexPath:      NSIndexPath
     - parameter collectionView: UICollectionViewCell
     
     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        if(imageDataArray.count == 0){
            
            let cell: EmptyFeedCollectionViewCell
            
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyFeedCollectionViewCell", forIndexPath: indexPath) as! EmptyFeedCollectionViewCell
            
            return cell
            
        }
        else{
            
            let cell: ProfileCollectionViewCell
            
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("ProfileCollectionViewCell", forIndexPath: indexPath) as! ProfileCollectionViewCell
            
            let image = imageDataArray[indexPath.row]
            
            cell.setupData(image.url,
                           image: nil,
                           caption: image.caption,
                           numberOfTags: image.tags?.count,
                           timeStamp: image.timeStamp,
                           fileName: image.fileName
            )
            
            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.mainScreen().scale
            
            return cell
            
        }
    }
    
    
    /**
     Method sets up the section header for the indexPath parameter
     
     - parameter indexPath:      NSIndexPath
     - parameter kind:           String
     - parameter collectionView: UICollectionView
     
     - returns: TripDetailSupplementaryView
     */
    func setUpSectionHeaderViewForIndexPath(indexPath : NSIndexPath, kind: String, collectionView : UICollectionView) -> ProfileHeaderCollectionReusableView {
        
        let header : ProfileHeaderCollectionReusableView
        
        header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ProfileHeaderCollectionReusableView", forIndexPath: indexPath) as! ProfileHeaderCollectionReusableView
        
        header.setupData(CurrentUser.fullName!, numberOfShots: imageDataArray.count, profilePictureURL : CurrentUser.facebookProfilePictureURL)
        
        return header
    }
    
    
    func prepareImageDetailViewControllerSelectedCellAtIndexPath(indexPath : NSIndexPath) -> ImageDetailViewController? {
   
        if(imageDataArray.count > 0){
            let imageDetailVC = Utils.vcWithNameFromStoryboardWithName("ImageDetailViewController", storyboardName: "Feed") as! ImageDetailViewController
            imageDetailVC.image = imageDataArray[indexPath.row]
            return imageDetailVC
        }
        else{
            return nil
        }
        
    }
  
    
}
