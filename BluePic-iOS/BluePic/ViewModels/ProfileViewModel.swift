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

class ProfileViewModel: NSObject {

    //array that holds all that pictures that are displayed in the collection view
    private var imageDataArray = [Image]()

    //callback used to tell the ProfileViewController when to refresh its collection view
    private var refreshVCCallback : (()->())!

    //constant that represents the number of sections in the collection view
    private let kNumberOfSectionsInCollectionView = 1

    //constant that represents the height of the info view in the collection view cell that shows the photos caption and photographer name
    private let kCollectionViewCellInfoViewHeight: CGFloat = 60

    //constant that represents the limit of how big the colection view cell height can be
    private let kCollectionViewCellHeightLimit: CGFloat = 480

    //constant that represents a value added to the height of the EmptyFeedCollectionViewCell when its given a size in the sizeForItemAtIndexPath method, this value allows the collection view to scroll
    private let kEmptyFeedCollectionViewCellBufferToAllowForScrolling: CGFloat = 1

    //constant that represents the number of cells in the collection view when there is no photos
    private let kNumberOfCellsWhenUserHasNoPhotos = 1


    /**
     Method called upon init, it sets up the method used to inform the profile vc of events, suscribes to BlueMixDataManager notifications, and updates the image data araay and tells the profile vc to reload its collection view

     - parameter refreshVCCallback: (()->())

     - returns:
     */
    init(refreshVCCallback : (()->())) {
       super.init()

        self.refreshVCCallback  = refreshVCCallback

        suscribeToBluemixDataManagerNotifications()

        updateImageArrayAndNotifyViewControllerToReloadCollectionView()

    }

    /**
     Method suscribes to the event notifications from the BluemixDataManager
     */
    func suscribeToBluemixDataManagerNotifications() {

         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewModel.updateImageArrayAndNotifyViewControllerToReloadCollectionView), name: BluemixDataManagerNotification.ImagesRefreshed.rawValue, object: nil)

    }


    /**
     Method updates the imageDataArray to the latest currentUserImages from the BluemixDataManager and then tells the profile vc to reload its collection view
     */
    func updateImageArrayAndNotifyViewControllerToReloadCollectionView() {

        self.imageDataArray = BluemixDataManager.SharedInstance.currentUserImages

        self.callRefreshCallBack()

    }


    /**
     Method tells the profile view controller to reload its collectionView
     */
    func callRefreshCallBack() {
        if let callback = refreshVCCallback {
            dispatch_async(dispatch_get_main_queue()) {
                callback()
            }
        }
    }


}


//View Controller -> View Model Communication
extension ProfileViewModel {

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

        if(imageDataArray.count == 0) {
            return kNumberOfCellsWhenUserHasNoPhotos
        } else {
            return imageDataArray.count
        }
    }


    /**
     Method returns the size for item at indexPath

     - parameter indexPath:                               NSIndexPath
     - parameter collectionView:                          UICollectionView
     - parameter heightForEmptyProfileCollectionViewCell: CGFloat

     - returns: CGSize
     */
    func sizeForItemAtIndexPath(indexPath: NSIndexPath, collectionView: UICollectionView, heightForEmptyProfileCollectionViewCell: CGFloat) -> CGSize {

        //no images so show empty feed collection view cell
        if(imageDataArray.count == 0) {

            return CGSize(width: collectionView.frame.width, height: heightForEmptyProfileCollectionViewCell + kEmptyFeedCollectionViewCellBufferToAllowForScrolling)
        }
        //there are images so show profile collection view
        else {

            let picture = imageDataArray[indexPath.row]

            let ratio = picture.height / picture.width

            var height = collectionView.frame.width * ratio

            if(height > kCollectionViewCellHeightLimit) {
                height = kCollectionViewCellHeightLimit
            }

            return CGSize(width: collectionView.frame.width, height: height + kCollectionViewCellInfoViewHeight)

        }

    }


    /**
     Method sets up the collection view cell for indexPath. If the imageDataArray.count is equal to 0 then we return an instance EmptyfeedCollectionviewCell

     - parameter indexPath:      NSIndexPath
     - parameter collectionView: UICollectionViewCell

     - returns: UICollectionViewCell
     */
    func setUpCollectionViewCell(indexPath: NSIndexPath, collectionView: UICollectionView) -> UICollectionViewCell {

        if(imageDataArray.count == 0) {

            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyFeedCollectionViewCell", forIndexPath: indexPath) as? EmptyFeedCollectionViewCell else {
                return EmptyFeedCollectionViewCell()
            }

            return cell

        } else {

            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ProfileCollectionViewCell", forIndexPath: indexPath) as? ProfileCollectionViewCell else {
                return ProfileCollectionViewCell()
            }

            let image = imageDataArray[indexPath.row]

            cell.setupData(image.url,
                           image: nil,
                           caption: image.caption,
                           numberOfTags: image.tags?.count,
                           timeStamp: image.timeStamp,
                           fileName: image.fileName
            )

            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.mainScreen().scale

            return cell

        }
    }


    /**
     Method sets up the section header for the indexPath parameter

     - parameter indexPath:      NSIndexPath
     - parameter kind:           String
     - parameter collectionView: UICollectionView

     - returns: TripDetailSupplementaryView
     */
    func setUpSectionHeaderViewForIndexPath(indexPath: NSIndexPath, kind: String, collectionView: UICollectionView) -> ProfileHeaderCollectionReusableView {

        guard let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ProfileHeaderCollectionReusableView", forIndexPath: indexPath) as? ProfileHeaderCollectionReusableView else {
            return ProfileHeaderCollectionReusableView()
        }

        header.setupData(CurrentUser.fullName, numberOfShots: imageDataArray.count, profilePictureURL : CurrentUser.facebookProfilePictureURL)

        return header
    }


    /**
     Method return an ImageDetailViewModel for the image at the indexPath parameter

     - parameter indexPath: NSIndexPath

     - returns: ImageDetailViewModel?
     */
    func prepareImageDetailViewModelForSelectedCellAtIndexPath(indexPath: NSIndexPath) -> ImageDetailViewModel? {

        if((imageDataArray.count - 1 ) >= indexPath.row ) {

            let viewModel = ImageDetailViewModel()
            viewModel.image = imageDataArray[indexPath.row]

            return viewModel
        } else {
            return nil
        }
    }

}
