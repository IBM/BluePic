//
//  ImageDetailViewModel.swift
//  BluePic
//
//  Created by Alex Buck on 5/20/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class ImageDetailViewModel: UIView {

    var image : Image!
    
    //constant that represents the number of sections in the collection view
    private let kNumberOfSectionsInCollectionView = 1
    private let kCellPadding: CGFloat = 60
    private let kImageInfoHeaderViewMinimumHeight : CGFloat = 357//340
    
    
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
        
        if let tags = image.tags {
            return tags.count
        }
        else{
            return 0
        }
        
    }
    
    
    
    func setUpSectionHeaderViewForIndexPath(indexPath : NSIndexPath, kind: String, collectionView : UICollectionView) -> ImageInfoHeaderCollectionReusableView {
        
        let header : ImageInfoHeaderCollectionReusableView
        
        header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ImageInfoHeaderCollectionReusableView", forIndexPath: indexPath) as! ImageInfoHeaderCollectionReusableView
        
        header.setupWithData(image.caption, userFullName: image.user?.name, locationName: image.location?.name, latitude: image.location?.latitude, longitude: image.location?.longitude, timeStamp: image.timeStamp, weatherIconId: image.location?.weather?.iconId, temperature: image.location?.weather?.temperature)
        
        return header
    }
    
    
    
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let tags = image.tags!
        
        cell.tagLabel.text = tags[indexPath.item].label?.uppercaseString
        return cell

    }
    
    
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView) -> CGSize {
        
        let tags = image.tags!
        
        let size = NSString(string: tags[indexPath.item].label!).sizeWithAttributes(nil)
        return CGSizeMake(size.width + kCellPadding, 30.0)
 
    }
    
    
    func referenceSizeForHeaderInSection(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, section: Int, superViewHeight : CGFloat) -> CGSize {
        
        let collectionWidth = collectionView.frame.size.width
        
        if(section == 0){
            
            let headerHeight = superViewHeight * 0.60
            
            if(headerHeight < kImageInfoHeaderViewMinimumHeight){
                 return CGSizeMake(collectionWidth, kImageInfoHeaderViewMinimumHeight)
            }
            else{
                 return CGSizeMake(collectionWidth, headerHeight)
            }
        
        }
        else{
            return CGSizeMake(collectionWidth, 0)
        }
    
    }
    
    private func getTagForIndexPath(indexPath : NSIndexPath) -> String? {
        
        if let tags = image.tags {
            if((tags.count - 1) >= indexPath.row){
                return tags[indexPath.row].label
            }
        }
        
        return nil
    }
    
    
    func getFeedViewControllerForTagSearchAtIndexPath(indexPath : NSIndexPath) -> FeedViewController? {
        
        let tagString = getTagForIndexPath(indexPath)
        
        let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as! FeedViewController
        
        if let tagString = tagString {
            vc.searchQuery = tagString
            return vc
        }
        else{
            return nil
        }

    }
    
    
    func getImageURLString() -> String? {
        return image.url
    }

}
