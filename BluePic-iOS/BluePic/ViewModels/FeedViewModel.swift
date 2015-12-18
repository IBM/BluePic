/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/


import UIKit

//used to inform the Feed View Controller of notifications
enum FeedViewModelNotification {
    
    //called when there is new data in the pictureDataArray, used to tell the Feed VC to refresh it's data in the collection view
    case RefreshCollectionView
    
    //called when in the view did appear of the tab vc
    case StartLoadingAnimationForAppLaunch
}

class FeedViewModel: NSObject {
    
    //array that holds all the picture data objects we used to populate the Feed VC's collection view
    var pictureDataArray = [Picture]()
    
    //callback used to inform the Feed VC when there is new data and to refresh its collection view
    var refreshVCCallback : (()->())?
    
    //callback used to inform the Feed VC of notifications from its view model
    var passFeedViewModelNotificationToFeedVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())!
    
    //state variable used to keep track if we have received data from cloudant yet
    var hasRecievedDataFromCloudant = false
    
    //state variable to keep of if we are current pulling from cloudant. This is to prevent a user to pull down to refresh while it is already refreshing
    private var isPullingFromCloudantAlready = false
    
    //constant that represents the height of the info view in the collection view cell that shows the photos caption and photographer name
    let kCollectionViewCellInfoViewHeight : CGFloat = 76
    
    //constant that represents the limit of how tall a collection view cell's height can be
    let kCollectionViewCellHeightLimit : CGFloat = 480
    
    //constant that represents a value added to the height of the EmptyFeedCollectionViewCell when its given a size in the sizeForItemAtIndexPath method, this value allows the collection view to scroll
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling : CGFloat = 1
    
    //constant that defines the number of cells there is when the user has no photos
    let kNumberOfCellsWhenUserHasNoPhotos = 1
    
    //constant that defines the number of sections there are in the collection view
    let kNumberOfSectionsInCollectionView = 1
    
    
    /**
     Method called upon init. It sets a callback to inform the VC of new noti
     
     - parameter passFeedViewModelNotificationToTabBarVCCallback: ((feedViewModelNotification : FeedViewModelNotification)->())
     
     - returns:
     */
    init(passFeedViewModelNotificationToFeedVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())){
        super.init()
        
        self.passFeedViewModelNotificationToFeedVCCallback = passFeedViewModelNotificationToFeedVCCallback
        
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
            self.passFeedViewModelNotificationToFeedVCCallback(feedViewModelNotification: FeedViewModelNotification.StartLoadingAnimationForAppLaunch)
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
            self.passFeedViewModelNotificationToFeedVCCallback(feedViewModelNotification: FeedViewModelNotification.RefreshCollectionView)
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

