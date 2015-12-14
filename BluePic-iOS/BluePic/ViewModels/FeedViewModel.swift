//
//  FeedViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/1/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

enum FeedViewModelNotification {
    case RefreshCollectionView
    case StartLoadingAnimationForAppLaunch
}



class FeedViewModel: NSObject {

    let kNumberOfSectionsInCollectionView = 1
    
    var pictureDataArray = [Picture]()
    var refreshVCCallback : (()->())?
    var passFeedViewModelNotificationToTabBarVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())!
    var hasRecievedDataFromCloudant = false
    
    let kCollectionViewCellInfoViewHeight : CGFloat = 76
    let kCollectionViewCellHeightLimit : CGFloat = 480
    let kEmptyFeedCollectionViewCellBufferToAllowForScrolling : CGFloat = 1
    let kNumberOfCellsWhenUserHasNoPhotos = 1
    
    
    
    init(passFeedViewModelNotificationToTabBarVCCallback : ((feedViewModelNotification : FeedViewModelNotification)->())){
        super.init()
        
        self.passFeedViewModelNotificationToTabBarVCCallback = passFeedViewModelNotificationToTabBarVCCallback
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleDataManagerNotification)
        
    }
    
    
    
    func handleDataManagerNotification(dataManagerNotification : DataManagerNotification){
        
        if(dataManagerNotification == DataManagerNotification.CloudantPullDataSuccess){
            getPictureObjects()
        }
        else if(dataManagerNotification == DataManagerNotification.UserDecidedToPostPhoto){
            getPictureObjects()
        }
        else if(dataManagerNotification == DataManagerNotification.StartLoadingAnimationForAppLaunch){
            self.passFeedViewModelNotificationToTabBarVCCallback(feedViewModelNotification: FeedViewModelNotification.StartLoadingAnimationForAppLaunch)
        }
    }
    
    
    func addUsersLastPhotoTakenToPictureDataArrayAndRefreshCollectionView(){

        let lastPhotoTaken = CameraDataManager.SharedInstance.lastPictureObjectTaken
        
        var lastPhotoTakenArray = [Picture]()
        lastPhotoTakenArray.append(lastPhotoTaken)
        
        pictureDataArray = lastPhotoTakenArray + pictureDataArray
        
        callRefreshCallBack()
    }
    
    
    
    
    func repullForNewData() {
        do {
            try CloudantSyncDataManager.SharedInstance!.pullFromRemoteDatabase()
        } catch {
            print("repullForNewData ERROR: \(error)")
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
        }
    }
    
    
    func getPictureObjects(){
        pictureDataArray = CameraDataManager.SharedInstance.pictureUploadQueue + CloudantSyncDataManager.SharedInstance!.getPictureObjects(nil)
        hasRecievedDataFromCloudant = true

         dispatch_async(dispatch_get_main_queue()) {
            self.passFeedViewModelNotificationToTabBarVCCallback(feedViewModelNotification: FeedViewModelNotification.RefreshCollectionView)
        }
    }
    
    
    func numberOfSectionsInCollectionView() -> Int {
        return kNumberOfSectionsInCollectionView
    }
    
    
    func numberOfItemsInSection(section : Int) -> Int {
        
        if(pictureDataArray.count == 0 && hasRecievedDataFromCloudant == true){
            return kNumberOfCellsWhenUserHasNoPhotos
        }
        else{
            return pictureDataArray.count
        }
    }
    
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
    
    func callRefreshCallBack(){
        if let callback = refreshVCCallback {
            callback()
        }
    }

    
    
    
}

