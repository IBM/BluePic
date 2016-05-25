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
        
        guard let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ImageInfoHeaderCollectionReusableView", forIndexPath: indexPath) as? ImageInfoHeaderCollectionReusableView else {
            return ImageInfoHeaderCollectionReusableView()
        }
        
        header.setupWithData(image.caption, userFullName: image.user.name, locationName: image.location.name, latitude: image.location.latitude, longitude: image.location.longitude, timeStamp: image.timeStamp, weatherIconId: image.location.weather?.iconId, temperature: image.location.weather?.temperature, tags: image.tags)
        
        return header
    }
    
    
    func setUpCollectionViewCell(indexPath : NSIndexPath, collectionView : UICollectionView) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell, tags = image.tags else {
            return UICollectionViewCell()
        }
        
        cell.tagLabel.text = tags[indexPath.item].label.uppercaseString
        return cell

    }
    
    
    func sizeForItemAtIndexPath(indexPath : NSIndexPath, collectionView : UICollectionView) -> CGSize {
        
        if let tags = image.tags {
            let size = NSString(string: tags[indexPath.item].label).sizeWithAttributes(nil)
            return CGSizeMake(size.width + kCellPadding, 30.0)
        }
        return CGSizeZero
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
        
        if let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as? FeedViewController, tagString = tagString {
            vc.searchQuery = tagString
            return vc
        }
        return nil

    }
    
    
    func getImageURLString() -> String? {
        return image.url
    }

}
