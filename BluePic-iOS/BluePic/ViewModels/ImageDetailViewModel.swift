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

    //the image object the image vc is display data for
    var image: Image!

    //constant that represents the number of sections in the collection view
    private let kNumberOfSectionsInCollectionView = 1

    //constant used for padded the width of the collection view cell
    private let kCellPadding: CGFloat = 60

    //constant used to define the minimum height the image info header view must be
    private let kImageInfoHeaderViewMinimumHeight: CGFloat = 357//340


    /**
     Method returns the tag for indexPath

     - parameter indexPath: NSIndexPath

     - returns: String?
     */
    private func getTagForIndexPath(indexPath: NSIndexPath) -> String? {

        if let tags = image.tags {
            if((tags.count - 1) >= indexPath.row) {
                return tags[indexPath.row].label
            }
        }

        return nil
    }

}



// MARK: - View Controller -> ViewModel Communication
extension ImageDetailViewModel {

    func getImageURLString() -> String? {
        return image.url
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
    func numberOfItemsInSection(section: Int) -> Int {

        if let tags = image.tags {
            return tags.count
        } else {
            return 0
        }

    }

    /**
     Method sets up the header view with image data for index path, specifically the ImageInfoHeaderCollectionReusableView

     - parameter indexPath:      NSIndexPath
     - parameter kind:           String
     - parameter collectionView: UICollectionView

     - returns: ImageInfoHeaderCollectionReusableView
     */
    func setUpSectionHeaderViewForIndexPath(indexPath: NSIndexPath, kind: String, collectionView: UICollectionView) -> ImageInfoHeaderCollectionReusableView {

        guard let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ImageInfoHeaderCollectionReusableView", forIndexPath: indexPath) as? ImageInfoHeaderCollectionReusableView else {
            return ImageInfoHeaderCollectionReusableView()
        }

        header.setupWithData(image.caption, userFullName: image.user.name, locationName: image.location.name, latitude: image.location.latitude, longitude: image.location.longitude, timeStamp: image.timeStamp, weatherIconId: image.location.weather?.iconId, temperature: image.location.weather?.temperature, tags: image.tags)

        return header
    }


    /**
     Method sets up the collection view cell with tag data for indexPath, specifically the TagCollectionViewCell

     - parameter indexPath:      NSIndexPath
     - parameter collectionView: UICollectionView

     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(indexPath: NSIndexPath, collectionView: UICollectionView) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCollectionViewCell", forIndexPath: indexPath) as? TagCollectionViewCell, tags = image.tags else {
            return UICollectionViewCell()
        }

        cell.tagLabel.text = tags[indexPath.item].label.uppercaseString
        return cell

    }

    /**
     Method returns the size for item at indexPath

     - parameter indexPath:      NSIndexPath
     - parameter collectionView: UICollectionVIew

     - returns: CGSize
     */
    func sizeForItemAtIndexPath(indexPath: NSIndexPath, collectionView: UICollectionView) -> CGSize {

        if let tags = image.tags {
            let size = NSString(string: tags[indexPath.item].label).sizeWithAttributes(nil)
            return CGSizeMake(size.width + kCellPadding, 30.0)
        }
        return CGSize.zero
    }

    /**
     Method returns the reference size for header in section

     - parameter collectionView:       UICollectionView
     - parameter collectionViewLayout: UICollectionViewLayout
     - parameter section:              Int
     - parameter superViewHeight:      CGFloat

     - returns: CGSize
     */
    func referenceSizeForHeaderInSection(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, section: Int, superViewHeight: CGFloat) -> CGSize {

        let collectionWidth = collectionView.frame.size.width

        if(section == 0) {

            let headerHeight = superViewHeight * 0.60

            if(headerHeight < kImageInfoHeaderViewMinimumHeight) {
                return CGSizeMake(collectionWidth, kImageInfoHeaderViewMinimumHeight)
            } else {
                return CGSizeMake(collectionWidth, headerHeight)
            }

        } else {
            return CGSizeMake(collectionWidth, 0)
        }

    }


    /**
     Method gets the tagString for indexPath, and then sets up a new instance of the feed view controller with this tag as its search query

     - parameter indexPath: NSIndexPath

     - returns: FeedViewController?
     */
    func getFeedViewControllerForTagSearchAtIndexPath(indexPath: NSIndexPath) -> FeedViewController? {

        if let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as? FeedViewController, tagString = getTagForIndexPath(indexPath) {
            vc.searchQuery = tagString
            return vc
        }
        return nil

    }
}
