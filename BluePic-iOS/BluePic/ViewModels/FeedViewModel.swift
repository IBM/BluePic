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
    var refreshCallback : (()->())?
    
    
    init(refreshCallback : (()->())){
        super.init()
        
        self.refreshCallback = refreshCallback
        
        getPictureObjects()
    }
    
    
    func getPictureObjects(){
        pictureDataArray = CloudantSyncClient.SharedInstance.getAllPictureObjects()
        
        callRefreshCallBack()
    }
    
    
    func numberOfSectionsInCollectionView() -> Int {
        return kNumberOfSectionsInCollectionView
    }
    
    
    func numberOfItemsInSection(section : Int) -> Int {
        return pictureDataArray.count
    }
    
    
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        let cell: ImageFeedCollectionViewCell
        
        cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageFeedCollectionViewCell", forIndexPath: indexPath) as! ImageFeedCollectionViewCell
        
        cell.setupData("", captionText: "Test", photographerName: "", timeSincePosted: "")
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        return cell
        
    }
    
    func callRefreshCallBack(){
        if let callback = refreshCallback {
            callback()
        }
    }

    
    
    
}

