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

class ImageDetailViewModel: NSObject {

    //the image object the image vc is display data for
    var image: Image!

    //constant that represents the number of sections in the collection view
    fileprivate let kNumberOfSectionsInCollectionView = 1

    //constant used for padded the width of the collection view cell
    fileprivate let kCellPadding: CGFloat = 60

    //constant used to define the minimum height the image info header view must be
    fileprivate let kImageInfoHeaderViewMinimumHeight: CGFloat = 380

    var captionHeightOffset: CGFloat = 20

    init(image: Image) {

        self.image = image

    }

    /**
     Method returns the tag for indexPath

     - parameter indexPath: IndexPath

     - returns: String?
     */
    fileprivate func getTagForIndexPath(_ indexPath: IndexPath) -> String? {

        if let tags = image.tags {
            if (tags.count - 1) >= indexPath.row {
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
    func numberOfItemsInSection(_ section: Int) -> Int {

        if let tags = image.tags {
            return tags.count
        } else {
            return 0
        }

    }

    /**
     Method sets up the header view with image data for index path, specifically the ImageInfoHeaderCollectionReusableView

     - parameter indexPath:      IndexPath
     - parameter kind:           String
     - parameter collectionView: UICollectionView

     - returns: ImageInfoHeaderCollectionReusableView
     */
    func setUpSectionHeaderViewForIndexPath(_ indexPath: IndexPath, kind: String, collectionView: UICollectionView) -> ImageInfoHeaderCollectionReusableView {

        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ImageInfoHeaderCollectionReusableView", for: indexPath) as? ImageInfoHeaderCollectionReusableView else {
            return ImageInfoHeaderCollectionReusableView()
        }
        header.setupWithData(image)

        return header
    }

    /**
     Method sets up the collection view cell with tag data for indexPath, specifically the TagCollectionViewCell

     - parameter indexPath:      IndexPath
     - parameter collectionView: UICollectionView

     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(_ indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionViewCell", for: indexPath) as? TagCollectionViewCell, let tags = image.tags else {
            return UICollectionViewCell()
        }

        cell.tagLabel.text = tags[indexPath.item].label.uppercased()
        return cell

    }

    /**
     Method returns the size for item at indexPath

     - parameter indexPath:      IndexPath
     - parameter collectionView: UICollectionVIew

     - returns: CGSize
     */
    func sizeForItemAtIndexPath(_ indexPath: IndexPath, collectionView: UICollectionView) -> CGSize {

        if let tags = image.tags {
            let size = NSString(string: tags[indexPath.item].label).size(attributes: nil)
            return CGSize(width: size.width + kCellPadding, height: 30.0)
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
    func referenceSizeForHeaderInSection(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, section: Int, superViewHeight: CGFloat) -> CGSize {

        let collectionWidth = collectionView.frame.size.width

        if section == 0 {

            let headerHeight = superViewHeight * 0.60

            // create sample label to determine size of captionLabel, increase header height accordingly
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.frame.width - 60, height: CGFloat.greatestFiniteMagnitude))
            label.numberOfLines = 0
            label.attributedText = NSAttributedString.createAttributedStringWithLetterAndLineSpacingWithCentering(image.caption.uppercased(), letterSpacing: 1.7, lineSpacing: 10.0, centered: true)
            label.sizeToFit()
            captionHeightOffset = label.frame.size.height - 20 // subtract default caption label height

            if headerHeight < kImageInfoHeaderViewMinimumHeight {
                return CGSize(width: collectionWidth, height: kImageInfoHeaderViewMinimumHeight + captionHeightOffset)
            } else {
                return CGSize(width: collectionWidth, height: headerHeight + captionHeightOffset)
            }

        } else {
            return CGSize(width: collectionWidth, height: 0)
        }

    }

    /**
     Method gets the tagString for indexPath, and then sets up a new instance of the feed view controller with this tag as its search query

     - parameter indexPath: IndexPath

     - returns: FeedViewController?
     */
    func getFeedViewControllerForTagSearchAtIndexPath(_ indexPath: IndexPath) -> FeedViewController? {

        if let vc = Utils.vcWithNameFromStoryboardWithName("FeedViewController", storyboardName: "Feed") as? FeedViewController, let tagString = getTagForIndexPath(indexPath) {
            vc.searchQuery = tagString
            return vc
        }
        return nil

    }
}
