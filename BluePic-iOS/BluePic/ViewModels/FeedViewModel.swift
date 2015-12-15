/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit


//
enum FeedViewModelNotification {
    case RefreshCollectionView
    case StartLoadingAnimationForAppLaunch
}

class FeedViewModel: NSObject {
    
    var pictureDataArray = [Picture]()
    var refreshVCCallback : (()->())?
    var passFeedViewModelNotificationToTabBarVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())!
    var hasRecievedDataFromCloudant = false
    private var isPullingFromCloudantAlready = false
    
    let kCollectionViewCellInfoViewHeight : CGFloat = 76
    let kCollectionViewCellHeightLimit : CGFloat = 480
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling : CGFloat = 1
    let kNumberOfCellsWhenUserHasNoPhotos = 1
    let kNumberOfSectionsInCollectionView = 1
    
    
    /**
     Method called upon init. It sets a callback to inform the VC of new noti
     
     - parameter passFeedViewModelNotificationToTabBarVCCallback: ((feedViewModelNotification : FeedViewModelNotification)->())
     
     - returns:
     */
    init(passFeedViewModelNotificationToTabBarVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())){
        super.init()
        
        self.passFeedViewModelNotificationToTabBarVCCallback = passFeedViewModelNotificationToTabBarVCCallback
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleDataManagerNotification)
        
    }
    
    
    /**
     Method called when there are new DataManager notifications
     
     - parameter dataManagerNotification: DataMangerNotification
     */
    func handleDataManagerNotification(dataManagerNotification : DataManagerNotification){
        
        if(dataManagerNotification == DataManagerNotification.CloudantPullDataSuccess){
            isPullingFromCloudantAlready = false
            getPictureObjects()
        }
        else if(dataManagerNotification == DataManagerNotification.UserDecidedToPostPhoto){
            getPictureObjects()
        }
        else if(dataManagerNotification == DataManagerNotification.StartLoadingAnimationForAppLaunch){
            self.passFeedViewModelNotificationToTabBarVCCallback(feedViewModelNotification: FeedViewModelNotification.StartLoadingAnimationForAppLaunch)
        }
    }

    
    /**
     Method asks cloudant to pull for new data
     */
    func repullForNewData() {
        if(isPullingFromCloudantAlready == false){
            isPullingFromCloudantAlready = true
            do {
                try CloudantSyncDataManager.SharedInstance!.pullFromRemoteDatabase()
            } catch {
                isPullingFromCloudantAlready = false
                print("repullForNewData ERROR: \(error)")
                DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
            }
        }
    }
    
    
    /**
     Method synchronously asks cloudant for new data. It sets the pictureDataArray to be a combination of the local pictureUploadQueue images + images receives from cloudant/objectDataStore
     */
    func getPictureObjects(){
        pictureDataArray = CameraDataManager.SharedInstance.pictureUploadQueue + CloudantSyncDataManager.SharedInstance!.getPictureObjects(nil)
        hasRecievedDataFromCloudant = true

         dispatch_async(dispatch_get_main_queue()) {
            self.passFeedViewModelNotificationToTabBarVCCallback(feedViewModelNotification: FeedViewModelNotification.RefreshCollectionView)
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
        
        if(pictureDataArray.count == 0 && hasRecievedDataFromCloudant == true){
            return kNumberOfCellsWhenUserHasNoPhotos
        }
        else{
            return pictureDataArray.count
        }
    }
    
    
    /**
     Method returns the size for item at index path
     
     - parameter indexPath: NSIndexPath
     - parameter collectionView: UICollectionViewcell
     
     - returns: CGSize
     */
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView) -> CGSize {
        
        if(pictureDataArray.count == 0){
            
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height + kEmptyFeedCollectionViewCellBufferToAllowForScrolling)
            
        }
        else{
        
            let picture = pictureDataArray[indexPath.row]
        
        
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
     Method sets up the collection view for indexPath. If the the pictureDataArray is 0, then it shows the EmptyFeedCollectionViewCell
     
     - parameter indexPath:      indexPath
     - parameter collectionView: UICollectionView
     
     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        
        if(pictureDataArray.count == 0){
            
            let cell : EmptyFeedCollectionViewCell
            
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyFeedCollectionViewCell", forIndexPath: indexPath) as! EmptyFeedCollectionViewCell
            
            return cell
            
        }
        else{
        
            let cell: ImageFeedCollectionViewCell
        
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageFeedCollectionViewCell", forIndexPath: indexPath) as! ImageFeedCollectionViewCell
        
            let picture = pictureDataArray[indexPath.row]
        
            cell.setupData(
                picture.url,
                image: picture.image,
                displayName: picture.displayName,
                ownerName: picture.ownerName,
                timeStamp: picture.timeStamp,
                fileName: picture.fileName
            )
        
            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
            return cell
            
        }
        
    }
    
    /**
     Method tells the view controller to refresh its collectionView
     */
    func callRefreshCallBack(){
        if let callback = refreshVCCallback {
            callback()
        }
    }

    
    
    
}

