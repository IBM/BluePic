//
//  FeedViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/1/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit


class FeedViewModel: NSObject {

    let kNumberOfSectionsInCollectionView = 1
    
    var pictureDataArray = [Picture]()
    var refreshVCCallback : (()->())?
    
    
    let kCollectionViewCellInfoViewHeight : CGFloat = 76
    let kCollectionViewCellHeightLimit : CGFloat = 480
    
    
    
    init(refreshCallback : (()->())){
        super.init()
        
        self.refreshVCCallback = refreshCallback
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleDataManagerNotification)
        
        getPictureObjects()
    }
    
    
    
    func handleDataManagerNotification(dataManagerNotification : DataManagerNotification){
        
        if(dataManagerNotification == DataManagerNotification.CloudantPullDataSuccess){
            getPictureObjects()
        }
        else if(dataManagerNotification == DataManagerNotification.UserDecidedToPostPhoto){
            getPictureObjects()
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

         dispatch_async(dispatch_get_main_queue()) {
            self.callRefreshCallBack()
        }
    }
    
    
    func numberOfSectionsInCollectionView() -> Int {
        return kNumberOfSectionsInCollectionView
    }
    
    
    func numberOfItemsInSection(section : Int) -> Int {
        return pictureDataArray.count
    }
    
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView) -> CGSize {
        
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
    
    
    
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
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
    
    func callRefreshCallBack(){
        if let callback = refreshVCCallback {
            callback()
        }
    }

    
    
    
}

