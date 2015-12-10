//
//  ProfileViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 12/8/15.
//  Copyright © 2015 MIL. All rights reserved.
//

import UIKit

class ProfileViewModel: NSObject {

    var pictureDataArray = [Picture]()
    var refreshVCCallback : (()->())!
    let kNumberOfSectionsInCollectionView = 1
    
    let kCollectionViewCellInfoViewHeight : CGFloat = 60
    let kCollectionViewCellHeightLimit : CGFloat = 480
    
    init(refreshVCCallback : (()->())){
       super.init()
        
        self.refreshVCCallback  = refreshVCCallback
        
        
        DataManagerCalbackCoordinator.SharedInstance.addCallback(handleDataManagerNotifications)
        
        getPictureObjects()
        
    }
    

    
    func handleDataManagerNotifications(dataManagerNotification : DataManagerNotification){
        
        
        if (dataManagerNotification == DataManagerNotification.UserDecidedToPostPhoto){
            
            addUsersLastPhotoTakenToPictureDataArrayAndRefreshCollectionView()
            
        }
        
        
        
        
    }
    
    
    func addUsersLastPhotoTakenToPictureDataArrayAndRefreshCollectionView(){
        
        
        let lastPhotoTaken = CameraDataManager.SharedInstance.lastPictureObjectTaken
        
        var lastPhotoTakenArray = [Picture]()
        lastPhotoTakenArray.append(lastPhotoTaken)
        
        pictureDataArray = lastPhotoTakenArray + pictureDataArray
        
        callRefreshCallBack()
        
    }
    
    
    
    
    func getPictureObjects(){
        
         //pictureDataArray = CameraDataManager.SharedInstance.pictureUploadQueue + CloudantSyncClient.SharedInstance!.getPictureObjects(nil)
        pictureDataArray = CameraDataManager.SharedInstance.pictureUploadQueue + CloudantSyncClient.SharedInstance!.getPictureObjects(FacebookDataManager.SharedInstance.fbUniqueUserID!)
        
        
        dispatch_async(dispatch_get_main_queue()) {
            self.callRefreshCallBack()
        }
    }
    
    
    func repullForNewData(){
        do {
            try CloudantSyncClient.SharedInstance!.pullFromRemoteDatabase()
        } catch {
            print("repullForNewData error: \(error)")
            DataManagerCalbackCoordinator.SharedInstance.sendNotification(DataManagerNotification.CloudantPullDataFailure)
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
        
        let cell: ProfileCollectionViewCell
        
        cell = collectionView.dequeueReusableCellWithReuseIdentifier("ProfileCollectionViewCell", forIndexPath: indexPath) as! ProfileCollectionViewCell
        
        let picture = pictureDataArray[indexPath.row]
        
        cell.setupData(picture.url,
            image: picture.image,
            displayName: picture.displayName,
            timeStamp: picture.timeStamp,
            fileName: picture.fileName
        )
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        return cell
        
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
        
        header.setupData(FacebookDataManager.SharedInstance.fbUserDisplayName, numberOfShots: pictureDataArray.count, profilePictureURL : FacebookDataManager.SharedInstance.getUserFacebookProfilePictureURL())
        
        return header
    }
    
    

    
    func callRefreshCallBack(){
        if let callback = refreshVCCallback {
            callback()
        }
    }
    
    
    
}
